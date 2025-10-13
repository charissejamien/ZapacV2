import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:zapac/core/widgets/bottomNavBar.dart'; // Assuming this path
import 'package:zapac/features/account/presentation/pages/settings_page.dart'; // Assuming this path
import 'package:zapac/features/account/presentation/pages/profile_page.dart'; // Assuming this path

// Import the new file names
import 'community_insights_page.dart';
import '../../../../core/widgets/searchBar.dart';
import '../../../../core/widgets/app_floating_button.dart';
import 'addInsight.dart';
import '../../../../core/utils/map_utils.dart';

// Placeholder for ChatMessage model (re-exported from communityInsights)
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
  int _selectedIndex = 0; // Index for BottomNavBar (Dashboard)
  bool _isMapReady = false; 

  // Chat Data (Dashboard owns the state)
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      sender: 'Zole Laverne',
      message: '"Ig 6PM juseyo, expect traffic sa Escariomida..."',
      route: 'Escario',
      timeAgo: '2 days ago',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&h=500&fit=crop',
      likes: 15,
      isMostHelpful: true,
    ),
    // ... other initial messages (abbreviated for brevity)
    ChatMessage(sender: 'Kyline Alcantara', message: '"Kuyaw kaaio sa Carbon..."', route: 'Carbon', timeAgo: '9 days ago', imageUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=500&h=500&fit=crop', likes: 22, dislikes: 2),
    ChatMessage(sender: 'Adopted Brother ni Mikha Lim', message: '"Ang plete kai tag 12 pesos..."', route: 'Lahug – Carbon', timeAgo: 'Just Now', imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&h=500&fit=crop', likes: 5),
  ];

  @override
  void initState() {
    super.initState();
    // Add initial marker for context (Cebu City)
    MapUtils.addMarker(_markers, _initialCameraPosition, 'cebu_city_marker', 'Cebu City');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;

    // Load current location upon map creation
    _handleMyLocationPressed(); 
  }

  // Handle Bottom Navigation Bar taps
  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    // Example Navigation logic (needs real destination imports)
    if (index == 3) {
      // Assuming index 3 is Settings
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); 
    } else if (index == 2) {
      // Assuming index 2 is Profile
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); 
    }
    // Index 0 is Dashboard (current page)
    // Index 1 (Favorites) needs implementation
  }

  void _onCommunityInsightExpansionChanged(bool isExpanded) {
    if (!mounted) return;
    setState(() {
      _isCommunityInsightExpanded = isExpanded;
    });
  }

  // Callback for when a new insight is added from the modal
  void _addNewInsight(ChatMessage newInsight) {
    if (!mounted) return;
    setState(() {
      _chatMessages.insert(0, newInsight);
    });
  }

  // Handle My Location button press (uses helper from mapUtils.dart)
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

  // Handle place selection from search bar
  Future<void> _handlePlaceSelected(dynamic item) async {
    if (!mounted) return;
    
    // NOTE: This requires a valid Google Maps API key defined in mapUtils.dart
    await MapUtils.showRoute(
      item: item,
      apiKey: "YOUR_GOOGLE_MAPS_API_KEY", // Placeholder for actual key
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
      // The FloatingActionButton is now positioned above the DraggableSheet area
      floatingActionButton: FloatingButton(
        isCommunityInsightExpanded: _isCommunityInsightExpanded,
        onAddInsightPressed: () {
          if (!mounted) return;
          // Show the separate modal widget
          showAddInsightModal(
            context: context,
            onInsightAdded: _addNewInsight,
          );
        },
        onMyLocationPressed: _handleMyLocationPressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
              chatMessages: _chatMessages,
              onExpansionChanged: _onCommunityInsightExpansionChanged,
            ),

            // 3. Floating Search Bar (searchBar.dart)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SearchBar(onPlaceSelected: _handlePlaceSelected),
            ),
          ],
        ),
      ),
    );
  }
}
