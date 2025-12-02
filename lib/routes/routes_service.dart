import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutesService {
  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc";

  /// Returns the decoded Directions API JSON (or null on error).
  Future<Map<String, dynamic>?> getRouteDetails({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'transit', // change to 'driving' to test
  }) async {
    final params = {
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
      'mode': mode,
      'alternatives': 'true',
      'departure_time': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'key': apiKey,
    };

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', params);

    // debug: print URL so you can paste into browser to inspect
    print('Directions API URL: $uri');

    final resp = await http.get(uri).timeout(const Duration(seconds: 15));

    print('Directions API status: ${resp.statusCode}');
    print('Directions API body: ${resp.body}'); // debug: inspect response

    if (resp.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> data = json.decode(resp.body) as Map<String, dynamic>;
    return data;
  }
}
