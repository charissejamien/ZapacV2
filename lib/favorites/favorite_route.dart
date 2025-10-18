import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavoriteRoute {
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
  final String estimatedFare;

  const FavoriteRoute({
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
    required this.estimatedFare,
  });
}
