import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/settings/settings_page.dart';
import 'package:zapac/settings/profile_page.dart';

// Import the new file names
import 'community_insights_page.dart';
import '../core/widgets/searchBar.dart';
import '../core/widgets/app_floating_button.dart';
import 'addInsight.dart';
import '../core/utils/map_utils.dart';
import 'dart:io' show Platform;
import 'community_insights_page.dart' show ChatMessage;
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Map State
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final LatLng _initialCameraPosition = const LatLng(10.314481680817886, 123.88813209917954);

  // UI State
  bool _isCommunityInsightExpanded = false;
  int _selectedIndex = 0;
  bool _isMapReady = false; 

  // Firestore & Data State
  List<ChatMessage> _liveChatMessages = [];
  StreamSubscription? _chatSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  
// Defined API Key as a constant for easy management
  String _getMapApiKey() {
    if (Platform.isIOS) {
      // This key MUST match the one in AppDelegate.swift
      return "AIzaSyCWHublkXuYaWfT68qUwGY3o5L9NB82JA8";
    }
    // Default to Android for all other platforms (Android/Web/Desktop)
    return "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; 
  }
  // NEW: Store the current user ID
  String? _currentUserId;
  StreamSubscription? _authStateSubscription;

  // Defined API Key as a constant for easy management
  static const String _mapApiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; // Placeholder/Example Key

  @override
  void initState() {
    super.initState();
    // Get user ID immediately (can be null if not logged in)
    _currentUserId = _auth.currentUser?.uid;
    
    // Listen for auth state changes to update the user ID dynamically
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUserId = user?.uid;
        });
      }
    });

    // CRITICAL FIX: Ensure ALL resource-dependent initial calls are delayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 1. Move the marker addition here for maximum safety
        MapUtils.addMarker(_markers, _initialCameraPosition, 'cebu_city_marker', 'Cebu City');
        
        // 2. Start the Firestore listener
        _fetchAndListenToMessages(); 
        
        // 3. Force update UI after initial resources are set
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // FIX: Cancel both stream subscriptions when the widget is disposed
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
      // FIX: Only call setState if the widget is currently mounted
      if (!mounted) return; 
      
      final List<ChatMessage> fetchedMessages = snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc);
      }).toList();

      List<ChatMessage> combinedMessages = [];
      combinedMessages.addAll(fetchedMessages);
      
      // Sort combined list by createdAt timestamp
      combinedMessages.sort((a, b) {
          final aTime = a.createdAt?.toDate().millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.toDate().millisecondsSinceEpoch ?? 0;
          // Sample messages (which have a null createdAt) will go to the end if bTime is non-null
          return bTime.compareTo(aTime);
      });
      
      setState(() {
        _liveChatMessages = combinedMessages;
      });

    }, onError: (error) {
      print("Error fetching community insights: $error");
      if (mounted) {
        // Log the error to the console for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load community feed.')),
        );
      }
    });
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
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

    await MapUtils.getCurrentLocationAndMarker(
      _markers,
      _mapController,
      context,
      isMounted: () => mounted,
    );
    if (mounted) setState(() {});
  }

  Future<void> _handlePlaceSelected(dynamic item) async {
    if (!mounted) return;
    
    await MapUtils.showRoute(
      item: item,
      apiKey: _getMapApiKey(), 
      markers: _markers,
      polylines: _polylines,
      mapController: _mapController,
      context: context,
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // 1. Google Map (Map Screen)
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

            // 2. Draggable Commenting Section (communityInsights.dart)
            CommentingSection(
              chatMessages: _liveChatMessages, 
              onExpansionChanged: _onCommunityInsightExpansionChanged,
              currentUserId: _currentUserId, // PASS THE CURRENT USER ID HERE
            ),

            // 3. Floating Search Bar (searchBar.dart)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SearchBar(onPlaceSelected: _handlePlaceSelected),
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
                  // Get the current user ID right before showing the modal
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
                    firestore: _firestore, // Pass the Firestore instance
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
