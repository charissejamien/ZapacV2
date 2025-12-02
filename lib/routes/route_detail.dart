import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'routes_service.dart';
import 'route_list.dart'; // Assuming this defines LatLngBounds
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:io' show Platform; 

// NOTE: Since the FavoriteRoute model is not provided, 
// the map-specific data (bounds, polylinePoints) must be extracted from the API response.

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;
  final dynamic routeOption;

  const RouteDetailPage({
    super.key, // Changed Key? key to super.key
    required this.origin,
    required this.destination,
    required this.routeOption,
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  Map<String, dynamic>? routeData;
  bool loading = true;
  String? errorMessage;

  // Map state
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // UI / fare state
  String _distanceText = '';
  double _distanceKm = 0.0;
  String _durationText = ''; // Changed from _durationMinutes to match original UI text format
  Map<String, String> _estimatedFares = {};
  List<dynamic> _steps = [];
  String _startLabel = '';
  String _endLabel = '';
  LatLngBounds? _bounds; // Map bounds
  List<LatLng> _polylinePoints = []; // Route points
  
  // Constants from routeDetail.dart
  static const int alpha179 = 179;
  static const int alpha13 = 13;
  static const int alpha26 = 26;
  static const int alpha31 = 31;
  static const int alpha204 = 204;

  final Color angkasBlue = const Color(0xFF14b2d8);
  final Color maximYellow = const Color(0xFFFDDB0A); 
  final Color moveItRed = const Color(0xFFBB3329); 
  final Color grabGreen = const Color.fromARGB(255, 5, 199, 76);
  final Color joyrideBlue = const Color(0xFF1E21CD);
  
  static const Map<String, dynamic> appLinks = {
    'Angkas': {
      'scheme': 'angkasrider://', 
      'androidPackage': 'com.angkas.rider',
      'iosAppId': '1096417726', 
    },
    'Maxim': {
      'scheme': 'taximaxim://',
      'schemeWeb': 'https://taximaxim.page.link/app', // Added for better fallback if app is installed but scheme fails
      'androidPackage': 'com.taxsee.taxsee',
      'iosAppId': '597956747',
    },
    'MoveIt': {
      'scheme': 'moveit://',
      'androidPackage': 'com.moveitph.rider',
      'iosAppId': '1465241038',
    },
    'JoyRide': {
      'scheme': 'joyride://', 
      'androidPackage': 'com.joyride.rider',
      'iosAppId': '1467478148', 
    },
    'Grab': {
      'scheme': 'grab://',
      'androidPackage': 'com.grab.passenger',
      'iosAppId': '643912198',
    },
  };

  @override
  void initState() {
    super.initState();
    loadRoute();
  }
  
  // --- Data Extraction Helpers ---
  double _toDoubleSafe(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final cleaned = v.trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (v is num) return v.toDouble();
    return 0.0;
  }

  double _extractLat(Map<dynamic, dynamic>? m) {
    if (m == null) return 0.0;
    final candidates = [
      m['latitude'],
      m['lat'],
      m['latLng']?['latitude'],
      m['latLng']?['lat'],
      m['location']?['lat'],
      m['location']?['latitude'],
    ];
    for (final c in candidates) {
      if (c != null) return _toDoubleSafe(c);
    }
    return 0.0;
  }

  double _extractLng(Map<dynamic, dynamic>? m) {
    if (m == null) return 0.0;
    final candidates = [
      m['longitude'],
      m['lng'],
      m['latLng']?['longitude'],
      m['latLng']?['lng'],
      m['location']?['lng'],
      m['location']?['longitude'],
    ];
    for (final c in candidates) {
      if (c != null) return _toDoubleSafe(c);
    }
    return 0.0;
  }

  Map<String, dynamic> _extractFirstLeg(Map<String, dynamic> data) {
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final legs = routes[0]['legs'];
        if (legs is List && legs.isNotEmpty) {
          return (legs[0] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  List<dynamic> _getStepsSafe(Map<String, dynamic>? data) {
    if (data == null) return [];
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final legs = routes[0]['legs'];
        if (legs is List && legs.isNotEmpty) {
          final steps = legs[0]['steps'];
          if (steps is List) return steps;
        }
      }
    } catch (_) {}
    return [];
  }
  
  LatLngBounds? _getBoundsSafe(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final boundsData = routes[0]['bounds'] as Map<String, dynamic>;
        final northeast = boundsData['northeast'] as Map<String, dynamic>;
        final southwest = boundsData['southwest'] as Map<String, dynamic>;
        
        return LatLngBounds(
          northeast: LatLng(northeast['lat'], northeast['lng']),
          southwest: LatLng(southwest['lat'], southwest['lng']),
        );
      }
    } catch (_) {}
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> polylinePoints = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polylinePoints;
  }
  
  List<LatLng> _getPolylinePointsSafe(Map<String, dynamic>? data) {
    if (data == null) return [];
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final encodedPolyline = routes[0]['overview_polyline']?['points'] as String?;
        if (encodedPolyline != null) {
          return _decodePolyline(encodedPolyline);
        }
      }
    } catch (_) {}
    return [];
  }
  
  // --- Fare Estimation ---
  Map<String, String> _estimateFares(double distanceKm) {
    // basic fare estimates — adjust formulas to suit your app/region
    final fares = <String, String>{};

    // Moto Taxi (e.g., Angkas) - Base from routeDetail.dart logic for Moto Taxi
    final motoBase = 40;
    final motoPerKm = 12;
    final moto = (motoBase + (distanceKm * motoPerKm)).round();
    fares['Moto Taxi'] = '₱$moto';

    // Taxi (meter-ish) - Base from routeDetail.dart logic for Taxi
    final taxiBase = 40;
    final taxiPerKm = 18;
    final taxi = (taxiBase + (distanceKm * taxiPerKm)).round();
    fares['Taxi'] = '₱$taxi';

    // PUJ / Jeepney / Bus estimate (using simple public fare) - Base from routeDetail.dart logic for PUJ
    final puj = _calculatePublicFare(distanceKm);
    fares['PUJ / Bus'] = '₱$puj';

    return fares;
  }

  int _calculatePublicFare(double distanceKm) {
    if (distanceKm <= 4.0) return 15;
    return (15 + ((distanceKm - 4.0) * 2.5)).round();
  }
  
  // --- API Call and State Update ---
  Future<void> loadRoute() async {
    if (widget.origin == null || widget.destination == null) {
      setState(() {
        loading = false;
        errorMessage = 'Missing origin or destination data.';
      });
      return;
    }

    final originMap = widget.origin!;
    final destMap = widget.destination!;

    final originLat = _extractLat(originMap);
    final originLng = _extractLng(originMap);
    final destLat = _extractLat(destMap);
    final destLng = _extractLng(destMap);

    try {
      final service = RoutesService();
      final result = await service.getRouteDetails(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          loading = false;
          errorMessage = 'No route details returned from the API.';
        });
        return;
      }

      // extract summary info safely
      final Map<String, dynamic> firstLeg = _extractFirstLeg(result);
      _distanceText = (firstLeg['distance']?['text'] ??
          firstLeg['distance'] ??
          '')?.toString() ??
          '';
      final distanceMeters = (firstLeg['distance']?['value'] ?? 0) as num;
      _distanceKm = (distanceMeters.toDouble() / 1000.0);
      _durationText = (firstLeg['duration']?['text'] ?? 
          firstLeg['duration'] ?? 
          '')?.toString() ?? 
          '';

      // compute fares
      _estimatedFares = _estimateFares(_distanceKm);

      // extract steps
      _steps = _getStepsSafe(result);
      
      // extract map data
      _bounds = _getBoundsSafe(result);
      _polylinePoints = _getPolylinePointsSafe(result);

      // set addresses
      _startLabel = firstLeg['start_address']?.toString() ??
          widget.origin?['description']?.toString() ??
          widget.origin?['name']?.toString() ??
          'Start';
      _endLabel = firstLeg['end_address']?.toString() ??
          widget.destination?['description']?.toString() ??
          widget.destination?['name']?.toString() ??
          'Destination';
          
      // Set map markers and polylines
      if (_polylinePoints.isNotEmpty) {
        _markers.add(Marker(
          markerId: const MarkerId('start'),
          position: _polylinePoints.first,
          infoWindow: InfoWindow(title: 'Start', snippet: _startLabel),
        ));
        _markers.add(Marker(
          markerId: const MarkerId('end'),
          position: _polylinePoints.last,
          infoWindow: InfoWindow(title: 'End', snippet: _endLabel),
        ));
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF4A6FA5),
            points: _polylinePoints,
            width: 5,
          )
        };
      }

      setState(() {
        routeData = result;
        loading = false;
        errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('Error loading route details: $e\n$st');
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Failed to load route details.';
        });
      }
    }
  }

  // --- Map and App Launch Logic from routeDetail.dart ---
  
  LatLng _getCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_bounds != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(_bounds!, 50.0),
      );
    }
  }

  Future<void> _launchAppOrStore(String appName) async {
    final data = appLinks[appName];
    if (data == null || !mounted) return;

    final String appScheme = data['scheme'];
    String storeLink;

    if (Platform.isAndroid) {
      storeLink = "https://play.google.com/store/apps/details?id=${data['androidPackage']}";
    } else if (Platform.isIOS) {
      storeLink = "https://apps.apple.com/app/id${data['iosAppId']}";
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App redirection not supported on this platform.')),
        );
      }
      return;
    }

    final appUri = Uri.parse(appScheme);
    final storeUri = Uri.parse(storeLink);
    
    // Maxim uses a dynamic link fallback
    final webScheme = data['schemeWeb'] != null ? Uri.parse(data['schemeWeb']) : null;


    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } 
    else if (webScheme != null && await canLaunchUrl(webScheme)) {
      // Secondary attempt for apps like Maxim with web scheme/dynamic link
      await launchUrl(webScheme, mode: LaunchMode.externalApplication);
    }
    else if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } 
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $appName or app store.')),
        );
      }
    }
  }

  // --- UI Components from routeDetail.dart ---
  
  IconData _getTransportIcon(String transportName) {
    final lowerName = transportName.toLowerCase();
    if (lowerName.contains('moto taxi')) return Icons.two_wheeler;
    if (lowerName.contains('grab')) return Icons.directions_car_filled; 
    if (lowerName.contains('taxi')) return Icons.local_taxi;
    if (lowerName.contains('puj') || lowerName.contains('bus')) return Icons.directions_bus_filled;
    return Icons.directions_car; 
  }

  Widget _buildRouteInfoRow({required IconData icon, required String title, required String content, required Color textColor}) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: secondaryColor, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: textColor.withAlpha(alpha179))),
              Text(content, style: TextStyle(fontSize: 16, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: textColor.withAlpha(alpha179))),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
  
  Widget _buildFareOptionCard(ColorScheme cs, String transportName, String fare, String durationText) {
    // Note: The original timeRange logic (10 am -> 10 am) is placeholder/static.
    // Keeping it simple as no live time data is available here.
    const String timeRange = 'Today'; 
    
    Widget transportRow = Row(
      children: [
        Icon(_getTransportIcon(transportName), size: 20, color: cs.secondary),
        const SizedBox(width: 8),
        Text(
          transportName,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: cs.shadow.withAlpha(alpha26), 
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Future detailed flow here
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeRange, 
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(alpha31), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      durationText, 
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              transportRow,
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: TextStyle(color: cs.onSurface.withAlpha(alpha179)),
                  ),
                  Text(
                    fare, 
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme cs, String appName, String imagePath, {required Color backgroundColor}) {
    // NOTE: This assumes you have assets/angkas.png, assets/maxim.png, etc.
    // If you don't have these, use a TextButton with the appName instead.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _launchAppOrStore(appName),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(0, 20),
            backgroundColor: backgroundColor, 
          ),
          child: Text(
            appName, // Fallback to Text if image is missing
            style: TextStyle(
              color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          /* If you have the assets, uncomment the following and remove the Text widget:
          child: Image.asset(
            imagePath,
            height: 24,
            fit: BoxFit.contain,
            color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, 
            colorBlendMode: BlendMode.modulate, 
          ),
          */
        ),
      ),
    );
  }


  Widget _buildMotoTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(cs, 'Angkas', 'assets/angkas.png', backgroundColor: angkasBlue), 
        _buildActionButton(cs, 'Maxim', 'assets/maxim.png', backgroundColor: maximYellow), 
        _buildActionButton(cs, 'MoveIt', 'assets/moveit.png', backgroundColor: moveItRed), 
        _buildActionButton(cs, 'JoyRide', 'assets/joyride.png', backgroundColor: joyrideBlue),
      ],
    );
  }
  
  Widget _buildTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(cs, 'Grab', 'assets/grab.png', backgroundColor: grabGreen),
        _buildActionButton(cs, 'JoyRide', 'assets/joyride.png', backgroundColor: joyrideBlue),
      ],
    );
  }


  Widget _buildFareList(ColorScheme cs, Color textColor) {
    final List<Widget> fareWidgets = [];

    _estimatedFares.entries.forEach((entry) {
      final transportType = entry.key; // e.g., 'Moto Taxi', 'Taxi', 'PUJ / Bus'
      
      // 1. Add the main fare card
      fareWidgets.add(
        _buildFareOptionCard(
          cs, 
          transportType, 
          entry.value, 
          _durationText // Use the live duration text
        )
      );

      // 2. Conditionally add the ride-hailing buttons row below the card
      if (transportType == 'Moto Taxi') {
        fareWidgets.add(
              Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 8, right: 8),
              child: _buildMotoTaxiButtonsRow(cs), // Moto Taxi Row
            )
        );
      } else if (transportType == 'Taxi') {
          // Assuming Grab/JoyRide also cover Taxi/Car-based ride-hailing
          fareWidgets.add(
              Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 16, right: 16),
              child: _buildTaxiButtonsRow(cs), // Taxi/Car Row
            )
        );
      }
      
      // Add a small spacer between different transport type cards
      fareWidgets.add(const SizedBox(height: 10)); 
    });

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Estimated Fares",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: cs.primary
            )
          ),
          const SizedBox(height: 10),
          // Display the list of fare items and buttons
          ...fareWidgets,
        ],
      ),
    );
  }

  // --- UI Steps List (Adapted from route_detail.dart) ---
  Widget _buildStepsList(ColorScheme cs) {
    if (_steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.only(top: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Directions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = _steps[i] as Map<String, dynamic>;

                // time label if available
                String timeLabel = '';
                try {
                  final departureVal = s['departure_time']?['value'] ?? s['start_time']?['value'];
                  if (departureVal != null && departureVal is int) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(departureVal * 1000);
                    timeLabel = TimeOfDay.fromDateTime(dt).format(context);
                  } else if (s['start_time']?['text'] != null) {
                    timeLabel = s['start_time']['text'].toString();
                  }
                } catch (_) {}

                final htmlInstr = s['html_instructions']?.toString() ?? '';
                final instruction = htmlInstr.replaceAll(RegExp(r'<[^>]*>'), '') ??
                    s['instructions']?.toString() ??
                    s['text']?.toString() ??
                    '';

                final distance = (s['distance']?['text'] ?? s['distance'] ?? '')?.toString() ?? '';
                final duration = (s['duration']?['text'] ?? s['duration'] ?? '')?.toString() ?? '';
                final transit = s['transit_details'] ?? s['transitDetails'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          if (timeLabel.isNotEmpty) Text(timeLabel, style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
                          const SizedBox(height: 6),
                          Icon(
                            (s['travel_mode'] ?? s['travelMode'] ?? '').toString().toLowerCase().contains('walk')
                                ? Icons.directions_walk
                                : (s['transit_details'] != null ? Icons.directions_bus : Icons.directions),
                            size: 20,
                            color: cs.secondary,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(instruction, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(duration, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                            const SizedBox(width: 8),
                            Text(distance, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                            const Spacer(),
                            if (transit != null)
                              Text('${transit['num_stops'] ?? transit['stops'] ?? ''} stops', style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: Center(child: Text(errorMessage!)),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color textColor = cs.onSurface;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: cs.onPrimary), // Use Theme color for consistency
        title: const Text("Route Details", style: TextStyle(color: Colors.white)), // Hardcoded white to match primary background
        backgroundColor: cs.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Widget (from routeDetail.dart)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: (_bounds != null && _polylinePoints.isNotEmpty) 
                ? GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _getCenter(_bounds!), 
                    zoom: 12
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                )
                : Center(child: Text("Map data unavailable")),
            ),
            
            // Route Info and Fares (from routeDetail.dart)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: cs.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRouteInfoRow(icon: Icons.my_location, title: "Start", content: _startLabel, textColor: textColor),
                          const Divider(height: 30),
                          _buildRouteInfoRow(icon: Icons.location_on, title: "Destination", content: _endLabel, textColor: textColor),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn("Distance", _distanceText.isNotEmpty ? _distanceText : '${_distanceKm.toStringAsFixed(1)} km', textColor),
                              _buildStatColumn("Duration", _durationText, textColor),
                              _buildStatColumn("", "", textColor), // Empty column to match the 3-column layout
                            ],
                          ),
                          _buildFareList(cs, textColor),
                        ],
                      ),
                    ),
                  ),
                  
                  // Directions/Steps List (from route_detail.dart)
                  _buildStepsList(cs),

                  const SizedBox(height: 24),

                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}