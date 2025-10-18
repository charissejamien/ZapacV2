import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
// Removed: import 'package:zapac/models/favorite_route.dart';

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

  static Future<void> getCurrentLocationAndMarker(
    Set<Marker> markers,
    GoogleMapController mapController,
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    if (!isMounted()) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!isMounted()) return;

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      
      markers.removeWhere((marker) => marker.markerId.value == 'current_location');
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      if (isMounted()) {
        mapController.animateCamera(CameraUpdate.newLatLng(currentLatLng));
      }
    } catch (e) {
      print('Error getting location: $e');
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
      }
    }
  }

  static Future<Map<String, dynamic>> showRoute({
    required dynamic item, // Can be place ID or route object
    required String apiKey,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
    required GoogleMapController mapController,
    required BuildContext context,
  }) async {
    if (!context.mounted) return {};

    LatLng? destinationLatLng;
    String destinationName = '';

    // --- Destination Extraction (Simplified due to lack of FavoriteRoute model) ---
    try {
      if (item is Map && item.containsKey('place')) {
        final placeId = item['place']['place_id'];
        destinationName = item['place']['description'];

        // Get details (lat/lng) from Place ID
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
        // Handle case where item is a simpler route/marker object if needed
        return {};
      }
    } catch (_) {
      return {};
    }

    

    if (destinationLatLng == null) return {};

    // --- Permissions & Current Position Check ---
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return {};

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return {};
      }
    }

    Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (!context.mounted) return {};

    LatLng originLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    // --- Directions API Call ---
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

Future<List<dynamic>> getPredictions(String input, String apiKey) async {
  if (input.isEmpty) return [];

  try {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:ph';
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
