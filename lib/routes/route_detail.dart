import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'routes_service.dart';
import 'route_list.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:io' show Platform; 

// NOTE: Ensure RouteOption is defined in route_list.dart and imported here.

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;
  final RouteOption routeOption; 

  const RouteDetailPage({
    super.key, 
    required this.origin,
    required this.destination,
    required this.routeOption,
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  // Map state
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // UI / fare state
  bool loading = true;
  String? errorMessage;
  String _distanceText = '';
  double _distanceKm = 0.0;
  String _durationText = ''; 
  Map<String, String> _estimatedFares = {};
  List<dynamic> _steps = [];
  String _startLabel = '';
  String _endLabel = '';
  LatLngBounds? _bounds; 
  List<LatLng> _polylinePoints = [];
  
  // Constants from routeDetail.dart
  static const int alpha179 = 179;
  static const int alpha26 = 26;
  static const int alpha31 = 31;

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
      'schemeWeb': 'https://taximaxim.page.link/app', 
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
    _extractDataFromRouteOption(); 
  }
  
  // --- Data Extraction Helpers from previous response ---

  LatLngBounds? _getBoundsSafe(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      final boundsData = data['bounds'] as Map<String, dynamic>;
      final northeast = boundsData['northeast'] as Map<String, dynamic>;
      final southwest = boundsData['southwest'] as Map<String, dynamic>;
      
      return LatLngBounds(
        northeast: LatLng(northeast['lat'], northeast['lng']),
        southwest: LatLng(southwest['lat'], southwest['lng']),
      );
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
      final encodedPolyline = data['overview_polyline']?['points'] as String?;
      if (encodedPolyline != null) {
        return _decodePolyline(encodedPolyline);
      }
    } catch (_) {}
    return [];
  }

  List<dynamic> _getStepsSafe(Map<String, dynamic>? data) {
    if (data == null) return [];
    try {
      final legs = data['legs'];
      if (legs is List && legs.isNotEmpty) {
        final steps = legs[0]['steps'];
        if (steps is List) return steps;
      }
    } catch (_) {}
    return [];
  }
  
  // --- Fare Estimation ---
  Map<String, String> _estimateFaresFunc(double distanceKm) {
    // Replicates the logic from the previous route_detail.dart
    final fares = <String, String>{};

    final motoBase = 40;
    final motoPerKm = 12;
    final moto = (motoBase + (distanceKm * motoPerKm)).round();
    fares['Moto Taxi'] = '₱$moto';

    final taxiBase = 40;
    final taxiPerKm = 18;
    final taxi = (taxiBase + (distanceKm * taxiPerKm)).round();
    fares['Taxi'] = '₱$taxi';

    final puj = _calculatePublicFare(distanceKm);
    fares['PUJ / Bus'] = '₱$puj';

    return fares;
  }

  int _calculatePublicFare(double distanceKm) {
    if (distanceKm <= 4.0) return 15;
    return (15 + ((distanceKm - 4.0) * 2.5)).round();
  }
  
  // --- Data Extraction and State Update for selected RouteOption ---
  void _extractDataFromRouteOption() {
    final Map<String, dynamic> rawRoute = widget.routeOption.rawRouteData;

    try {
      // 1. Extract Distance and Duration
      final leg = (rawRoute['legs'] as List).first as Map<String, dynamic>;
      
      _distanceText = leg['distance']?['text']?.toString() ?? '';
      final distanceMeters = (leg['distance']?['value'] ?? 0) as num;
      _distanceKm = (distanceMeters.toDouble() / 1000.0);
      _durationText = leg['duration']?['text']?.toString() ?? '${widget.routeOption.durationMinutes} mins';
      
      // 2. Compute Fares (using the distance derived from the API response)
      _estimatedFares = _estimateFaresFunc(_distanceKm);

      // 3. Extract Steps
      _steps = _getStepsSafe(rawRoute);
      
      // 4. Extract Map Data (Bounds and Polyline)
      _bounds = _getBoundsSafe(rawRoute);
      _polylinePoints = _getPolylinePointsSafe(rawRoute);

      // 5. Set Addresses
      _startLabel = leg['start_address']?.toString() ?? widget.origin?['name']?.toString() ?? 'Start';
      _endLabel = leg['end_address']?.toString() ?? widget.destination?['name']?.toString() ?? 'Destination';
          
      // 6. Set Map Markers and Polylines
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
        loading = false;
        errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('Error extracting route data: $e\n$st');
      setState(() {
        loading = false;
        errorMessage = 'Failed to process route data.';
      });
    }
  }

  // --- Map and App Launch Logic ---
  
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
    final webScheme = data['schemeWeb'] != null ? Uri.parse(data['schemeWeb']) : null;


    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } 
    else if (webScheme != null && await canLaunchUrl(webScheme)) {
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _launchAppOrStore(appName),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(6), // Use smaller padding for logo
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(0, 20),
            backgroundColor: backgroundColor, 
          ),
          child: Image.asset( // Use Image.asset for the logo
            imagePath,
            height: 30,
            fit: BoxFit.contain,
            color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, 
            colorBlendMode: BlendMode.modulate, 
          ),
        ),
      ),
    );
  }


Widget _buildMotoTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(cs, 'Angkas', 'assets/angkas.png', backgroundColor: angkasBlue), 
        _buildActionButton(cs, 'Maxim', 'assets/maximT.png', backgroundColor: maximYellow), 
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
          fareWidgets.add(
              Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 16, right: 16),
              child: _buildTaxiButtonsRow(cs), // Taxi/Car Row
            )
        );
      }
      
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
        iconTheme: IconThemeData(color: cs.onPrimary), 
        title: Text("Route Details", style: TextStyle(color: cs.onPrimary)),
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
                              _buildStatColumn("", "", textColor), 
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
                  // debug: raw JSON button
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Raw API Response'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: Text(JsonEncoder.withIndent('  ').convert(widget.routeOption.rawRouteData)),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show raw API response'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}