import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapac/favorites/favorite_route.dart';
import 'favoriteRouteData.dart';
import 'dart:math' show max; // Import max for calculations, ceil for rounding if needed later

class AddNewRoutePage extends StatefulWidget {
  const AddNewRoutePage({super.key});

  @override
  _AddNewRoutePageState createState() => _AddNewRoutePageState();
}

class _AddNewRoutePageState extends State<AddNewRoutePage> {
  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#e0e0e0"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3a3a3a"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#273a2c"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1f1f1f"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d3d3d"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1b25"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#a0a0a0"}]}]';

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

  List<dynamic> _predictions = [];
  Rect? _activeFieldRect;

  Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _startFocusNode.addListener(_onFocusChange);
    _destinationFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    GlobalKey? activeKey;
    if (_startFocusNode.hasFocus) {
      activeKey = _startFieldKey;
    } else if (_destinationFocusNode.hasFocus) {
      activeKey = _destinationFieldKey;
    }

    if (activeKey != null) {
      final renderBox = activeKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
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
    }
  }

  @override
  void dispose() {
    _startFocusNode.removeListener(_onFocusChange);
    _destinationFocusNode.removeListener(_onFocusChange);
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _mapController?.setMapStyle(isDark ? _darkMapStyle : null);
  }

  Future<void> _getPredictions(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    const location = "10.3157,123.8854";
    const radius = "30000";
    const strictBounds = "true";
    const components = "country:ph";

    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&location=$location&radius=$radius&strictbounds=$strictBounds&components=$components';

    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 && mounted) {
      setState(() {
        _predictions = json.decode(response.body)['predictions'];
      });
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  Future<void> _getRoute() async {
    if (_startLocation == null || _destinationLocation == null) return;
    final startPlaceId = _startLocation!['place_id'];
    final destinationPlaceId = _destinationLocation!['place_id'];
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=place_id:$startPlaceId&destination=place_id:$destinationPlaceId&key=$apiKey';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var decoded = json.decode(response.body);
      final routeData = decoded['routes'][0];
      
      _markers.clear();
      final leg = routeData['legs'][0];
      final startLatLng = leg['start_location'];
      final endLatLng = leg['end_location'];
      
      _markers.add(Marker(markerId: const MarkerId('start'), position: LatLng(startLatLng['lat'], startLatLng['lng'])));
      _markers.add(Marker(markerId: const MarkerId('end'), position: LatLng(endLatLng['lat'], endLatLng['lng'])));

      List<PointLatLng> polylineCoordinates = PolylinePoints().decodePolyline(routeData['overview_polyline']['points']);
      List<LatLng> latLngList = polylineCoordinates.map((point) => LatLng(point.latitude, point.longitude)).toList();

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
  }

  String _calculateEstimatedFare(String distanceText) {
    double distanceKm;
    try {
      distanceKm = double.parse(distanceText.replaceAll(' km', '').replaceAll(',', ''));
    } catch (e) {
      print('Error parsing distance: $e');
      return 'Fare N/A';
    }

    double fare;
    if (distanceKm <= 1.0) {
      fare = distanceKm * 30;
    } else {
      fare = 23.20 + (distanceKm * 9.12);
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

    final newRoute = FavoriteRoute(
      routeName: _routeNameController.text,
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      polylinePoints: _polylines.first.points,
      bounds: _createBounds(_polylines.first.points),
      latitude: endLocation['lat'],
      longitude: endLocation['lng'],
      startLatitude: startLocation['lat'],
      startLongitude: startLocation['lng'],
      polylineEncoded: routeData['overview_polyline']['points'],
      estimatedFare: calculatedFare,
    );

    favoriteRoutes.add(newRoute);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route saved successfully!')),
    );

    Navigator.pop(context);
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final southwestLon = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final northeastLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final northeastLon = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _predictions = [];
            _activeFieldRect = null;
          });
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Add New Route",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headerTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _routeNameController,
                    decoration: _inputDecoration(context, 'Route Name'),
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    key: _startFieldKey,
                    child: TextField(
                      controller: _startLocationController,
                      focusNode: _startFocusNode,
                      onChanged: _getPredictions,
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
                      onChanged: _getPredictions,
                      decoration: _inputDecoration(context, 'Destination'),
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(target: LatLng(10.3157, 123.8854), zoom: 12),
                        polylines: _polylines,
                        markers: _markers,
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
                top: _activeFieldRect!.bottom,
                left: _activeFieldRect!.left,
                width: _activeFieldRect!.width,
                child: Material(
                  color: theme.cardColor,
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(10),
                  child: LimitedBox(
                    maxHeight: 200,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _predictions[index]['description'],
                            style: TextStyle(color: cs.onSurface),
                          ),
                          onTap: () {
                            if (_startFocusNode.hasFocus) {
                              _startLocationController.text = _predictions[index]['description'];
                              _startLocation = _predictions[index];
                            } else if (_destinationFocusNode.hasFocus) {
                              _destinationController.text = _predictions[index]['description'];
                              _destinationLocation = _predictions[index];
                            }
                            setState(() {
                              _predictions = [];
                              _activeFieldRect = null;
                            });
                            FocusScope.of(context).unfocus();
                          },
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