import 'package:flutter/material.dart' hide SearchBar;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/settings/settings_page.dart';
import 'package:zapac/settings/profile_page.dart';

// Import the new file names
import 'community_insights_page.dart';
import '../core/widgets/searchBar.dart';
import '../core/widgets/app_floating_button.dart';
import 'addInsight.dart';
import '../core/utils/map_utils.dart';

// Placeholder for ChatMessage model (re-exported from communityInsights)
import 'community_insights_page.dart' show ChatMessage;

// Sample data definition (MUST match ChatMessage structure)
final List<ChatMessage> _initialSampleMessages = [
  ChatMessage(
    sender: 'Zole Laverne',
    message: '"Ig 6PM juseyo, expect traffic sa Escariomida..."',
    route: 'Escario',
    timeAgo: '2 days ago',
    imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&h=500&fit=crop',
    likes: 15,
    isMostHelpful: true,
  ),
  ChatMessage(
    sender: 'Kyline Alcantara', 
    message: '"Kuyaw kaaio sa Carbon..."', 
    route: 'Carbon', 
    timeAgo: '9 days ago', 
    imageUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=500&h=500&fit=crop', 
    likes: 22, 
    dislikes: 2
  ),
  ChatMessage(
    sender: 'Adopted Brother ni Mikha Lim', 
    message: '"Ang plete kai tag 12 pesos..."', 
    route: 'Lahug – Carbon', 
    timeAgo: 'Just Now', 
    imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&h=500&fit=crop', 
    likes: 5
  ),
];


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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndListenToMessages(); // Start listening to Firestore after the frame is rendered
    });
    
    MapUtils.addMarker(_markers, _initialCameraPosition, 'cebu_city_marker', 'Cebu City');
  }

  @override
  void dispose() {
    // FIX: Cancel the stream subscription when the widget is disposed
    _chatSubscription?.cancel(); 
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
      
      combinedMessages.addAll(_initialSampleMessages);
      
      for (var fetchedMsg in fetchedMessages) {
        if (!_initialSampleMessages.any((sampleMsg) => 
          sampleMsg.sender == fetchedMsg.sender && 
          sampleMsg.message == fetchedMsg.message)) {
          combinedMessages.add(fetchedMsg);
        }
      }
      
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
  
  // ... (rest of the file content is unchanged but included for context)

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
      apiKey: "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc",
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
      floatingActionButton: FloatingButton(
        isCommunityInsightExpanded: _isCommunityInsightExpanded,
        onAddInsightPressed: () {
          if (!mounted) return;
          showAddInsightModal(
            context: context,
            firestore: _firestore, // Pass the Firestore instance
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
              chatMessages: _liveChatMessages, 
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
