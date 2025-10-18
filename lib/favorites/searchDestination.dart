import 'package:flutter/material.dart';
import 'dart:async'; 
import 'favoriteRouteData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/core/utils/map_utils.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

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

  final List<Map<String, dynamic>> _recentLocations = const [
    {'name': 'House ni Gorgeous', 'latitude': 10.3100, 'longitude': 123.9150}, 
    {'name': 'House sa Gwapa', 'latitude': 10.2900, 'longitude': 123.8900}, 
    {'name': 'Ayala Center Cebu', 'latitude': 10.3175, 'longitude': 123.9050}, 
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText ?? '';
    if (_searchController.text.isNotEmpty) {
      _debouncedSearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _debouncedSearch,
          decoration: const InputDecoration(
            hintText: 'Search for a destination...',
            border: InputBorder.none,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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

  Widget _buildRecentLocations(ColorScheme cs) {
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
            itemCount: _recentLocations.length,
            itemBuilder: (context, index) {
              final recentLocation = _recentLocations[index];
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
