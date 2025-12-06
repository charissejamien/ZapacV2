import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/dashboard/models/chat_message.dart';
import 'package:zapac/dashboard/route_details_overlay.dart'; 
import 'community_insights_page.dart';
import '../core/widgets/searchBar.dart';
import '../core/widgets/app_floating_button.dart'; // Ensure this is the correct import path
import 'addInsight.dart';
import '../core/utils/map_utils.dart'; 
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math'; 

// Dark Map Style JSON (Night/Aubergine inspired)
const String _darkMapStyleJson = r'''
[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263e"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263e"}]}]
''';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late GoogleMapController _mapController; 
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  // The initial position remains a fallback until location is loaded
  final LatLng _initialCameraPosition = const LatLng(10.314481680817886, 123.88813209917954);

  bool _isCommunityInsightExpanded = false;
  bool _isShowingTerminals = false; 
  bool _isMapReady = false; 
  
  // NEW STATE: Tracks the ID of the terminal being viewed in detail in the sheet.
  String? _selectedTerminalId; 

  List<ChatMessage> _liveChatMessages = [];
  StreamSubscription? _chatSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  
  bool _showDetailsButton = false;
  Map<String, dynamic> _currentSearchDetails = {};
  String? _currentSearchName;
  
  // State to hold the current address
  String _currentAddress = "Fetching location..."; 
  
  // State: Control visibility of the temporary address modal
  bool _showAddressModal = false;
  Timer? _addressTimer; 

  final List<Map<String, dynamic>> _hardcodedTerminals = const [
    {
      'id': 'cebu_south_terminal',
      'name': 'Cebu South Bus Terminal',
      'lat': 10.3015, 
      'lng': 123.8965, 
      'details': {
        'title': 'Cebu South Bus Terminal',
        'status': 'Open 24/7',
        'routes': 'Southern Cebu (Oslob, Moalboal, Carcar)',
        'facilities': 'Restrooms, Ticketing Counters, Food Stalls',
        'routes_fares': [
            {'route': 'Cebu City to Oslob (via Bato)', 'fare': 'P 250 - P 300'},
            {'route': 'Cebu City to Moalboal', 'fare': 'P 180 - P 220'},
            {'route': 'Cebu City to Carcar City', 'fare': 'P 50 - P 70'},
            {'route': 'Cebu City to Liloan (Santander)', 'fare': 'P 350 - P 400'},
        ],
      }
    },
    {
      'id': 'cebu_north_terminal',
      'name': 'Cebu North Bus Terminal',
      'lat': 10.3200, 
      'lng': 123.9110, 
      'details': {
        'title': 'Cebu North Bus Terminal',
        'status': 'Open 4:00 AM - 10:00 PM',
        'routes': 'Northern Cebu (Bogo, Daanbantayan, Danao)',
        'facilities': 'Waiting Area, Ticket Booths, Vending Machines',
        'routes_fares': [
            {'route': 'Cebu City to Bogo City', 'fare': 'P 150 - P 200'},
            {'route': 'Cebu City to Daanbantayan', 'fare': 'P 250 - P 350'},
            {'route': 'Cebu City to Danao City', 'fare': 'P 50 - P 75'},
        ],
      }
    },
    {
      'id': 'sm_city_cebu_terminal',
      'name': 'SM City Cebu PUV Terminal',
      'lat': 10.3164, 
      'lng': 123.9189, 
      'details': {
        'title': 'SM City Cebu PUV Terminal',
        'status': 'Open 10:00 AM - 9:00 PM',
        'routes': 'Route 01K, 03B, 04H (Modern Jeepneys)',
        'facilities': 'Sheltered Waiting Area, CCTV, Access to Mall',
        'routes_fares': [
            {'route': 'SM City to IT Park (01K)', 'fare': 'P 15 - P 25'},
            {'route': 'SM City to Ayala Center (03B)', 'fare': 'P 15 - P 25'},
            {'route': 'SM City to Fuente Osmeña (04H)', 'fare': 'P 20 - P 30'},
        ],
      }
    },
    {
      'id': 'ayala_puv_terminal',
      'name': 'Ayala Public Utility Vehicle Terminal',
      'lat': 10.3177, 
      'lng': 123.905, 
      'details': {
        'title': 'Ayala Public Utility Vehicle Terminal',
        'status': 'Open 10:00 AM - 9:00 PM',
        'routes': 'Route 01K, 03B, 04H (Modern Jeepneys)',
        'facilities': 'Sheltered Waiting Area, CCTV, Access to Mall',
        'routes_fares': [
            {'route': 'Ayala to SM City (03B)', 'fare': 'P 15 - P 25'},
            {'route': 'Ayala to IT Park (01K)', 'fare': 'P 15 - P 25'},
            {'route': 'Ayala to Mango Ave', 'fare': 'P 13 - P 20'},
        ],
      }
    },
    {
      'id': 'cebu_itpark_transport_terminal',
      'name': 'Cebu IT Park Transport Terminal',
      'lat': 10.3317, 
      'lng': 123.9065, 
      'details': {
        'title': 'Cebu IT Park Transport Terminal',
        'status': 'Open 10:00 AM - 9:00 PM',
        'routes': 'Route 01K, 03B, 04H (Modern Jeepneys)',
        'facilities': 'Sheltered Waiting Area, CCTV, Access to Mall',
        'routes_fares': [
            {'route': 'IT Park to SM City (01K)', 'fare': 'P 15 - P 25'},
            {'route': 'IT Park to Colon St', 'fare': 'P 20 - P 30'},
            {'route': 'IT Park to Mandaue', 'fare': 'P 18 - P 28'},
        ],
      }
    },
];
  BitmapDescriptor _terminalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  
  String _getMapApiKey() {
    if (Platform.isIOS) {
      return dotenv.env['GOOGLE_MAPS_API_KEY_IOS']!;
    }
    return dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID']!;
  }

  String? _currentUserId;
  StreamSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUserId = user?.uid;
        });
      }
    });

    _loadTerminalIcon(); 
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAndListenToMessages(); 
        setState(() {});
      }
    });
  }

  // NEW: Handle theme changes after map is created
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isMapReady) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      // Set map style to dark JSON string if dark mode is active, or "[]" for default (light) style
      final mapStyle = isDarkMode ? _darkMapStyleJson : "[]";
      _mapController.setMapStyle(mapStyle);
    }
  }
  
  // MODIFIED: Function to load the custom image asset as a BitmapDescriptor with larger size
  Future<void> _loadTerminalIcon() async {
      // Increased the logical size to 80x80 dp for a bigger icon.
      final newIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(80, 80)),
          'assets/insightsIcon.png', 
      );
      if (mounted) {
          setState(() {
              _terminalIcon = newIcon;
          });
      }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel(); 
    _authStateSubscription?.cancel();
    _addressTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  void _fetchAndListenToMessages() {
    final insightsCollection = _firestore
        .collection('public_data')
        .doc('zapac_community')
        .collection('comments');
        
    _chatSubscription = insightsCollection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return; 
      
      final List<ChatMessage> fetchedMessages = snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc);
      }).toList();

      List<ChatMessage> combinedMessages = [];
      combinedMessages.addAll(fetchedMessages);
      
      combinedMessages.sort((a, b) {
          final aTime = a.createdAt?.toDate().millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.toDate().millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
      });
      
      setState(() {
        _liveChatMessages = combinedMessages;
      });

    }, onError: (error) {
      // Logger.error("Error fetching community insights: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load community feed.')),
        );
      }
    });
  }
  
  // MODIFIED: Logic to center map on current location AND apply map style
  void _onMapCreated(GoogleMapController controller) async { 
    _mapController = controller;
    _isMapReady = true;

    // Apply initial map style based on current theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      _mapController.setMapStyle(_darkMapStyleJson);
    } else {
      _mapController.setMapStyle("[]"); // Explicitly setting to default style
    }
    
    // 1. Try to get current location
    final LatLng? currentLocation = await MapUtils.getCurrentLocation(context);
    LatLng targetLocation;
    double targetZoom;
    
    if (currentLocation != null) {
      targetLocation = currentLocation;
      targetZoom = 16.0; // Zoom in closer for current location
    } else {
      // 2. Fallback to hardcoded position
      targetLocation = _initialCameraPosition;
      targetZoom = 14.0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location. Showing default area.')),
        );
      }
    }
    
    // 3. Animate camera to the determined location
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(targetLocation, targetZoom),
    );
    
    // 4. Update address display for the determined location
    await _updateCurrentAddress(location: targetLocation); 
    
    // 5. Show the address modal briefly if we used current location
    if (currentLocation != null && mounted) {
        setState(() {
            _showAddressModal = true;
        });

        _addressTimer = Timer(const Duration(seconds: 5), () {
            if(mounted) {
                setState(() {
                    _showAddressModal = false;
                });
            }
        });
    }
  }

  void _onCommunityInsightExpansionChanged(bool isExpanded) {
    if (!mounted) return;
    setState(() {
      _isCommunityInsightExpanded = isExpanded;
      // When the sheet is collapsed, revert to the default (Insights) view
      if (!isExpanded) {
          _isShowingTerminals = false;
          _selectedTerminalId = null; // Clear detail view on collapse
      }
    });
  }

  void _addNewInsight(ChatMessage newInsight) {
    // Logger.info("Insight added, Firebase listener will refresh UI.");
  }
  
  void _handleAddInsightPressed() {
    if (!mounted) return;
    
    showAddInsightModal(
      context: context,
      firestore: _firestore,
      onInsightAdded: _addNewInsight, 
    );
  }

  // NEW FUNCTION: Handler when a terminal is clicked in the sheet list
  void _handleTerminalCardSelected(String terminalId) {
    if (!mounted) return;
    setState(() {
      _selectedTerminalId = terminalId;
      _isCommunityInsightExpanded = true; // Ensure the sheet is expanded to show details
    });
  }
  
  // NEW FUNCTION: Handler for the back button in the detail view
  void _handleBackToTerminals() {
    if (!mounted) return;
    setState(() {
      _selectedTerminalId = null; // Go back to the list view
      // The sheet remains expanded, showing the full list.
    });
  }
  
  void _handleTerminalsPressed() {
    if (!mounted || !_isMapReady) return;
    
    setState(() {
        _isCommunityInsightExpanded = false; 
        _isShowingTerminals = true; 
        _selectedTerminalId = null; // Ensure we start at the list view
    });

    _markers.clear();
    _polylines.clear();
    _addressTimer?.cancel(); 
    
    setState(() {
        _showDetailsButton = false;
        _currentSearchDetails = {};
        _showAddressModal = false;
    });

    final Set<Marker> terminalMarkers = {};
    final List<LatLng> positions = [];

    for (var terminal in _hardcodedTerminals) {
        final position = LatLng(terminal['lat'] as double, terminal['lng'] as double);
        positions.add(position);
        
        terminalMarkers.add(
            Marker(
                markerId: MarkerId(terminal['id'] as String),
                position: position,
                icon: _terminalIcon, 
                infoWindow: InfoWindow(
                    title: terminal['name'] as String,
                    snippet: terminal['details']['status'] as String,
                ),
                onTap: () => _handleTerminalTapped(terminal['id'] as String),
            ),
        );
    }
    
    setState(() {
        _markers.addAll(terminalMarkers);
    });
    
    if (positions.isNotEmpty) {
        double minLat = positions.map((p) => p.latitude).reduce(min);
        double maxLat = positions.map((p) => p.latitude).reduce(max);
        double minLng = positions.map((p) => p.longitude).reduce(min);
        double maxLng = positions.map((p) => p.longitude).reduce(max);
        
        final bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
        );
        
        _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
    } else {
        _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0),
        );
    }
  }

  Future<void> _updateCurrentAddress({LatLng? location}) async {
    if (!mounted) return;

    LatLng? currentLatLng = location ?? await MapUtils.getCurrentLocation(context);

    if (currentLatLng != null) {
      try {
        final address = await MapUtils.getAddressFromLatLng(
          latLng: currentLatLng,
          apiKey: _getMapApiKey(), // Use your map API key for geocoding
        );
        setState(() {
          _currentAddress = address ?? "Location not found.";
        });
      } catch (e) {
        // Logger.error("Reverse Geocoding Error: $e");
        setState(() {
          _currentAddress = "Error getting address.";
        });
      }
    } else {
      setState(() {
        _currentAddress = "Location access denied.";
      });
    }
  }


  void _handleTerminalTapped(String terminalId) {
      final terminal = _hardcodedTerminals.firstWhere(
          (t) => t['id'] == terminalId,
          orElse: () => <String, dynamic>{}, 
      );

      if (terminal.isNotEmpty && mounted) {
          // Keep the existing dialog for marker taps on the map
          showDialog(
              context: context,
              builder: (BuildContext context) {
                  return TerminalDetailsModal(
                      details: terminal['details'] as Map<String, dynamic>,
                      cs: Theme.of(context).colorScheme,
                  );
              },
          );
      }
  }


  Future<void> _handleMyLocationPressed() async {
    if (!mounted || !_isMapReady) return;
    
    if (_isCommunityInsightExpanded || _isShowingTerminals) {
        setState(() {
            _isCommunityInsightExpanded = false; // THIS LINE COLLAPSES THE SHEET
            _isShowingTerminals = false; // Reset view to default (insights)
            _selectedTerminalId = null; // Clear detail view
        });
        await Future.delayed(const Duration(milliseconds: 350)); 
    }
    
    _addressTimer?.cancel(); 
    
    _markers.clear();
    _polylines.clear(); 
    
    final LatLng? currentLocation = await MapUtils.getCurrentLocation(context);

    if (currentLocation != null) {
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 16.0), 
      );
      await _updateCurrentAddress(location: currentLocation); 
      
      if (!mounted) return;
      setState(() {
          _showAddressModal = true;
      });

      _addressTimer = Timer(const Duration(seconds: 5), () {
          if(mounted) {
              setState(() {
                  _showAddressModal = false;
              });
          }
      });

    } else {
      if (!mounted) return;
      
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location. Check permissions.')),
        );
      }
      await _updateCurrentAddress(location: _initialCameraPosition);
    }
    
    if (mounted) {
        setState(() {
            _showDetailsButton = false;
            _currentSearchDetails = {};
        });
    }
  }
  
  Future<void> _handlePlaceSelected(dynamic item) async {
    if (!mounted || !_isMapReady) return;
    
    double? lat;
    double? lng;
    String? name;

    if (item.containsKey('place')) {
      final place = item['place'];
      lat = place['latitude'] as double;
      lng = place['longitude'] as double;
      name = place['description'] as String;
    } else if (item.containsKey('recent_location')) {
      final location = item['recent_location'];
      lat = location['latitude'] as double;
      lng = location['longitude'] as double;
      name = location['name'] as String;
    }

    if (lat != null && lng != null) {
      final LatLng? currentLocation = await MapUtils.getCurrentLocation(context);
      if (currentLocation == null) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not get current location for route details.')),
              );
          }
          return;
      }
      
      if (!mounted) return;

      final routeDetails = await MapUtils.getRouteAndDetails(
          item: item, 
          apiKey: _getMapApiKey(),
          markers: _markers,
          polylines: _polylines,
          mapController: _mapController,
          context: context,
      );

      if (!mounted) return;

      setState(() {
        _currentSearchName = name;
        if (routeDetails.isNotEmpty) {
            _currentSearchDetails = routeDetails;
            _showDetailsButton = true; 
        } else {
            _currentSearchDetails = {'distance': 'N/A', 'duration': 'N/A'};
            _showDetailsButton = true;
            // Logger.error("Failed to fetch route details.");
        }
        _isShowingTerminals = false; 
        _selectedTerminalId = null; // Clear detail view
      });
    }
  }

  void _clearSearchMarker() {
      _addressTimer?.cancel();
      setState(() {
          _showAddressModal = false;
      });
      
      if (_markers.isNotEmpty || _polylines.isNotEmpty || _showDetailsButton || _isShowingTerminals) {
          setState(() {
              _markers.clear();
              _polylines.clear();
              _showDetailsButton = false;
              _currentSearchDetails = {};
              _currentSearchName = null;
              _isShowingTerminals = false; 
              _selectedTerminalId = null; // Clear detail view
          });
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0), 
          );
      }
      _updateCurrentAddress();
  }

  void _showDetailsOverlay() {
      if (_currentSearchDetails.isEmpty || _currentSearchName == null) return;
      
      showDialog(
          context: context,
          builder: (BuildContext context) {
              return RouteDetailsOverlay(
                  destinationName: _currentSearchName!,
                  distance: _currentSearchDetails['distance'] ?? 'Unknown',
                  duration: _currentSearchDetails['duration'] ?? 'Unknown',
                  onClose: () => Navigator.of(context).pop(),
              );
          },
      );
  }

  Widget _buildAddressModal(ColorScheme cs) {
    return AnimatedOpacity(
        opacity: _showAddressModal ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Visibility(
            visible: _showAddressModal,
            maintainAnimation: true,
            maintainState: true,
            maintainSize: true,
            child: Container(
                width: 250, 
                constraints: const BoxConstraints(minHeight: 56.0), 
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                        BoxShadow(
                            color: cs.onSurface.withAlpha(38),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                        ),
                    ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, 
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text(
                            "CURRENTLY AT",
                            style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold,
                                color: cs.secondary,
                            ),
                        ),
                        const SizedBox(height: 1), 
                        Text( 
                            _currentAddress, 
                            style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                            ),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                        ),
                    ],
                ),
            ),
        ),
    );
}


  @override
  Widget build(BuildContext context) {
    final bottomSheetHeight = MediaQuery.of(context).size.height * (_isCommunityInsightExpanded ? 0.85 : 0.35);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(10.314481680817886, 123.88813209917954),
                  zoom: 14.0,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
              ),
            ),

            // Pass all required props to CommentingSection
            CommentingSection(
              chatMessages: _liveChatMessages, 
              onExpansionChanged: _onCommunityInsightExpansionChanged,
              currentUserId: _currentUserId,
              hardcodedTerminals: _hardcodedTerminals, 
              isShowingTerminals: _isShowingTerminals, 
              onShowTerminalsPressed: _handleTerminalsPressed, 
              
              selectedTerminalId: _selectedTerminalId, 
              onTerminalCardSelected: _handleTerminalCardSelected, 
              onBackToTerminals: _handleBackToTerminals, 
            ),
            
            // Contains SearchBar 
            Positioned(
              top: 15,
              left: 0, 
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SearchBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SearchBar(
                      onPlaceSelected: _handlePlaceSelected,
                      onSearchCleared: _clearSearchMarker,
                    ),
                  ),
                ],
              ),
            ),

            if (_showDetailsButton)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: 16,
                right: 16,
                bottom: bottomSheetHeight - 50,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _showDetailsOverlay,
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('SHOW DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

            // Floating Buttons and Address Modal (right edge)
            AnimatedPositioned(
               duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                right: _isCommunityInsightExpanded ? 16 :10,
                bottom: _isCommunityInsightExpanded ? 10 : null, 
                top: _isCommunityInsightExpanded ? null : 80, 

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation, 
                    child: child);
                },

              key: ValueKey<bool>(_isCommunityInsightExpanded),
              child: Row( 
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                    if (_showAddressModal && !_isCommunityInsightExpanded) 
                        Column( 
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                _buildAddressModal(cs),
                            ],
                        ),
                    
                    if (_showAddressModal && !_isCommunityInsightExpanded) const SizedBox(width: 8),

                    // Floating Button Stack (RIGHT)
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            // Pass all required props to FloatingButton
                            FloatingButton(
                              isCommunityInsightExpanded: _isCommunityInsightExpanded,
                              isShowingTerminals: _isShowingTerminals, 
                              onMyLocationPressed: _handleMyLocationPressed, 
                              onAddInsightPressed: _handleAddInsightPressed,
                              onTerminalPressed: _handleTerminalsPressed, 
                            ),
                        ],
                    ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Terminal Details Modal Widget (Kept here as it's used by map marker taps)
// =========================================================================

class TerminalDetailsModal extends StatelessWidget {
  // FIX: Change to Map<String, dynamic> to handle nested lists in details
  final Map<String, dynamic> details; 
  final ColorScheme cs;

  const TerminalDetailsModal({super.key, required this.details, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(details['title'] as String? ?? 'Terminal Details', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: Add safe casting for string fields
            _buildDetailRow(context, 'Status', details['status'] as String? ?? 'N/A', Icons.access_time_filled, cs),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'Primary Routes', details['routes'] as String? ?? 'N/A', Icons.directions_bus, cs),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'Facilities', details['facilities'] as String? ?? 'N/A', Icons.local_convenience_store, cs),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('CLOSE', style: TextStyle(color: cs.primary)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: cs.secondary, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface.withAlpha(179))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}