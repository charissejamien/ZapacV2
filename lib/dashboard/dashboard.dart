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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAndListenToMessages(); 
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel(); 
    _authStateSubscription?.cancel();
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
  
  // FIX: _onMapCreated now calls _handleMyLocationPressed() immediately after map is ready
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    
    // Call location logic here to ensure it overrides the initial CameraPosition
    _handleMyLocationPressed(); 
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

  Future<void> _handleMyLocationPressed() async {
    if (!mounted || !_isMapReady) return;
    _markers.clear();
    _polylines.clear();
    
    // This call moves the camera to the current location with high zoom (18.0)
    await MapUtils.getCurrentLocationAndMarker(
      {},
      _mapController,
      context,
      isMounted: () => mounted,
    );
    
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


  @override
  Widget build(BuildContext context) {
    final bottomSheetHeight = MediaQuery.of(context).size.height * (_isCommunityInsightExpanded ? 0.85 : 0.35);

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
                initialCameraPosition: CameraPosition(
                  target: _initialCameraPosition,
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

            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SearchBar(
                onPlaceSelected: _handlePlaceSelected,
                onSearchCleared: _clearSearchMarker,
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

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: 16,
              top: _isCommunityInsightExpanded ? null: MediaQuery.of(context).size.height * 0.08,
              bottom: _isCommunityInsightExpanded ? 20 : null,

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation, 
                    child: child);
                },

              child: Column(
                key: ValueKey<bool>(_isCommunityInsightExpanded),
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
            ),
            ),
        ],
        ),
      ),
    );
  }
}