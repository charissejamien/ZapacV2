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
// (Removed duplicate and unnecessary imports related to ChatMessage and CommentingSection)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math'; // Added for min/max calculation

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
  bool _isMapReady = false; 

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

  // Hardcoded terminal data (USED BY CommentingSection)
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
      }
    },
];
  // MODIFIED: Initial value for the icon is a default, will be updated in initState
  BitmapDescriptor _terminalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  
  String _getMapApiKey() {
    if (Platform.isIOS) {
      return "AIzaSyCWHublkXuYaWfT68qUwGY3o5L9NB82JA8";
    }
    return "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; 
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

    // NEW: Load the custom marker icon
    _loadTerminalIcon(); 
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAndListenToMessages(); 
        setState(() {});
      }
    });
  }
  
  // NEW: Function to load the custom image asset as a BitmapDescriptor
  Future<void> _loadTerminalIcon() async {
      // **NOTE: Change 'assets/images/bus_terminal_pin.png' to your actual asset path.**
      final newIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
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
  
  // Map is set to Cebu - no automatic location detection
  void _onMapCreated(GoogleMapController controller) async { 
    _mapController = controller;
    _isMapReady = true;
    
    // Ensure map stays centered on Cebu
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0),
    );
    
    // Attempt to get and display the initial address
    await _updateCurrentAddress(location: _initialCameraPosition); 
  }


  void _onCommunityInsightExpansionChanged(bool isExpanded) {
    if (!mounted) return;
    setState(() {
      _isCommunityInsightExpanded = isExpanded;
    });
  }

  void _addNewInsight(ChatMessage newInsight) {
    // Logger.info("Insight added, Firebase listener will refresh UI.");
  }
  
  // NEW FUNCTION: Handler for the Add Insight FAB
  void _handleAddInsightPressed() {
    if (!mounted) return;
    
    // Calls the modal function from addInsight.dart
    showAddInsightModal(
      context: context,
      firestore: _firestore,
      onInsightAdded: _addNewInsight, 
    );
  }

  // FIX 1: Using the now-available MapUtils.getAddressFromLatLng
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


  // Handler for when a hardcoded terminal marker is tapped
  void _handleTerminalTapped(String terminalId) {
      final terminal = _hardcodedTerminals.firstWhere(
          (t) => t['id'] == terminalId,
          orElse: () => <String, dynamic>{}, 
      );

      // Add check to ensure terminal is not the empty fallback map
      if (terminal.isNotEmpty && mounted) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                  return TerminalDetailsModal(
                      details: terminal['details'] as Map<String, String>,
                      cs: Theme.of(context).colorScheme,
                  );
              },
          );
      }
  }


  // MODIFIED: _handleMyLocationPressed to collapse sheet, center on actual location and manage modal visibility
  Future<void> _handleMyLocationPressed() async {
    if (!mounted || !_isMapReady) return;
    
    // Collapse the Community Insights Sheet if it is expanded
    if (_isCommunityInsightExpanded) {
        setState(() {
            _isCommunityInsightExpanded = false; // THIS LINE COLLAPSES THE SHEET
        });
        await Future.delayed(const Duration(milliseconds: 350)); 
    }
    
    // Clear any existing timer
    _addressTimer?.cancel(); 
    
    // Clear previous search/route markers
    _markers.clear();
    _polylines.clear(); 
    
    // 1. Fetch the user's actual current location
    final LatLng? currentLocation = await MapUtils.getCurrentLocation(context);

    if (currentLocation != null) {
      // 2. Animate the camera to the current location (GPS)
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 16.0), // Use a closer zoom level
      );
      // 3. Update address based on new location
      await _updateCurrentAddress(location: currentLocation); 
      
      // 4. Show the address modal and start timer
      if (!mounted) return; // Guard against async gap
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
      // Fallback: If location is unavailable, reset to Cebu center
      if (!mounted) return; // Guard against async gap
      
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location. Check permissions.')),
        );
      }
      // Update address to the fallback location
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
      
      if (!mounted) return; // Guard against async gap

      // FIX: Replace non-existent getRouteDetails with getRouteAndDetails
      // This new function handles drawing the route and returns real-time driving details.
      final routeDetails = await MapUtils.getRouteAndDetails(
          item: item, 
          apiKey: _getMapApiKey(),
          markers: _markers,
          polylines: _polylines,
          mapController: _mapController,
          context: context,
      );

      if (!mounted) return; // Guard against async gap

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
      });
      // Camera animation handled inside MapUtils.getRouteAndDetails
    }
  }

  void _clearSearchMarker() {
      // Hide the temporary address modal when searching/clearing
      _addressTimer?.cancel();
      setState(() {
          _showAddressModal = false;
      });
      
      if (_markers.isNotEmpty || _polylines.isNotEmpty || _showDetailsButton) {
          setState(() {
              _markers.clear();
              _polylines.clear();
              _showDetailsButton = false;
              _currentSearchDetails = {};
              _currentSearchName = null;
          });
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_initialCameraPosition, 14.0), 
          );
      }
      // Re-fetch current address when markers are cleared
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

  // MODIFIED: Widget for the temporary, address modal, constrained width/height, non-full-width
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
                width: 250, // MODIFIED: Changed width from 300 to 250
                // MODIFIED: Changed minHeight from 60 to 56.0 (standard FAB height)
                constraints: const BoxConstraints(minHeight: 56.0), 
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                        BoxShadow(
                            // FIX: Replaced .withOpacity(0.15) with .withAlpha(38)
                            color: cs.onSurface.withAlpha(38),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                        ),
                    ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text(
                            "CURRENTLY AT",
                            style: TextStyle(
                                fontSize: 9, // MODIFIED: Reduced font size for better fit
                                fontWeight: FontWeight.bold,
                                color: cs.secondary,
                            ),
                        ),
                        const SizedBox(height: 1), // MODIFIED: Reduced spacing
                        // Text should flow, max 2 lines to maintain compact height
                        Text( 
                            _currentAddress, // State variable
                            style: TextStyle(
                                fontSize: 11, // MODIFIED: Reduced font size for better fit
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                            ),
                            maxLines: 2, // Constrain lines to fit the smaller height
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

            // MODIFIED: Pass the hardcoded terminal data
            CommentingSection(
              chatMessages: _liveChatMessages, 
              onExpansionChanged: _onCommunityInsightExpansionChanged,
              currentUserId: _currentUserId,
              hardcodedTerminals: _hardcodedTerminals, // <--- NEW PROP
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
                // Repositioned to the bottom right when expanded
                bottom: _isCommunityInsightExpanded ? 10 : null, 
                // Repositioned to the top right when collapsed
                top: _isCommunityInsightExpanded ? null : 80, 

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation, 
                    child: child);
                },

              // Use Row to place modal beside the FloatingButton stack
              key: ValueKey<bool>(_isCommunityInsightExpanded),
              child: Row( 
                mainAxisSize: MainAxisSize.min,
                // Align content to the bottom of the tallest element in the Row (which is the FAB stack)
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                    // Modal appears on the LEFT of the buttons
                    if (_showAddressModal && !_isCommunityInsightExpanded) 
                        // Wrap in a Column to allow vertical centering/alignment within the space defined by the Row
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
                            FloatingButton(
                              isCommunityInsightExpanded: _isCommunityInsightExpanded,
                              onMyLocationPressed: _handleMyLocationPressed, 
                              onAddInsightPressed: _handleAddInsightPressed, // NEW: Pass the Add Insight handler
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
// Terminal Details Modal Widget
// =========================================================================

class TerminalDetailsModal extends StatelessWidget {
  final Map<String, String> details;
  final ColorScheme cs;

  const TerminalDetailsModal({super.key, required this.details, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(details['title'] ?? 'Terminal Details', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(context, 'Status', details['status'] ?? 'N/A', Icons.access_time_filled, cs),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'Primary Routes', details['routes'] ?? 'N/A', Icons.directions_bus, cs),
            const SizedBox(height: 10),
            _buildDetailRow(context, 'Facilities', details['facilities'] ?? 'N/A', Icons.local_convenience_store, cs),
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
              // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
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

// =========================================================================
// NOTE: This placeholder reflects the original structure from lib/core/widgets/app_floating_button.dart
// It has been replaced by the actual content in the next section for standalone compilation.
// However, the dashboard depends on the file existing.
// =========================================================================

// For compilation completeness, the placeholder class is kept here, 
// but its logical content is placed in the actual app_floating_button.dart section.
// The dashboard relies on a FloatingButton widget with the defined interface.
// If this file were truly lib/dashboard/dashboard.dart, the definition below would be removed.
// Assuming for now the definition below is correct for the sake of the dashboard.
/*
class FloatingButton extends StatelessWidget {
  final bool isCommunityInsightExpanded;
  final VoidCallback onMyLocationPressed;

  const FloatingButton({
    super.key,
    required this.isCommunityInsightExpanded,
    required this.onMyLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder implementation for functionality not available in provided files
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'my_location',
          onPressed: onMyLocationPressed,
          backgroundColor: const Color(0xFF6CA89A), 
          foregroundColor: Colors.white, 
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
*/