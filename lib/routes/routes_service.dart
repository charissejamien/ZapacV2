import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stepDetail.dart';

class RoutesService {
  // Set your real API key here
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
        "&alternatives=true"
        "&departure_time=${DateTime.now().millisecondsSinceEpoch ~/ 1000}"
        "&key=$apiKey";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("Failed to load directions (${res.statusCode})");
    }

    final data = json.decode(res.body) as Map<String, dynamic>;

    final status = (data['status'] ?? '').toString();
    if (status != 'OK') {
      if (status == 'ZERO_RESULTS') return [];
      throw Exception("Directions API error: $status");
    }

    final routes = (data["routes"] as List<dynamic>?) ?? [];
    final List<RouteOption> results = [];

    for (var route in routes) {
      final legs = (route['legs'] as List<dynamic>?) ?? [];
      if (legs.isEmpty) continue;
      final leg = (legs[0] as Map<String, dynamic>);

      final depart = leg["departure_time"]?["text"]?.toString() ?? "N/A";
      final arrive = leg["arrival_time"]?["text"]?.toString() ?? "N/A";
      final durationSec = (leg["duration"]?["value"] ?? 0) as int;
      final duration = (durationSec ~/ 60);
      final distanceMeters = (leg["distance"]?["value"] ?? 0) as int;
      final distanceText = leg["distance"]?["text"]?.toString() ?? "N/A";

      // Build detailed steps
      final List<StepDetail> steps = [];
      int cumulative = 0;
      final legDepartureEpoch = (leg['departure_time'] != null && leg['departure_time']['value'] != null)
          ? (leg['departure_time']['value'] as int)
          : DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final legSteps = (leg["steps"] as List<dynamic>?) ?? [];
      for (var s in legSteps) {
        final stepMap = (s as Map<String, dynamic>);
        final rawMode = (stepMap["travel_mode"] ?? '').toString().toLowerCase();
        final travelMode = (rawMode == 'walking') ? 'walk' : rawMode; // will refine for transit below

        final htmlInstr = stepMap['html_instructions']?.toString() ?? '';
        final instruction = htmlInstr.replaceAll(RegExp(r'<[^>]*>'), '');

        final stepDurationSec = (stepMap['duration']?['value'] ?? 0) as int;
        final stepDurationText = stepMap['duration']?['text']?.toString() ?? '';
        final stepDistanceText = stepMap['distance']?['text']?.toString() ?? '';

        final startEpoch = legDepartureEpoch + cumulative;
        cumulative += stepDurationSec;

        Map<String, dynamic>? transitInfo;
        String finalTravelMode = travelMode;

        if ((stepMap['transit_details']) != null) {
          final t = (stepMap['transit_details'] as Map<String, dynamic>);
          final vehicleType = t['line']?['vehicle']?['type']?.toString() ?? '';
          // normalize vehicle type to lowercase and pick UI-friendly mode
          final vehicle = vehicleType.toString().toLowerCase();
          if (vehicle.contains('bus')) finalTravelMode = 'bus';
          else if (vehicle.contains('jeep') || vehicle.contains('jeepney')) finalTravelMode = 'jeep';
          else if (vehicle.contains('rail') || vehicle.contains('train') || vehicle.contains('metro') || vehicle.contains('subway')) finalTravelMode = 'train';
          else finalTravelMode = 'transit';

          transitInfo = {
            'line_name': t['line']?['short_name'] ?? t['line']?['name'] ?? '',
            'vehicle': vehicleType,
            'num_stops': t['num_stops'] ?? 0,
            'departure_stop': t['departure_stop']?['name'] ?? '',
            'arrival_stop': t['arrival_stop']?['name'] ?? '',
            'headsign': t['headsign'] ?? '',
          };
        }

        steps.add(StepDetail(
          travelMode: finalTravelMode,
          instruction: instruction,
          distanceText: stepDistanceText,
          durationText: stepDurationText,
          durationSeconds: stepDurationSec,
          transitInfo: transitInfo,
          startEpoch: startEpoch,
        ));
      }

      final totalFare = _calculateFare(distanceMeters / 1000.0);

      results.add(RouteOption(
        depart: depart,
        arrive: arrive,
        durationMinutes: duration,
        totalFare: totalFare,
        legs: steps.map((e) => e.travelMode).toList(),
        steps: steps,
        distanceText: distanceText,
      ));
    }

    return results;
  }

  static int _calculateFare(double distanceKm) {
    if (distanceKm <= 4.0) return 15;
    return (15 + ((distanceKm - 4.0) * 2.5)).round();
  }
}
