import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/favorites/favorite_route.dart';
// import 'favoriteRouteData.dart'; // REMOVED: Local data store
import 'dart:async'; 
// NEW IMPORTS for Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/favorites/favorite_routes_service.dart';

Future<List<dynamic>> Function(String, String) getPredictions = (String input, String apiKey) async {
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
        // use strictbounds to prefer results inside the radius (some keys accept 'strictbounds' without value)
        'strictbounds': 'true',
        'types': 'geocode', 
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
  };



// Helper method to check if coordinates are within Cebu bounds
bool _isWithinCebuBounds(double lat, double lng) {
  // Approximate Cebu City bounds
  // Cebu City roughly: lat 10.25-10.40, lng 123.75-124.00
  // Expanded for Cebu Province: lat 9.50-11.50, lng 123.00-124.50
  const double minLat = 9.50;
  const double maxLat = 11.50;
  const double minLng = 123.00;
  const double maxLng = 124.50;
  
  return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}

// New: Helper method to parse the distance and duration from the route data
// FIX: Added safer parsing with ?? 0.0 to prevent nulls from distance/duration text
Map<String, double> _parseRouteMetrics(String distanceText, String durationText) {
  // Distance parsing (e.g., "5.2 km")
  final String distanceString = distanceText.replaceAll(RegExp(r' km|\,'), '').trim();
  final double distanceKm = double.tryParse(distanceString) ?? 0.0; 
  
  // Duration parsing (e.g., "7 mins" or "1 hour 2 mins")
  double durationMin = 0.0;
  final String durationLower = durationText.toLowerCase();
  
  final RegExp timeRegex = RegExp(r'(\d+)\s+(hour|hr|min|mins)');
  final matches = timeRegex.allMatches(durationLower);

  for (var match in matches) {
    final value = double.tryParse(match.group(1)!) ?? 0.0;
    final unit = match.group(2)!;
    if (unit.startsWith('h')) {
      durationMin += value * 60;
    } else if (unit.startsWith('m')) {
      durationMin += value;
    }
  }
  
  // Fallback for simple case like "30 min"
  if (matches.isEmpty && durationLower.contains('min')) {
    final parts = durationLower.split(' ');
    durationMin = double.tryParse(parts.first) ?? 0.0;
  }

  return {
    'distanceKm': distanceKm,
    'durationMin': durationMin,
  };
}

// New: Method to calculate all estimated fares based on the provided formulas
Map<String, String> _calculateAllEstimatedFares(String distanceText, String durationText) {
  final metrics = _parseRouteMetrics(distanceText, durationText);
  final double distanceKm = metrics['distanceKm']!;
  final double durationMin = metrics['durationMin']!;
  
  final Map<String, double> fares = {};

  // 1. Moto Taxi (Previous single fare)
  double motoTaxiFare;
  if (distanceKm <= 4.0) {
    motoTaxiFare = 15.0; 
  } else {
    motoTaxiFare = 15.0 + ((distanceKm - 4.0) * 2.5);
  }
  fares['Moto Taxi'] = motoTaxiFare;

  // 2. Grab (4-seater)
  const double grabBase = 45.0;
  const double grabDistRate = 15.0;
  const double grabTimeRate = 2.0;
  const double grabSurge = 1.5;
  double grabFare = (grabBase + (distanceKm * grabDistRate + durationMin * grabTimeRate)) * grabSurge;
  fares['Grab (4-seater)'] = grabFare;
  
  // 3. Taxi
  const double taxiFlagDown = 50.0;
  const double taxiDistRate = 13.50;
  const double taxiTimeRate = 2.0;
  double taxiFare = taxiFlagDown + (distanceKm * taxiDistRate) + (durationMin * taxiTimeRate);
  fares['Taxi'] = taxiFare;
  
  // 4. Modern and Electric PUJ (Regular)
  const double modernPujBaseKm = 4.0;
  const double modernPujBaseFare = 15.0;
  const double modernPujSucceedingRate = 2.20;
  double modernPujFare = modernPujBaseFare;
  if (distanceKm > modernPujBaseKm) {
    modernPujFare += (distanceKm - modernPujBaseKm) * modernPujSucceedingRate;
  }
  fares['Modern/E-PUJ'] = modernPujFare;
  
  // 5. Traditional PUJ (Regular)
  const double tradPujBaseKm = 4.0;
  const double tradPujBaseFare = 13.0;
  const double tradPujSucceedingRate = 1.80;
  double tradPujFare = tradPujBaseFare;
  if (distanceKm > tradPujBaseKm) {
    tradPujFare += (distanceKm - tradPujBaseKm) * tradPujSucceedingRate;
  }
  fares['Traditional PUJ'] = tradPujFare;

  // 6. Bus Airconditioned (Regular)
  const double acBusBaseKm = 5.0;
  const double acBusBaseFare = 15.0;
  const double acBusSucceedingRate = 2.65;
  double acBusFare = acBusBaseFare;
  if (distanceKm > acBusBaseKm) {
    acBusFare += (distanceKm - acBusBaseKm) * acBusSucceedingRate;
  }
  fares['Bus (Aircon)'] = acBusFare;
  
  // 7. Bus Non-Airconditioned (Regular)
  const double nonAcBusBaseKm = 5.0;
  const double nonAcBusBaseFare = 13.0;
  const double nonAcBusSucceedingRate = 2.25;
  double nonAcBusFare = nonAcBusBaseFare;
  if (distanceKm > nonAcBusBaseKm) {
    nonAcBusFare += (distanceKm - nonAcBusBaseKm) * nonAcBusSucceedingRate;
  }
  fares['Bus (Non-Aircon)'] = nonAcBusFare;

  // Format all calculated fares to currency string
  return fares.map((key, value) => MapEntry(key, '₱${value.toStringAsFixed(2)}'));
}


class AddNewRoutePage extends StatefulWidget {
  const AddNewRoutePage({super.key});

  @override
  _AddNewRoutePageState createState() => _AddNewRoutePageState();
}

class _AddNewRoutePageState extends State<AddNewRoutePage> {
  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#e0e0e0"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3a3a3a"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#273a2c"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d3d3d"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"transit.station.bus","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1b25"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#a0a0a0"}]}]';

  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; 

  // NEW: Initialize the service
  final FavoriteRoutesService _routesService = FavoriteRoutesService();

  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  Map<String, dynamic>? _startLocation;
  Map<String, dynamic>? _destinationLocation;
  Map<String, dynamic>? _directionsResponse;

  List<dynamic> _startPredictions = const [];
  List<dynamic> _destinationPredictions = const [];
  
  Timer? _debounce; 

  Set<Polyline> _polylines = const {};
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _startFocusNode.addListener(_onFocusChange);
    _destinationFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Clear predictions when fields lose focus
    if (!_startFocusNode.hasFocus && !_destinationFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _startPredictions = const [];
          _destinationPredictions = const [];
        });
      }
    }
  }

  @override
  void dispose() {
    _startFocusNode.removeListener(_onFocusChange);
    _destinationFocusNode.removeListener(_onFocusChange);
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    _routeNameController.dispose();
    _startLocationController.dispose();
    _destinationController.dispose();
    _mapController?.dispose();
    _debounce?.cancel(); 
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _mapController?.setMapStyle(isDark ? _darkMapStyle : null);
  }

  void _debouncedGetPredictions(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final bool isStart = _startFocusNode.hasFocus;
    final bool isDestination = _destinationFocusNode.hasFocus;
    
    if (input.isEmpty) {
        if (mounted) {
          setState(() {
            if (isStart) {
              _startPredictions = const [];
            } else if (isDestination) {
              _destinationPredictions = const [];
            }
          });
        }
        return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
        final bool stillStart = _startFocusNode.hasFocus;
        final bool stillDest = _destinationFocusNode.hasFocus;
        
        // Verify focus hasn't changed during debounce
        if (input.isEmpty || (!stillStart && !stillDest)) return;
        if (isStart != stillStart || isDestination != stillDest) return;

        try {
            final List<dynamic> results = await getPredictions(input, apiKey);
            // Filter to only Cebu results - check description and verify coordinates
            final List<dynamic> filteredResults = results.where((prediction) {
              final String description = (prediction['description'] ?? '').toString().toLowerCase();
              // Check if description contains Cebu-related terms
              final bool hasCebuInDescription = description.contains('cebu');
              return hasCebuInDescription;
            }).toList();
            
            if (mounted) {
              setState(() {
                if (isStart) {
                  _startPredictions = filteredResults;
                } else if (isDestination) {
                  _destinationPredictions = filteredResults;
                }
              });
            }
        } catch (e) {
            if (mounted) {
              setState(() {
                if (isStart) {
                  _startPredictions = const [];
                } else if (isDestination) {
                  _destinationPredictions = const [];
                }
              });
            }
        }
    });
  }
  
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
           return data['result'];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  
  void _onPredictionSelected(Map<String, dynamic> prediction) async {
    final bool isStart = _startFocusNode.hasFocus;
    final bool isDestination = _destinationFocusNode.hasFocus;

    setState(() {
      _startPredictions = const [];
      _destinationPredictions = const [];
    });
    FocusScope.of(context).unfocus();
    
    final Map<String, dynamic>? placeDetails = await _getPlaceDetails(prediction['place_id']);

    if (!mounted) return;

    if (placeDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load full place details. Try a different search.')),
      );
      return;
    }

    final double lat = placeDetails['geometry']['location']['lat'] as double;
    final double lng = placeDetails['geometry']['location']['lng'] as double;
    
    // Verify the selected place is actually in Cebu
    if (!_isWithinCebuBounds(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This location is not in Cebu. Please select a location within Cebu.')),
      );
      return;
    }

    final Map<String, dynamic> locationData = {
      'place_id': prediction['place_id'],
      'description': prediction['description'],
      'latitude': lat,
      'longitude': lng,
    };
    
    if (isStart) {
      _startLocationController.text = prediction['description'];
      setState(() => _startLocation = locationData);
    } else if (isDestination) {
      _destinationController.text = prediction['description'];
      setState(() => _destinationLocation = locationData);
    }

    if (_startLocation != null && _destinationLocation != null) {
      _getRoute();
    }
  }


  Future<void> _getRoute() async {
    if (!mounted) return;
    
    if (_startLocation == null || _destinationLocation == null ||
        _startLocation!['latitude'] == null || _destinationLocation!['latitude'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing complete geographic data for routing.')),
      );
      return;
    }
    
    final String startLatLng = '${_startLocation!['latitude']},${_startLocation!['longitude']}';
    final String endLatLng = '${_destinationLocation!['latitude']},${_destinationLocation!['longitude']}';
    
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$startLatLng&destination=$endLatLng&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['routes'].isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No route found between these locations.')),
           );
        }
        return;
      }
      
      final routeData = decoded['routes'][0];
      final leg = routeData['legs'][0];
      final start = LatLng(leg['start_location']['lat'], leg['start_location']['lng']);
      final end = LatLng(leg['end_location']['lat'], leg['end_location']['lng']);
      
      _markers.clear();
      _markers.add(Marker(markerId: const MarkerId('start'), position: start, infoWindow: InfoWindow(title: 'Start: ${leg['start_address'].split(',').first}')));
      _markers.add(Marker(markerId: const MarkerId('end'), position: end, infoWindow: InfoWindow(title: 'End: ${leg['end_address'].split(',').first}')));

      final PolylinePoints polylinePoints = PolylinePoints();
      final List<PointLatLng> polylineCoordinates = polylinePoints.decodePolyline(routeData['overview_polyline']['points']);
      final List<LatLng> latLngList = polylineCoordinates.map((point) => LatLng(point.latitude, point.longitude)).toList();

      if (mounted) {
        setState(() {
          _directionsResponse = decoded;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Theme.of(context).colorScheme.primary,
              points: latLngList,
              width: 5,
            )
          };
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(_createBounds(latLngList), 100.0));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch route. Check API key and service enablement.')),
        );
      }
    }
  }

  // MODIFIED: _saveRoute now uses FavoriteRoutesService to save to Firestore
  void _saveRoute() async {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save a favorite route.')),
      );
      return;
    }

    if (_routeNameController.text.isEmpty || _directionsResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a route name and show the route first.')),
      );
      return;
    }

    final routeData = _directionsResponse!['routes'][0];
    final leg = routeData['legs'][0];
    
    final startLocation = leg['start_location'];
    final endLocation = leg['end_location'];

    // Calculate all fares once and store the map
    final Map<String, String> allFares = _calculateAllEstimatedFares(
      leg['distance']['text'], 
      leg['duration']['text']
    );

    final List<LatLng> polylinePoints = _polylines.isNotEmpty ? _polylines.first.points : const [];

    final newRoute = FavoriteRoute(
      routeName: _routeNameController.text,
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      polylinePoints: polylinePoints, 
      bounds: _createBounds(polylinePoints),
      latitude: endLocation['lat'],
      longitude: endLocation['lng'],
      startLatitude: startLocation['lat'],
      startLongitude: startLocation['lng'],
      polylineEncoded: routeData['overview_polyline']['points'],
      estimatedFares: allFares, 
    );
    
    try {
      // Use the service to save the route to Firestore
      await _routesService.saveFavoriteRoute(newRoute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Display any error from the Firebase service
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save route: ${e.toString()}')),
        );
      }
    }
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(10.3157, 123.8854),
        northeast: LatLng(10.3157, 123.8854),
      );
    }
    final double southwestLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final double southwestLon = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final double northeastLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final double northeastLon = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLon),
      northeast: LatLng(northeastLat, northeastLon),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hintText) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Color(0xFFF3EEE6),
      hintText: hintText,
      hintStyle: TextStyle(color: cs.onSurface.withAlpha(153)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark ? cs.onBackground : cs.primary;
    
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: headerTextColor,
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: cs.background,
        elevation: 0,
        title: Text(
          "Add New Route",
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: headerTextColor
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _startPredictions = const [];
            _destinationPredictions = const [];
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              TextField(
                controller: _routeNameController,
                decoration: _inputDecoration(context, 'Route Name (e.g., Home to Work)'),
                style: TextStyle(color: cs.onSurface),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _startLocationController,
                focusNode: _startFocusNode,
                onChanged: _debouncedGetPredictions, 
                decoration: _inputDecoration(context, 'Starting Location'),
                style: TextStyle(color: cs.onSurface),
              ),
              // Show start predictions directly below start field
              if (_startPredictions.isNotEmpty && _startFocusNode.hasFocus)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _startPredictions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          _startPredictions[index]['description'],
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                        onTap: () => _onPredictionSelected(_startPredictions[index]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 15),
              TextField(
                controller: _destinationController,
                focusNode: _destinationFocusNode,
                onChanged: _debouncedGetPredictions, 
                decoration: _inputDecoration(context, 'Destination'),
                style: TextStyle(color: cs.onSurface)
              ),
              // Show destination predictions directly below destination field
              if (_destinationPredictions.isNotEmpty && _destinationFocusNode.hasFocus)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _destinationPredictions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          _destinationPredictions[index]['description'],
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                        onTap: () => _onPredictionSelected(_destinationPredictions[index]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 15),
                  SizedBox(
                    height: 400,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(target: LatLng(10.3157, 123.8854), zoom: 12),
                        polylines: _polylines,
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _getRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.surface,
                            foregroundColor: isDark ? cs.onSurface : cs.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: cs.primary),
                            ),
                          ),
                          child: const Text("Show Route"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Save Route"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
        ),
      ),
    );
  }
}