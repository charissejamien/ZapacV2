import 'dart:convert';
import 'package:http/http.dart' as http;
import 'route_list.dart';

class RoutesService {
  static const String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  static Future<List<RouteOption>> getRoutes({
    required String origin,
    required String destination,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=$origin"
        "&destination=$destination"
        "&mode=transit"
        "&key=$apiKey";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("Failed to load directions");
    }

    final data = json.decode(res.body);

    List<RouteOption> results = [];

    for (var route in data["routes"]) {
      final leg = route["legs"][0];

      final depart = leg["departure_time"]?["text"] ?? "N/A";
      final arrive = leg["arrival_time"]?["text"] ?? "N/A";
      final duration = leg["duration"]["value"] ~/ 60;

      final steps = <String>[];

      for (var step in leg["steps"]) {
        final travelMode = step["travel_mode"].toLowerCase();

        if (travelMode == "walking") steps.add("walk");

        if (travelMode == "transit") {
          final type =
              step["transit_details"]["line"]["vehicle"]["type"];

          if (type == "BUS") steps.add("bus");
          if (type == "JEEPNEY" || type == "SHARED_TAXI") steps.add("jeep");
          if (type == "HEAVY_RAIL" ||
              type == "METRO_RAIL" ||
              type == "SUBWAY") steps.add("train");
        }
      }

      results.add(
        RouteOption(
          depart: depart,
          arrive: arrive,
          durationMinutes: duration,
          totalFare: 50, 
          legs: steps,
        ),
      );
    }

    return results;
  }
}
