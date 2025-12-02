import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutesService {
  final String apiKey = "AIzaSyAzwFKoTmX_nC8c0ylxkLiEScwOEpWyvXcY";

  Future<Map<String, dynamic>?> getRouteDetails({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );

    final body = {
      "origin": {
        "location": {"latLng": {"latitude": originLat, "longitude": originLng}}
      },
      "destination": {
        "location": {"latLng": {"latitude": destLat, "longitude": destLng}}
      },
      "travelMode": "TRANSIT",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
      },
      "requestedReferenceRoutes": ["ROUTE"],
      "requestedTravelDetail": "FULL",
      "languageCode": "en-US",
      "units": "METRIC"
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
            "routes.legs.steps.transitDetails,routes.legs.steps.navigationInstruction,routes.legs.steps.distance,routes.legs.steps.duration,routes.legs.steps.travelMode,routes.duration,routes.distanceMeters",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(response.body);
      return null;
    }
  }
}
