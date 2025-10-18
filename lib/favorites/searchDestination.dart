import 'package:flutter/material.dart';
import 'dart:async'; // <--- ADDED for Timer
import 'favoriteRouteData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/core/utils/map_utils.dart'; // Ensure map_utils.dart has the showRoute modifications
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class SearchDestinationPage extends StatefulWidget {
  final String? initialSearchText;

  const SearchDestinationPage({super.key, this.initialSearchText});

  @override
  _SearchDestinationPageState createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc";
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _predictions = [];
  Timer? _debounce; // <--- ADDED: Debounce timer instance

  // MODIFIED: _recentLocations now contains exact latitude and longitude
  final List<Map<String, dynamic>> _recentLocations = [
    // Using approximate coordinates in Cebu/Lapu-Lapu for demo purposes
    {'name': 'House ni Gorgeous', 'latitude': 10.3100, 'longitude': 123.9150}, // Near Fuente Osmena
    {'name': 'House sa Gwapa', 'latitude': 10.2900, 'longitude': 123.8900}, // Near Cebu City Sports Complex
    {'name': 'House ni Pretty', 'latitude': 10.3250, 'longitude': 123.9000}, // Near IT Park
    {'name': 'SM City Cebu', 'latitude': 10.3106, 'longitude': 123.9189},
    {'name': 'House ni Lim', 'latitude': 10.3050, 'longitude': 123.9300}, // Somewhere in Lapu-Lapu
    {'name': 'iAcademy Cebu', 'latitude': 10.3340, 'longitude': 123.9050},
    {'name': 'Ayala Malls Central Bloc', 'latitude': 10.3168, 'longitude': 123.9056},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchText != null) {
      _searchController.text = widget.initialSearchText!;
      // Use the new debounced function call here
      _debouncedGetPredictions(widget.initialSearchText!); 
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // <--- ADDED: Cancel timer on dispose
    _searchController.dispose();
    super.dispose();
  }
  
  // NEW METHOD: Handle debouncing network calls
  void _debouncedGetPredictions(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Wait 500ms before triggering the search
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getPredictions(input);
    });
  }

  Future<void> _getPredictions(String input) async {
    // We can now call MapUtils.getPredictions directly, assuming it's correctly exposed
    // in map_utils.dart (as it was in the combined file snippet).
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    
    // NOTE: Instead of duplicating API logic, call the helper function from MapUtils
    try {
      final results = await getPredictions(input, apiKey); // Assuming getPredictions is available (it's globally scoped in map_utils.dart)

      if (mounted) {
        setState(() => _predictions = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed. Check API Key/Network: $e')),
        );
        setState(() => _predictions = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E0EA), // Same as Dashboard
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CA89A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Search Destination',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(70),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF4A6FA5).withOpacity(0.2),
                    blurRadius: 6.8,
                    offset: const Offset(2, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                // MODIFIED: Use the debounced function
                onChanged: _debouncedGetPredictions, 
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Where to?',
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6CA89A)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          // Favorite Routes Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: favoriteRoutes.map((route) {
                return ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'route': route}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6CA89A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                  child: Text(route.routeName, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 32, color: Color(0xFF6CA89A)),
          // Predictions or Recent List
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildRecentList()
                : _buildPredictionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionList() {
    return ListView.builder(
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFF6CA89A)),
            title: Text(
              _predictions[index]['description'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {
              // This is for Google Places API predictions
              Navigator.pop(context, {'place': _predictions[index]});
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
          child: Text(
            "Recent",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentLocations.length,
            itemBuilder: (context, index) {
              final recentLocation = _recentLocations[index];
              return Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF6CA89A)),
                  title: Text(
                    recentLocation['name'] as String, // Use 'name' for display
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // MODIFIED: Pass the exact latitude and longitude for recent locations
                    Navigator.pop(context, {
                      'recent_location': {
                        'name': recentLocation['name'],
                        'latitude': recentLocation['latitude'],
                        'longitude': recentLocation['longitude'],
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
