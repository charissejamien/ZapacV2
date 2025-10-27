import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class MapUtils {
  // -------------------------
  // Core Marker/Map Utils
  // -------------------------

  static void addMarker(
    Set<Marker> markers,
    LatLng position,
    String markerId,
    String title, {
    BitmapDescriptor? icon,
  }) {
    markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: icon ?? BitmapDescriptor.defaultMarker,
      ),
    );
  }

  static void clearRoute(Set<Polyline> polylines, Set<Marker> markers) {
    polylines.clear();
    markers.removeWhere((marker) => marker.markerId.value == 'destination_marker');
    markers.removeWhere((marker) => marker.markerId.value == 'current_location_marker');
    markers.removeWhere((marker) => marker.markerId.value == 'start');
    markers.removeWhere((marker) => marker.markerId.value == 'end');
    print('Cleared all relevant markers and polylines.');
  }

  // -------------------------
  // Location & Routing
  // -------------------------

  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return null;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
      }
      return null;
    }
  }

  static Future<void> getCurrentLocationAndMarker(
    Set<Marker> markers,
    GoogleMapController mapController,
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    if (!isMounted()) return;

    LatLng? currentLatLng = await getCurrentLocation(context);
    
    if (currentLatLng != null && isMounted()) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 18.0)); 
    }
  }

  static Future<Map<String, dynamic>?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
  }) async {
    final originStr = "${origin.latitude},${origin.longitude}";
    final destinationStr = "${destination.latitude},${destination.longitude}";
    
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destinationStr&key=$apiKey&mode=driving'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          
          return {
            'distance': leg['distance']['text'] as String,
            'duration': leg['duration']['text'] as String,
          };
        }
      }
    } catch (e) {
      print("Error fetching route details: $e");
    }
    return null;
  }
  
  // RE-ADDED: The getPredictions function, now correctly inside MapUtils
  static Future<List<dynamic>> getPredictions(String input, String apiKey) async {
    if (input.isEmpty) return [];

    try {
      const components = "country:ph";
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=$components';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['predictions'];
      } else {
        print('Failed to load predictions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting predictions: $e');
      return [];
    }
  }


  // Existing showRoute function 
  static Future<Map<String, dynamic>> showRoute({
    required dynamic item,
    required String apiKey,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
    required GoogleMapController mapController,
    required BuildContext context,
  }) async {
    if (!context.mounted) return {};

    LatLng? destinationLatLng;
    String destinationName = '';

    try {
      if (item is Map && item.containsKey('place')) {
        final placeId = item['place']['place_id'];
        destinationName = item['place']['description'];

        final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
        final response = await http.get(Uri.parse(url));
        if (!context.mounted || response.statusCode != 200) return {};
        
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          destinationLatLng = LatLng(location['lat'], location['lng']);
        } else {
          return {};
        }
      } else {
        return {};
      }
    } catch (_) {
      return {};
    }

    

    if (destinationLatLng == null) return {};

    LatLng? originLatLng = await getCurrentLocation(context);
    if (originLatLng == null || !context.mounted) return {};


    // Directions API Call
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${originLatLng.latitude},${originLatLng.longitude}&destination=${destinationLatLng.latitude},${destinationLatLng.longitude}&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (!context.mounted) return {};

    if (response.statusCode == 200) {
      var decoded = json.decode(response.body);
      if (decoded['routes'].isEmpty) return {};

      final routeData = decoded['routes'][0];
      final leg = routeData['legs'][0];
      final startLatLng = leg['start_location'];
      final endLatLng = leg['end_location'];

      // Update markers
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startLatLng['lat'], startLatLng['lng']),
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(endLatLng['lat'], endLatLng['lng']),
          infoWindow: InfoWindow(title: destinationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Update polyline
      List<PointLatLng> polylineCoordinates = PolylinePoints().decodePolyline(
        routeData['overview_polyline']['points'],
      );
      List<LatLng> latLngList = polylineCoordinates.map((p) => LatLng(p.latitude, p.longitude)).toList();

      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          points: latLngList,
          width: 5,
        ),
      );

      // Animate camera to show the whole route
      double minLat = math.min(originLatLng.latitude, destinationLatLng.latitude);
      double maxLat = math.max(originLatLng.latitude, destinationLatLng.latitude);
      double minLng = math.min(originLatLng.longitude, destinationLatLng.longitude);
      double maxLng = math.max(originLatLng.longitude, destinationLatLng.longitude);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));

      return {
        'distance': leg['distance']['text'],
        'duration': leg['duration']['text'],
      };
    } else {
      return {};
    }
  }
}