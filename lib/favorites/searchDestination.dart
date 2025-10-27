import 'package:flutter/material.dart';
import 'dart:async'; 
import 'favoriteRouteData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/core/utils/map_utils.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import '../routes/route_list.dart'; // <-- added import

class SearchDestinationPage extends StatefulWidget {
  final String? initialSearchText;

  const SearchDestinationPage({super.key, this.initialSearchText});

  @override
  _SearchDestinationPageState createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc";
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _predictions = const [];
  Timer? _debounce; 

  List<Map<String, dynamic>> _dbRecentLocations = []; 
  bool _isLoadingRecent = true; 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  final User? _currentUser = FirebaseAuth.instance.currentUser; 

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText ?? '';
    if (_searchController.text.isNotEmpty) {
      _debouncedSearch(_searchController.text);
    }
    _fetchRecentLocations(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchRecentLocations() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingRecent = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('recent_searches')
          .orderBy('timestamp', descending: true) 
          .limit(7) 
          .get();

      final recent = snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'] as String,
            'latitude': doc['latitude'] as double,
            'longitude': doc['longitude'] as double,
          }).toList();

      if (mounted) {
        setState(() {
          _dbRecentLocations = recent;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      print("Error fetching recent locations: $e");
      if (mounted) {
        setState(() {
          _isLoadingRecent = false;
        });
      }
    }
  }

  Future<void> _saveRecentLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    if (_currentUser == null) return;

    final locationData = {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Save the new location
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('recent_searches')
          .add(locationData);

      // No need to re-fetch if using Firestore snapshots, but since we are using get()
      // we need to re-fetch to update the state immediately after saving.
      // Keeping fetch for now as the streaming change was not fully implemented.
      await _fetchRecentLocations();
      
    } catch (e) {
      print("Error saving recent location: $e");
    }
  }

  Future<void> _debouncedSearch(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      if (mounted) setState(() => _predictions = const []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final List<dynamic> results = await _getPredictions(query);
      if (mounted) {
        setState(() => _predictions = results);
      }
    });
  }

  Future<List<dynamic>> _getPredictions(String input) async {
    if (input.isEmpty) return const [];
    try {
      const components = "country:ph";
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=$components';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['predictions'];
      } else {
        print('Search failed: ${response.statusCode}');
        return const [];
      }
    } catch (e) {
      print('Network error: $e');
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }


  void _onPredictionSelected(dynamic prediction) async {
    final Map<String, dynamic>? placeDetails = await _getPlaceDetails(prediction['place_id']);

    if (!mounted) return;

    if (placeDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load place details.')),
      );
      return;
    }

    final name = prediction['description'] as String;
    final lat = placeDetails['geometry']['location']['lat'] as double;
    final lng = placeDetails['geometry']['location']['lng'] as double;

    _saveRecentLocation(name: name, latitude: lat, longitude: lng); 


    Navigator.pop(context, {
      'place': {
        'place_id': prediction['place_id'],
        'description': prediction['description'],
        'latitude': placeDetails['geometry']['location']['lat'],
        'longitude': placeDetails['geometry']['location']['lng'],
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), 
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _debouncedSearch,
          decoration: InputDecoration(
            hintText: 'Search for a destination',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w400
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color.fromARGB(255, 56, 56, 56), // MODIFIED: Set caret color to black
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.primaryColor, 
      ),
      body: _predictions.isNotEmpty
          ? _buildPredictionList(cs)
          : _buildRecentLocations(cs),
    );
  }

  Widget _buildPredictionList(ColorScheme cs) {
    return ListView.builder(
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return ListTile(
          leading: Icon(Icons.location_on, color: cs.secondary),
          title: Text(prediction['structured_formatting']['main_text'], style: TextStyle(color: cs.onSurface)),
          subtitle: Text(prediction['structured_formatting']['secondary_text'], style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
          onTap: () => _onPredictionSelected(prediction),
        );
      },
    );
  }

  // MODIFIED: Simplified loading and ensured left-alignment for all states
  Widget _buildRecentLocations(ColorScheme cs) {
    
    // Check if the user is not logged in first.
    if (_currentUser == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Sign in to track your recent search history.",
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
      );
    }
    
    // Handle Loading/Empty states using Column for left alignment
    if (_isLoadingRecent || _dbRecentLocations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // MODIFIED: Align to the left
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Recent Locations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          // MODIFIED: Simple, non-expanded loading indicator
          if (_isLoadingRecent)
             Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8),
                child: SizedBox(
                    width: 20, 
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
             )
          else if (_dbRecentLocations.isEmpty)
             Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8),
                child: Text(
                  "Start searching to see your recent locations here!",
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                ),
              ),
        ],
      );
    }

    // Populated state remains the same, using Column for left alignment
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Recent Locations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _dbRecentLocations.length,
            itemBuilder: (context, index) {
              final recentLocation = _dbRecentLocations[index];
              return Card(
                color: cs.surface,
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  leading: Icon(Icons.history, color: cs.secondary),
                  title: Text(
                    recentLocation['name'] as String, 
                    style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
                  ),
                  onTap: () {
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