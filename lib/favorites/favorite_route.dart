import 'package:google_maps_flutter/google_maps_flutter.dart';
// NEW IMPORT for Firestore server timestamp
import 'package:cloud_firestore/cloud_firestore.dart'; 

class FavoriteRoute {
  final String? id; // NEW: Firestore document ID for updates/deletes
  final String routeName;
  final String startAddress;
  final String endAddress;
  final LatLngBounds bounds;
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final double latitude;
  final double longitude;
  final double startLatitude;
  final double startLongitude;
  final String polylineEncoded;
  final Map<String, String> estimatedFares;

  const FavoriteRoute({
    this.id, // NEW: Include in constructor
    required this.routeName,
    required this.startAddress,
    required this.endAddress,
    required this.bounds,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.startLatitude,
    required this.startLongitude,
    required this.polylineEncoded,
    required this.estimatedFares,
  });

  // Factory constructor to create a FavoriteRoute from a Firestore document map
  factory FavoriteRoute.fromMap(Map<String, dynamic> data, String id) {
    // Helper function to parse LatLngBounds from a map
    LatLngBounds boundsFromMap(Map<String, dynamic> map) {
      return LatLngBounds(
        southwest: LatLng(map['southwest']['latitude'] as double, map['southwest']['longitude'] as double),
        northeast: LatLng(map['northeast']['latitude'] as double, map['northeast']['longitude'] as double),
      );
    }

    // Helper function to parse List<LatLng> from a list of maps
    List<LatLng> polylineFromList(List<dynamic> list) {
      return list.map((e) => LatLng(e['latitude'] as double, e['longitude'] as double)).toList();
    }
    
    // Convert estimatedFares map values from dynamic to String
    Map<String, String> parsedFares = Map<String, String>.from(data['estimatedFares'] ?? {});


    return FavoriteRoute(
      id: id,
      routeName: data['routeName'] as String,
      startAddress: data['startAddress'] as String,
      endAddress: data['endAddress'] as String,
      bounds: boundsFromMap(data['bounds'] as Map<String, dynamic>),
      polylinePoints: polylineFromList(data['polylinePoints'] as List<dynamic>),
      distance: data['distance'] as String,
      duration: data['duration'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      startLatitude: data['startLatitude'] as double,
      startLongitude: data['startLongitude'] as double,
      polylineEncoded: data['polylineEncoded'] as String,
      estimatedFares: parsedFares,
    );
  }

  // Method to convert the FavoriteRoute object to a map for Firestore
  Map<String, dynamic> toMap() {
    // Helper function to convert LatLngBounds to a map
    Map<String, dynamic> boundsToMap(LatLngBounds bounds) {
      return {
        'southwest': {
          'latitude': bounds.southwest.latitude,
          'longitude': bounds.southwest.longitude,
        },
        'northeast': {
          'latitude': bounds.northeast.latitude,
          'longitude': bounds.northeast.longitude,
        },
      };
    }

    // Helper function to convert List<LatLng> to a list of maps
    List<Map<String, dynamic>> polylineToList(List<LatLng> polylinePoints) {
      return polylinePoints.map((p) => {
            'latitude': p.latitude,
            'longitude': p.longitude,
          }).toList();
    }

    return {
      'routeName': routeName,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'bounds': boundsToMap(bounds),
      'polylinePoints': polylineToList(polylinePoints),
      'distance': distance,
      'duration': duration,
      'latitude': latitude,
      'longitude': longitude,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'polylineEncoded': polylineEncoded,
      'estimatedFares': estimatedFares,
      'createdAt': FieldValue.serverTimestamp(), // NEW: for sorting and persistence metadata
    };
  }
}