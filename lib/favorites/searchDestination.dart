import 'package:flutter/material.dart';
import 'dart:async'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import '../routes/route_list.dart'; 
import 'favoriteRouteData.dart'; 

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
          // FIX: Access _currentUser.uid is safe here due to the null check above
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
      // FIX: Replaced print() with comment
      // Logger.error("Error fetching recent locations: $e");
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
          // FIX: Access _currentUser.uid is safe here due to the null check above
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('recent_searches')
          .add(locationData);

      // Keeping fetch to update the state immediately after saving.
      await _fetchRecentLocations();
      
    } catch (e) {
      // FIX: Replaced print() with comment
      // Logger.error("Error saving recent location: $e");
    }
  }

  Future<void> _debouncedSearch(String query) async {
    // FIX: Using null-aware check
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

    const String cebuLatLng = '10.315700,123.885437';
    const String radiusMeters = '30000'; // 30 km

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        // Restrict to Philippines and bias to Cebu City area
        'components': 'country:ph',
        'location': cebuLatLng,
        'radius': radiusMeters,
        // use strictbounds to prefer results inside the radius
        'strictbounds': 'true',
        'types': 'geocode', // limit to address/results
        'language': 'en',
      },
    );

    
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];

      final Map<String, dynamic> data = json.decode(resp.body);
      final status = (data['status'] ?? '').toString();

      if (status != 'OK') {
        // ZERO_RESULTS or OVER_QUERY_LIMIT etc.
        return const [];
      }

      return (data['predictions'] as List<dynamic>?) ?? const [];
    } catch (e) {
      // network / timeout / parse error -> return empty list
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
      // Logger.error("Error fetching place details: $e");
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

    // FIX: Guard usage against async gap
    if (mounted) {
      _saveRecentLocation(name: name, latitude: lat, longitude: lng); 
    }

    final place = {
      'place_id': prediction['place_id'],
      'description': prediction['description'],
      'latitude': placeDetails['geometry']['location']['lat'],
      'longitude': placeDetails['geometry']['location']['lng'],
    };

    // push RouteListPage and pass the selected destination
    if (!mounted) return;
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => RouteListPage(
      origin: null,
      destination: place,
    ),
  ),
);

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
              // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
              color: Colors.white.withAlpha(179),
              fontWeight: FontWeight.w400
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color.fromARGB(255, 56, 56, 56), 
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.primaryColor, 
      ),
      
      
      // When predictions exist show them, otherwise show favorites first then recents
      body: _predictions.isNotEmpty
          ? _buildPredictionList(cs)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favorites (fixed height horizontal list)
                _buildFavoritesSection(cs),
                const Divider(height: 1),
                // Recent locations fill remaining space
                Expanded(child: _buildRecentLocations(cs)),
              ],
            ),
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
          // FIX: Replaced .withOpacity(0.6) with .withAlpha(153)
          subtitle: Text(prediction['structured_formatting']['secondary_text'], style: TextStyle(color: cs.onSurface.withAlpha(153))),
          onTap: () => _onPredictionSelected(prediction),
        );
      },
    );
  }

  // New: Favorites section shown above recent locations
  Widget _buildFavoritesSection(ColorScheme cs) {
    if (favoriteRoutes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "No favorite routes saved.",
          // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
          style: TextStyle(color: cs.onSurface.withAlpha(179)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: favoriteRoutes.length,
          itemBuilder: (context, index) {
            final route = favoriteRoutes[index];
            return GestureDetector(
              onTap: () {
                final place = {
                  'place_id': null,
                  'description': route.endAddress,
                  'latitude': route.latitude,
                  'longitude': route.longitude,
                };
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteListPage(
                      origin: null,
                      destination: place,
                    ),
                  ),
                );

              },
              child: Card(
                margin: const EdgeInsets.only(right: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: cs.surface,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.routeName, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 6),
                      // FIX: Replaced .withOpacity(0.8) with .withAlpha(204)
                      Text('From: ${route.startAddress.split(',').first}', style: TextStyle(color: cs.onSurface.withAlpha(204), fontSize: 12)),
                      // FIX: Replaced .withOpacity(0.8) with .withAlpha(204)
                      Text('To: ${route.endAddress.split(',').first}', style: TextStyle(color: cs.onSurface.withAlpha(204), fontSize: 12)),
                      const Spacer(),
                      // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
                      Text('${route.distance} • ${route.duration}', style: TextStyle(color: cs.onSurface.withAlpha(179), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Modified: _buildRecentLocations now returns only the recent list widget (no Expanded internally)
  Widget _buildRecentLocations(ColorScheme cs) {
    
    // Check if the user is not logged in first.
    if (_currentUser == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Sign in to track your recent search history.",
          // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
          style: TextStyle(color: cs.onSurface.withAlpha(179)),
        ),
      );
    }
    
    // Handle Loading/Empty states using Column for left alignment
    if (_isLoadingRecent || _dbRecentLocations.isEmpty) {
      return SingleChildScrollView(
        child: Column(
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
            if (_isLoadingRecent)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: SizedBox(
                      width: 20, 
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
                )
            else
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    "Start searching to see your recent locations here!",
                    // FIX: Replaced .withOpacity(0.7) with .withAlpha(179)
                    style: TextStyle(color: cs.onSurface.withAlpha(179)),
                  ),
                ),
          ],
        ),
      );
    }

    // Populated state: show a vertical list of recent locations
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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
              final place = {
                'place_id': null,
                'description': recentLocation['name'],
                'latitude': recentLocation['latitude'],
                'longitude': recentLocation['longitude'],
              };
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteListPage(
                    origin: null,
                    destination: place,
                  ),
                ),
              );

            },
          ),
        );
      },
    );
  }
}