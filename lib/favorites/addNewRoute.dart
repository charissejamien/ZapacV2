import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/favorites/favorite_route.dart';
import 'favoriteRouteData.dart';
import 'dart:async'; 

final Future<List<dynamic>> Function(String, String) getPredictions = (String input, String apiKey) async {
  if (input.isEmpty) return const [];
  try {
    const components = "country:ph";
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=$components';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    } else {
      print('Failed to load predictions: ${response.statusCode}');
      return const [];
    }
  } catch (e) {
    print('Error getting predictions: $e');
    return const [];
  }
};


class AddNewRoutePage extends StatefulWidget {
  const AddNewRoutePage({super.key});

  @override
  _AddNewRoutePageState createState() => _AddNewRoutePageState();
}

class _AddNewRoutePageState extends State<AddNewRoutePage> {
  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#e0e0e0"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3a3a3a"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#273a2c"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d3d3d"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"transit.station.bus","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1b25"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#a0a0a0"}]}]';

  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc"; 

  final GlobalKey _startFieldKey = GlobalKey();
  final GlobalKey _destinationFieldKey = GlobalKey();

  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  Map<String, dynamic>? _startLocation;
  Map<String, dynamic>? _destinationLocation;
  Map<String, dynamic>? _directionsResponse;

  List<dynamic> _predictions = const [];
  Rect? _activeFieldRect;
  
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
    if (!_startFocusNode.hasFocus && !_destinationFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _predictions = const [];
          _activeFieldRect = null;
        });
      }
    }
    
    final GlobalKey? activeKey = _startFocusNode.hasFocus 
        ? _startFieldKey 
        : _destinationFocusNode.hasFocus ? _destinationFieldKey : null;

    if (activeKey != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        final renderBox = activeKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && mounted) {
          final offset = renderBox.localToGlobal(Offset.zero);
          setState(() {
            _activeFieldRect = Rect.fromLTWH(
              offset.dx,
              offset.dy,
              renderBox.size.width,
              renderBox.size.height,
            );
          });
        }
      });
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
    
    if (input.isEmpty) {
        if (mounted) setState(() => _predictions = const []);
        return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
        final isStart = _startFocusNode.hasFocus;
        final isDestination = _destinationFocusNode.hasFocus;
        
        if (input.isEmpty || (!isStart && !isDestination)) return;

        try {
            final List<dynamic> results = await getPredictions(input, apiKey); 
            if (mounted) {
              setState(() {
                _predictions = results;
              });
            }
        } catch (e) {
            if (mounted) setState(() => _predictions = const []);
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
      _predictions = const [];
      _activeFieldRect = null;
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

    final Map<String, dynamic> locationData = {
      'place_id': prediction['place_id'],
      'description': prediction['description'],
      'latitude': placeDetails['geometry']['location']['lat'],
      'longitude': placeDetails['geometry']['location']['lng'],
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

  String _calculateEstimatedFare(String distanceText) {
    final double distanceKm;
    try {
      distanceKm = double.parse(distanceText.replaceAll(RegExp(r' km|\,'), ''));
    } catch (e) {
      return 'Fare N/A';
    }

    final double fare;
    if (distanceKm <= 4.0) {
      fare = 15.0; 
    } else {
      fare = 15.0 + ((distanceKm - 4.0) * 2.5);
    }

    return '₱${fare.toStringAsFixed(2)}';
  }

  void _saveRoute() {
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

    final String calculatedFare = _calculateEstimatedFare(leg['distance']['text']);

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
      estimatedFare: calculatedFare,
    );

    if (favoriteRoutes.any((r) => r.routeName == newRoute.routeName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route name already exists.')),
      );
      return;
    }

    favoriteRoutes.add(newRoute);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route saved successfully!')),
    );

    Navigator.pop(context);
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
      fillColor: cs.surface,
      hintText: hintText,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
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
            _predictions = const [];
            _activeFieldRect = null;
          });
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  TextField(
                    controller: _routeNameController,
                    decoration: _inputDecoration(context, 'Route Name (e.g., Downtown Loop)'),
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    key: _startFieldKey,
                    child: TextField(
                      controller: _startLocationController,
                      focusNode: _startFocusNode,
                      onChanged: _debouncedGetPredictions, 
                      decoration: _inputDecoration(context, 'Starting Location'),
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    key: _destinationFieldKey,
                    child: TextField(
                      controller: _destinationController,
                      focusNode: _destinationFocusNode,
                      onChanged: _debouncedGetPredictions, 
                      decoration: _inputDecoration(context, 'Destination'),
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
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
            if (_predictions.isNotEmpty && _activeFieldRect != null)
              Positioned(
                top: _activeFieldRect!.bottom + 5, 
                left: 20,
                right: 20, 
                child: Material(
                  color: theme.cardColor,
                  elevation: 6.0,
                  borderRadius: BorderRadius.circular(10),
                  child: LimitedBox(
                    maxHeight: 250,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            _predictions[index]['description'],
                            style: TextStyle(color: cs.onSurface, fontSize: 14),
                          ),
                          onTap: () => _onPredictionSelected(_predictions[index]),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
