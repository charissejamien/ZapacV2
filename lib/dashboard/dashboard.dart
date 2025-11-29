import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/settings/settings_page.dart';
import 'package:zapac/settings/profile_page.dart';
import 'package:zapac/dashboard/route_details_overlay.dart'; 
import 'community_insights_page.dart';
import '../core/widgets/searchBar.dart';
import '../core/widgets/app_floating_button.dart';
import 'addInsight.dart';
import '../core/utils/map_utils.dart'; 
import 'dart:io' show Platform;
import 'community_insights_page.dart' show ChatMessage;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math'; // Added for min/max calculation

// Category Model for the Chips
class Category {
  final String label;
  final IconData icon;
  final String placeType; // Google Place Type identifier

  const Category({required this.label, required this.icon, required this.placeType});
}

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
  int _selectedIndex = 0;
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

  // Hardcoded terminal data
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
];
  // NEW: Terminal Icon
  BitmapDescriptor _terminalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  // List of categories for the chips
  static const List<Category> _categories = [
    Category(label: 'Terminal', icon: Icons.tram, placeType: 'bus_station'), // Use bus_station for PUV terminals
    Category(label: 'Mall', icon: Icons.shopping_bag, placeType: 'shopping_mall'),
    Category(label: 'Grocery', icon: Icons.local_grocery_store, placeType: 'supermarket'),
    Category(label: 'Gasoline', icon: Icons.local_gas_station, placeType: 'gas_station'),
    Category(label: 'School', icon: Icons.school, placeType: 'school'),
    Category(label: 'Hospital', icon: Icons.local_hospital, placeType: 'hospital'),
  ];
  
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

    // NOTE: If you add an asset 'assets/icons/bus_icon.png', uncomment and change the path here
    // _loadTerminalIcon(); 
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAndListenToMessages(); 
        setState(() {});
      }
    });
  }
  
  // NOTE: This function is only needed if you use a custom asset for the terminal icon.
  /*
  Future<void> _loadTerminalIcon() async {
      final newIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/icons/bus_icon.png', // Replace with your actual path
      );
      if (mounted) {
          setState(() {
              _terminalIcon = newIcon;
          });
      }
  }
  */

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
      print("Error fetching community insights: $error");
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

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); 
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); 
    }
  }

  void _onCommunityInsightExpansionChanged(bool isExpanded) {
    if (!mounted) return;
    setState(() {
      _isCommunityInsightExpanded = isExpanded;
    });
  }

  void _addNewInsight(ChatMessage newInsight) {
    print("Insight added, Firestore listener will refresh UI.");
  }

  // Function to fetch and display the current address
  Future<void> _updateCurrentAddress({LatLng? location}) async {
    if (!mounted) return;

    LatLng? currentLatLng = location;
    if (currentLatLng == null) {
      currentLatLng = await MapUtils.getCurrentLocation(context);
    }

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
        print("Reverse Geocoding Error: $e");
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
      final newPosition = LatLng(lat, lng);
      
      final LatLng? currentLocation = await MapUtils.getCurrentLocation(context);
      if (currentLocation == null) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not get current location for route details.')),
              );
          }
          return;
      }

      final routeDetails = await MapUtils.getRouteDetails(
          origin: currentLocation,
          destination: newPosition,
          apiKey: _getMapApiKey(),
      );

      setState(() {
        _markers.clear();
        _polylines.clear(); 

        _markers.add(
          Marker(
            markerId: const MarkerId('destination_search'),
            position: newPosition,
            infoWindow: InfoWindow(title: name ?? 'Selected Location'),
          ),
        );
        
        _currentSearchName = name;
        if (routeDetails != null) {
            _currentSearchDetails = routeDetails;
            _showDetailsButton = true; 
        } else {
            _currentSearchDetails = {'distance': 'N/A', 'duration': 'N/A'};
            _showDetailsButton = true;
            print("Failed to fetch route details.");
        }
      });

      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 16.0),
      );
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

  // MODIFIED: Function to search POIs by category (Points 1, 2, 3 implemented here)
  Future<void> _searchPOIsByCategory(String placeType) async {
    if (!mounted || !_isMapReady || _mapController == null) return; 
    _clearSearchMarker(); 

    // Handle hardcoded terminals separately
    if (placeType == 'bus_station') {
      _markers.clear();
      
      // Variables for bounds calculation (Point 2)
      double minLat = 90.0, maxLat = -90.0;
      double minLng = 180.0, maxLng = -180.0;

      for (var terminal in _hardcodedTerminals) {
        final lat = terminal['lat'] as double;
        final lng = terminal['lng'] as double;
        
        // Calculate bounds
        minLat = min(minLat, lat);
        maxLat = max(maxLat, lat);
        minLng = min(minLng, lng);
        maxLng = max(maxLng, lng);

        _markers.add(
          Marker(
            markerId: MarkerId(terminal['id'] as String),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: terminal['name'] as String),
            icon: _terminalIcon, // Use custom icon (Pin will be Green - Point 3)
            onTap: () => _handleTerminalTapped(terminal['id'] as String),
          ),
        );
      }
      
      if (mounted) {
        setState(() {
          _showDetailsButton = false;
        });
        // REMOVED: Snackbar notification (Point 1)
      }
      
      // Zoom to fit all terminal locations (Point 2)
      if (_hardcodedTerminals.isNotEmpty) {
          final bounds = LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
          );
          // 50.0 padding is added for better visual spacing around the markers
          _mapController.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50.0), 
          );
      }
      return; // Exit here to use hardcoded markers for terminals
    }

    // Existing Google Places API logic for other categories
    try {
      // Use getVisibleRegion() and calculate center from bounds
      final LatLngBounds bounds = await _mapController.getVisibleRegion();
      final LatLng mapCenter = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      
      final String apiKey = _getMapApiKey();

      final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${mapCenter.latitude},${mapCenter.longitude}&radius=5000&type=$placeType&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          _markers.clear();
          
          for (var result in results) {
            final lat = result['geometry']['location']['lat'];
            final lng = result['geometry']['location']['lng'];
            final name = result['name'];
            
            _markers.add(
              Marker(
                markerId: MarkerId(result['place_id']),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: name),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
          }

          if (mounted) {
            setState(() {
              _showDetailsButton = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Found ${results.length} ${placeType.replaceAll("_", " ")}s nearby.')),
            );
          }
        } else {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No results found for this category nearby.')),
              );
          }
        }
      } else {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to fetch POI data from Google Places.')),
            );
         }
      }
    } catch (e) {
      print("POI Search Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred during POI search.')),
        );
      }
    }
  }

  // Widget to build the horizontal list of category chips
  Widget _buildCategoryChips(ColorScheme cs) {
    return Container(
      height: 48, // Fixed height for the horizontal list
      margin: const EdgeInsets.only(top: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: EdgeInsets.only(right: index == _categories.length - 1 ? 0 : 8.0),
            child: ActionChip(
              avatar: Icon(category.icon, size: 18, color: cs.primary),
              label: Text(category.label, style: TextStyle(color: cs.onSurface)),
              backgroundColor: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: cs.primary.withOpacity(0.5)),
              ),
              onPressed: () {
                _searchPOIsByCategory(category.placeType);
              },
            ),
          );
        },
      ),
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
                width: 300, // Increased width
                constraints: const BoxConstraints(minHeight: 60), // Minimum height for alignment
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                        BoxShadow(
                            color: cs.onSurface.withOpacity(0.15),
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
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.secondary,
                            ),
                        ),
                        const SizedBox(height: 2),
                        // Text should flow, max 2 lines to maintain compact height
                        Text( 
                            _currentAddress, // State variable
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                            ),
                            maxLines: 3, // Constrain lines to fit
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),

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

            CommentingSection(
              chatMessages: _liveChatMessages, 
              onExpansionChanged: _onCommunityInsightExpansionChanged,
              currentUserId: _currentUserId,
            ),
            
            // Contains SearchBar and Category Chips
            Positioned(
              top: 8,
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
                  // Category Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildCategoryChips(cs), 
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
                bottom: _isCommunityInsightExpanded ? 10 : 500,
                top: _isCommunityInsightExpanded ? null : 50,

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation, 
                    child: child);
                },

              // Use Row to place modal beside the FloatingButton stack
              child: Row( 
                key: ValueKey<bool>(_isCommunityInsightExpanded),
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
                              onAddInsightPressed: () {
                                final currentUserId = _auth.currentUser?.uid;
                                if (!mounted) return;

                                if (currentUserId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please sign in to post an insight.'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                showAddInsightModal(
                                  context: context,
                                  firestore: _firestore,
                                  onInsightAdded: _addNewInsight,
                                );
                              },
                              onMyLocationPressed: _handleMyLocationPressed, 
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
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface.withOpacity(0.7))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}