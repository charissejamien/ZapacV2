import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'favorite_route.dart';
import 'favorite_routes_service.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:io' show Platform; 
import '../core/utils/map_utils.dart'; // Import map utilities
import 'favoriteRouteData.dart'; 
import 'dart:async'; // 1. IMPORT dart:async FOR TIMER

class RouteDetailPage extends StatefulWidget {
  final FavoriteRoute route;

  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = const {};
  final FavoriteRoutesService _routesService = FavoriteRoutesService(); 
  
  // State to hold real-time durations
  Map<String, String> _transportDurations = {};
  
  // State to manage visibility of ride-hailing buttons (Used inside the Moto/Grab expansion)
  Map<String, bool> _isExpandedMap = {
    'Moto Taxi': false,
    'Grab (4-seater)': false,
  };
  
  // State to hold route codes (Jeepney/Bus codes)
  Map<String, String> _transportRouteCodes = {};

  // --- NEW INLINE TOOLTIP STATE MANAGEMENT ---
  // State to track which fare card's discount info is expanded (Inline Fix)
  Map<String, bool> _isDiscountTooltipVisible = {};
  // 2. TIMER FIELD
  Timer? _discountTimer; 
  // ------------------------------------------

  // --- TRANSPORT ORDER & IDENTIFIERS ---
  // The master order is still needed, but primarily used inside grouping.
  final List<String> _transportOrder = const [
    'Moto Taxi',
    'Grab (4-seater)',
    'Taxi',
    'Traditional PUJ',
    'Modern PUJ',
    'Non Aircon Bus',
    'Aircon Bus',
  ];
  
  // NEW: State to manage which main transport category is expanded
  Map<String, bool> _expansionState = {
    'Moto Taxi': false,
    'Grab': false,
    'PUJ': false,
    'Bus': false,
    'Taxi': false,
  };
  
  // NEW: Groupings of individual transports by category
  final Map<String, List<String>> _transportGroups = const {
    'Moto Taxi': ['Moto Taxi'],
    'Grab': ['Grab (4-seater)'],
    'PUJ': ['Traditional PUJ', 'Modern PUJ'],
    'Bus': ['Non Aircon Bus', 'Aircon Bus'],
    'Taxi': ['Taxi'],
  };
  
  // --- COLOR AND ALPHA CONSTANTS ---
  static const int alpha179 = 179;
  static const int alpha13 = 13;
  static const int alpha26 = 26;
  static const int alpha31 = 31;
  static const int alpha204 = 204;
  
  // Custom Ride-Hailing Colors
  final Color angkasBlue = const Color(0xFF14b2d8);
  final Color maximYellow = const Color(0xFFFDDB0A); 
  final Color moveItRed = const Color(0xFFBB3329); 
  final Color grabGreen = const Color(0xFF009C3A);
  final Color joyrideBlue = const Color(0xFF1E21CD);


  // --- DEEP LINKING CONSTANTS ---
// ... (appLinks constant remains the same)
  static const Map<String, dynamic> appLinks = {
    'Angkas': {
      'scheme': 'angkasrider://', 
      'androidPackage': 'com.angkas.rider',
      'iosAppId': '1096417726', 
    },
    'Maxim': {
      'scheme': 'taximaxim://',
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

  String _getMapApiKey() {
    if (Platform.isIOS) {
      return "AIzaSyCWHublkXuYaWfT68qUwGY3o5L9NB82JA8";
    }
    return "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; 
  }
  
  // Helper function to shorten duration string format (e.g., "1 hour 12 mins" -> "1 h 12 min")
  String _formatDurationShort(String durationText) {
    if (durationText == '...' || durationText.isEmpty) return durationText;

    String shortText = durationText
        .replaceAll(' hours', 'h')
        .replaceAll(' hour', 'h')
        .replaceAll(' minutes', 'min')
        .replaceAll(' minute', 'min')
        .replaceAll(' mins', 'min');
    
    return shortText;
  }

  // Helper function to format time (h:mm am/pm)
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $ampm';
  }

  // Helper function to parse duration string (e.g., "1 hour 30 mins") into Duration object
  Duration _parseDurationString(String durationString) {
    int hours = 0;
    int minutes = 0;

    final parts = durationString.toLowerCase().split(' ');
    for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        try {
            final value = int.parse(part);
            if (i + 1 < parts.length) {
                final unit = parts[i + 1];
                if (unit.startsWith('hour')) {
                    hours = value;
                } else if (unit.startsWith('min')) {
                    minutes = value;
                }
            }
        } catch (_) {
            continue;
        }
    }
    return Duration(hours: hours, minutes: minutes);
  }

  // Helper function to calculate the arrival time range string
  String _calculateArrivalTimeRange(String durationText) {
      if (durationText == '...') {
          return '... \u2192 ...';
      }
      
      final startTime = DateTime.now();
      final duration = _parseDurationString(durationText);
      final arrivalTime = startTime.add(duration);

      final startTimeStr = _formatTime(startTime);
      final arrivalTimeStr = _formatTime(arrivalTime);

      return '$startTimeStr \u2192 $arrivalTimeStr';
  }


  LatLng _getCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }
  
  IconData _getTransportIcon(String transportName) {
    if (transportName.contains('Moto Taxi')) return Icons.two_wheeler;
    if (transportName.contains('Grab')) return Icons.directions_car_filled; 
    if (transportName == 'Taxi') return Icons.local_taxi;
    if (transportName.contains('PUJ') || transportName.contains('Bus')) return Icons.directions_bus_filled;
    return Icons.directions_car; 
  }
  
  // Logic to extract the route code from the transit steps
  String? _extractRouteCode(List<dynamic> steps) {
    for (var step in steps) {
      if (step['travel_mode'] == 'TRANSIT' && step['transit_details'] != null) {
        final transitDetails = step['transit_details'];
        if (transitDetails['line'] != null) {
          // Prefer short_name (like "01K", "13B") over long name
          final routeShortName = transitDetails['line']['short_name'] as String?;
          final routeName = transitDetails['line']['name'] as String?;
          
          if (routeShortName != null && routeShortName.isNotEmpty) {
            return routeShortName;
          }
          if (routeName != null && routeName.isNotEmpty) {
            return routeName;
          }
        }
      }
    }
    return null;
  }
  
  // Helper function to convert distance string (e.g., "5.5 km") to kilometers (double)
  double _parseDistanceToKm(String distanceString) {
    try {
      // Remove all non-numeric characters except the decimal point
      final cleaned = distanceString.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // NEW: Helper function to parse both distance (in km) and duration (in minutes)
  Map<String, double> _parseRouteMetrics(String distanceText, String durationText) {
    double distanceKm = 0.0;
    double durationMin = 0.0;

    // 1. Parse Distance 
    try {
      final cleaned = distanceText.replaceAll(RegExp(r'[^\d\.]'), '');
      distanceKm = double.tryParse(cleaned) ?? 0.0;
    } catch (_) {}

    // 2. Parse Duration 
    final duration = _parseDurationString(durationText);
    durationMin = duration.inMinutes.toDouble();
    
    return {
      'distanceKm': distanceKm,
      'durationMin': durationMin,
    };
  }


  // MODIFIED: Comprehensive function to calculate fares using the provided formulas.
  String _getCalculatedFare(String distanceText, String durationText, String transportType) {
    final metrics = _parseRouteMetrics(distanceText, durationText);
    final double distanceKm = metrics['distanceKm']!;
    final double durationMin = metrics['durationMin']!;
    
    if (distanceKm == 0.0) return 'N/A';

    double fare = 0.0;
    
    if (transportType == 'Moto Taxi') {
        // FIX: Implemented the new linear formula: Fare = Base Fare + (Per-km rate * Distance)
        const double motoTaxiBaseFare = 20.74;
        const double motoTaxiPerKmRate = 10.65;
        fare = motoTaxiBaseFare + (distanceKm * motoTaxiPerKmRate);
    } else if (transportType == 'Grab (4-seater)') {
        const double grabBase = 45.0;
        const double grabDistRate = 15.0;
        const double grabTimeRate = 2.0;
        const double grabSurge = 1.5;
        fare = (grabBase + (distanceKm * grabDistRate + durationMin * grabTimeRate)) * grabSurge;
    } else if (transportType == 'Taxi') {
        const double taxiFlagDown = 50.0;
        const double taxiDistRate = 13.50;
        const double taxiTimeRate = 2.0;
        fare = taxiFlagDown + (distanceKm * taxiDistRate) + (durationMin * taxiTimeRate);
    } else if (transportType == 'Modern PUJ') {
        const double modernPujBaseKm = 4.0;
        const double modernPujBaseFare = 15.0;
        const double modernPujSucceedingRate = 2.20;
        fare = modernPujBaseFare;
        if (distanceKm > modernPujBaseKm) {
            fare += (distanceKm - modernPujBaseKm) * modernPujSucceedingRate;
        }
    } else if (transportType == 'Traditional PUJ') {
        const double tradPujBaseKm = 4.0;
        const double tradPujBaseFare = 13.0;
        const double tradPujSucceedingRate = 1.80;
        fare = tradPujBaseFare;
        if (distanceKm > tradPujBaseKm) {
            fare += (distanceKm - tradPujBaseKm) * tradPujSucceedingRate;
        }
    } else if (transportType == 'Aircon Bus') {
        const double acBusBaseKm = 5.0;
        const double acBusBaseFare = 15.0;
        const double acBusSucceedingRate = 2.65;
        fare = acBusBaseFare;
        if (distanceKm > acBusBaseKm) {
            fare += (distanceKm - acBusBaseKm) * acBusSucceedingRate;
        }
    } else if (transportType == 'Non Aircon Bus') {
        const double nonAcBusBaseKm = 5.0;
        const double nonAcBusBaseFare = 13.0;
        const double nonAcBusSucceedingRate = 2.25;
        fare = nonAcBusBaseFare;
        if (distanceKm > nonAcBusBaseKm) {
            fare += (distanceKm - nonAcBusBaseKm) * nonAcBusSucceedingRate; 
        }
    }

    if (fare <= 0.0) return 'N/A';
    // Return fare formatted to currency string with two decimal places
    return '₱${fare.toStringAsFixed(2)}';
  }

  // 3. MODIFIED: Simple function to toggle inline tooltip visibility and set a 3-second timer
  void _showDiscountInfoTooltip(String transportName) {
    // Cancel any existing timer before state change
    _discountTimer?.cancel();
    _discountTimer = null;
    
    setState(() {
      // If we click the same one, close it immediately.
      if (_isDiscountTooltipVisible[transportName] == true) {
        _isDiscountTooltipVisible[transportName] = false;
      } else {
        // Close all others and open the selected one.
        _isDiscountTooltipVisible.updateAll((key, value) => false);
        _isDiscountTooltipVisible[transportName] = true;

        // Start 3-second timer to auto-hide the tooltip
        _discountTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) { // Check if widget is still mounted before calling setState
            setState(() {
              _isDiscountTooltipVisible[transportName] = false;
              _discountTimer = null; // Clear timer reference
            });
          }
        });
      }
    });
  }


  // Function updated to use caching for the expensive Transit API call.
  Future<void> _fetchRealTimeDurations() async {
    if (!mounted) return;
    final apiKey = _getMapApiKey();
    final start = widget.route.polylinePoints.first;
    final end = widget.route.polylinePoints.last;
    final durations = <String, String>{};
    final routeCodes = <String, String>{};
    
    if (widget.route.estimatedFares.isEmpty) {
      if (mounted) setState(() {});
      return; 
    }

    // Cache for the single expensive transit API call
    Map<String, dynamic>? cachedTransitDetails;

    // Iterate over the fixed order to ensure all keys are processed for the UI
    for (var transportType in _transportOrder) { 
      
      if (!widget.route.estimatedFares.containsKey(transportType) && 
          !transportType.contains('PUJ') && !transportType.contains('Bus') &&
          !transportType.contains('Grab') && !transportType.contains('Moto') && !transportType.contains('Taxi')) {
        continue;
      }

      Map<String, dynamic>? details;
      final lowerType = transportType.toLowerCase();
      
      if (lowerType.contains('puj') || lowerType.contains('bus')) {
        
        // 1. Check/Call Transit API (only runs once)
        if (cachedTransitDetails == null) {
          cachedTransitDetails = await MapUtils.getTransitDetails(
            origin: start,
            destination: end,
            apiKey: apiKey,
          );
        }
        details = cachedTransitDetails;
        
        if (details != null && details['steps'] != null) {
          final steps = details['steps'] as List<dynamic>;
          final code = _extractRouteCode(steps);
          if (code != null) {
            routeCodes[transportType] = code;
          }
          // Use the duration fetched from transit details
          durations[transportType] = details['duration'] ?? widget.route.duration;

        } else {
          // Fallback to static duration if transit API failed
          durations[transportType] = widget.route.duration;
        }
        
      } else if (lowerType.contains('moto taxi')) {
        details = await MapUtils.getMotoTaxiDuration(
          origin: start,
          destination: end,
          apiKey: apiKey,
        );
        durations[transportType] = details?['duration'] ?? widget.route.duration;

      } else if (lowerType.contains('taxi') || lowerType.contains('grab')) {
        details = await MapUtils.getDrivingDuration(
          origin: start,
          destination: end,
          apiKey: apiKey,
        );
        durations[transportType] = details?['duration'] ?? widget.route.duration;
      } else {
        // Fallback for any other type
        durations[transportType] = widget.route.duration;
      } 
    }
    
    if (mounted) {
      setState(() {
        _transportDurations = durations;
        _transportRouteCodes = routeCodes; // Set the new state map
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _markers.add(Marker(
      markerId: const MarkerId('start'),
      position: widget.route.polylinePoints.first,
      infoWindow: InfoWindow(title: 'Start', snippet: widget.route.startAddress),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('end'),
      position: widget.route.polylinePoints.last,
      infoWindow: InfoWindow(title: 'End', snippet: widget.route.endAddress),
    ));

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        color: const Color(0xFF4A6FA5),
        points: widget.route.polylinePoints,
        width: 5,
      )
    };
    
    _fetchRealTimeDurations(); // Start fetching durations and codes on load
    
    // Initialize expansion state for all groups
    _transportGroups.keys.forEach((key) => _expansionState[key] = false);
  }
  
  // 4. DISPOSE: Cancel the timer to prevent memory leaks
  @override
  void dispose() {
    _discountTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(widget.route.bounds, 50.0),
    );
  }
  
  // Helper function to calculate 20% discounted fare
  String _calculateDiscountedFare(String originalFare) {
    try {
      final cleanedFare = originalFare.replaceAll(RegExp(r'[^\d\.]'), '');
      if (cleanedFare.isEmpty || cleanedFare == 'N/A') return 'N/A';
      
      final originalAmount = double.parse(cleanedFare);
      
      final discountedAmount = originalAmount * 0.80;
      
      return '₱${discountedAmount.toStringAsFixed(2)}';
    } catch (e) {
      return 'N/A';
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

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
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

  void _deleteRoute() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${widget.route.routeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.route.id != null) {
        try {
          await _routesService.deleteFavoriteRoute(widget.route.id!);
          if (mounted) {
            Navigator.pop(context); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route successfully deleted from cloud.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete route: ${e.toString()}')),
            );
          }
        }
      } else {
        // Fallback for local deletion if ID is missing
          if (mounted) {
          // This relies on the 'favoriteRouteData.dart' import which is not in the shared project structure, but is assumed here.
          // favoriteRoutes.removeWhere((r) => r.routeName == widget.route.routeName); 
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route successfully deleted locally.')),
          );
        }
      }
    }
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
  
  // Renders the individual fare cards inside the expansion panel
  Widget _buildFareOptionCard(ColorScheme cs, String transportName, String fare) {
    
    final discountedFare = _calculateDiscountedFare(fare); 
    
    // Get real-time duration from state, or display loading indicator/fallback
    final currentDuration = _transportDurations[transportName] ?? '...';
    const String defaultDurationPlaceholder = '...';
    final isLoading = currentDuration == defaultDurationPlaceholder;

    // Get Route Code from state
    final routeCode = _transportRouteCodes[transportName];

    // Calculate the real-time departure -> arrival time range
    final timeRange = _calculateArrivalTimeRange(currentDuration);

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
    
    // Check if the discount row should be visible (Taxi, PUJ, Bus are eligible)
    final bool showDiscount = !(transportName.contains('Moto Taxi') || transportName.contains('Grab'));
    
    // Check the state map for inline tooltip visibility
    final bool isTooltipVisible = _isDiscountTooltipVisible[transportName] == true;
    const String tooltipMessage = 
        "20% fare discount applies to Senior Citizens, PWDs, and Students as mandated by Philippine Law.\n(RA 9994 | RA 9442 | RA 11314)";


    return Card(
      // Keep the card for individual transport types
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1, // Reduced elevation since it's inside an expansion tile
      shadowColor: cs.shadow.withAlpha(alpha26), 
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Time Row (Dynamic)
            Row(
              // Vertically centering elements in this row
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Icon(Icons.schedule, color: cs.primary),
                const SizedBox(width: 4), // Reduced spacing
                Expanded(
                  child: Text(
                    timeRange, // Display dynamic time range
                    textAlign: TextAlign.center, // Centered Arrow
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  // Reduced padding for a smaller badge
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), 
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(alpha31), 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isLoading 
                      ? SizedBox(
                          // Spinner size
                          width: 16, 
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        )
                      : Text(
                          _formatDurationShort(currentDuration), // Apply new short format
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 2. Transport Info (Name and Icon)
            transportRow,
            
            // Route Code Display (for PUJ/Bus)
            if (routeCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.directions, size: 20, color: cs.primary), 
                    const SizedBox(width: 8),
                    Text(
                      'Route: $routeCode',
                      style: TextStyle(
                        color: cs.onSurface.withAlpha(alpha179),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Adjust spacing based on whether route code was shown
            SizedBox(height: routeCode == null ? 12 : 0), 

            // 3. Original Estimated Fare Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated fare',
                  style: TextStyle(color: cs.onSurface.withAlpha(alpha179)),
                ),
                Text(
                  fare, // Original calculated fare
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 0), 
            
            // 4. Discounted Fare Section (Row + Inline Tooltip)
            if (showDiscount)
              Column( // Column to hold the discounted row and the inline message
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Discounted', // Simplified text
                            style: TextStyle(
                              color: cs.onSurface.withAlpha(alpha179),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            // MODIFIED: Use the new toggle function
                            onTap: () => _showDiscountInfoTooltip(transportName), 
                            child: Icon(
                              // Show filled icon if visible
                              isTooltipVisible ? Icons.info : Icons.info_outline, 
                              size: 14,
                              // Highlight icon if the info is showing
                              color: isTooltipVisible 
                                  ? cs.primary 
                                  : cs.onSurface.withAlpha(alpha179),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        discountedFare, 
                        style: TextStyle(
                          color: cs.secondary, 
                          fontSize: 14, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  // NEW: Inline Discount Tooltip (attached to the card, scrolls with it)
                  Visibility(
                    visible: isTooltipVisible,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.9), // Darker primary color for contrast
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tooltipMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
            // 5. Conditionally add the collapsible buttons row below the card
            // FIX: Removed curly braces to ensure valid widget assignment in the Column's children List.
            if (transportName == 'Moto Taxi')
                _buildCollapsibleButtons(
                  cs, 
                  transportName, 
                  _buildMotoTaxiButtonsRow(cs)
                ),
            if (transportName == 'Grab (4-seater)')
                _buildCollapsibleButtons(
                  cs, 
                  transportName, 
                  _buildGrabButtonsRow(cs)
                ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: _buildCollapsibleButtons now only handles the ride-hailing app list (Inner Collapsible)
  Widget _buildCollapsibleButtons(ColorScheme cs, String transportType, Widget buttonsRow) {
    final bool isExpanded = _isExpandedMap[transportType] ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Removed "View available transportations" button
          InkWell(
            onTap: () {
              setState(() {
                _isExpandedMap[transportType] = !isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "View available transportations",
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: cs.primary,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: isExpanded,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: buttonsRow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for building individual logo buttons (no text)
  Widget _buildActionButton(ColorScheme cs, String appName, String imagePath, {required Color backgroundColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _launchAppOrStore(appName), // Call the launch function
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(0, 20),
            backgroundColor: backgroundColor, 
          ),
          child: Image.asset(
            imagePath,
            height: 24,
            fit: BoxFit.contain,
            color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, 
            colorBlendMode: BlendMode.modulate, 
          ),
        ),
      ),
    );
  }

  // Row for Moto Taxi services (Angkas, Maxim, MoveIt, JoyRide)
  Widget _buildMotoTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          cs, 
          'Angkas',
          'assets/angkas.png', 
          backgroundColor: angkasBlue,
        ), 
        _buildActionButton(
          cs, 
          'Maxim',
          'assets/maxim.png', 
          backgroundColor: maximYellow,
        ), 
        _buildActionButton(
          cs, 
          'MoveIt',
          'assets/moveit.png', 
          backgroundColor: moveItRed,
        ), 
        _buildActionButton(
          cs, 
          'JoyRide',
          'assets/joyride.png', 
          backgroundColor: joyrideBlue,
        ),
      ],
    );
  }
  
  // Row for Grab services (Grab, JoyRide)
  Widget _buildGrabButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          cs, 
          'Grab',
          'assets/grab.png', 
          backgroundColor: grabGreen,
        ),
        _buildActionButton(
          cs, 
          'JoyRide',
          'assets/joyride.png', 
          backgroundColor: joyrideBlue,
        ),
      ],
    );
  }

  // NEW: Builds the ExpansionTile for a single transport category (e.g., "PUJ")
  Widget _buildFareCategoryPanel(ColorScheme cs, String categoryName, List<String> transportTypes) {
    
    // Default header values (will be calculated dynamically if needed)
    String headerFare = 'N/A';
    String headerDuration = 'N/A';
    
    // Try to find the most favorable fare/duration to display in the header
    // In this simple model, we'll just show the first one's info if available.
    if (transportTypes.isNotEmpty) {
      final firstType = transportTypes.first;
      headerFare = widget.route.estimatedFares[firstType] ?? _getCalculatedFare(widget.route.distance, widget.route.duration, firstType);
      headerDuration = _transportDurations[firstType] ?? '...';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: cs.shadow.withAlpha(alpha26),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          // MODIFIED: Use the correct state property for expansion
          initiallyExpanded: _expansionState[categoryName] ?? false, 
          onExpansionChanged: (isExpanded) {
            setState(() {
              _expansionState[categoryName] = isExpanded;
            });
          },
          // HEADER
          title: Text(
            categoryName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          // HEADER TRAILING (FARES/DURATION SUMMARY)
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headerFare == 'N/A' ? 'N/A' : headerFare, 
                style: TextStyle(
                  color: cs.primary, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 15
                ),
              ),
              const SizedBox(width: 8),
              // Use the default Flutter chevron icon
            ],
          ),
          // EXPANDED BODY (Contains individual fare cards)
          children: transportTypes.map((transportType) {
            
            // Get the fare, calculating it if the original route data is missing
            String fare = widget.route.estimatedFares[transportType] ?? 
                          _getCalculatedFare(widget.route.distance, widget.route.duration, transportType);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: _buildFareOptionCard(cs, transportType, fare),
            );
          }).toList(),
        ),
      ),
    );
  }


  // MODIFIED: Main list now iterates over categories and builds ExpansionTiles
  Widget _buildFareList(ColorScheme cs, Color textColor) {
    
    final List<Widget> fareWidgets = [];
    
    // The fixed order of categories as requested by the user's focus (Moto Taxi, Grab, PUJ, Bus, Taxi)
    final List<String> categoryOrder = ['Moto Taxi', 'Grab', 'PUJ', 'Bus', 'Taxi'];
    
    for (var categoryName in categoryOrder) {
      final transportTypes = _transportGroups[categoryName];
      if (transportTypes != null && transportTypes.isNotEmpty) {
        fareWidgets.add(
          _buildFareCategoryPanel(cs, categoryName, transportTypes)
        );
      }
    }

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
          ...fareWidgets, // fareWidgets is List<Widget>
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color textColor = cs.onSurface;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), 
        title: Text(widget.route.routeName, style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        actions: [
          if (widget.route.id != null) 
            IconButton(
              icon: const Icon(Icons.delete),
              color: cs.onPrimary,
              onPressed: _deleteRoute,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: _getCenter(widget.route.bounds), zoom: 12),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
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
                          _buildRouteInfoRow(icon: Icons.my_location, title: "Start", content: widget.route.startAddress, textColor: textColor),
                          const Divider(height: 30),
                          _buildRouteInfoRow(icon: Icons.location_on, title: "Destination", content: widget.route.endAddress, textColor: textColor),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn("Distance", widget.route.distance, textColor),
                              _buildStatColumn("Duration", widget.route.duration, textColor),
                            ],
                          ),
                          _buildFareList(cs, textColor), // Use the new list builder
                        ],
                      ),
                    ),
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