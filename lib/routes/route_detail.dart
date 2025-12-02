import 'dart:convert';
import 'package:flutter/material.dart';
import 'routes_service.dart';
import 'route_list.dart';

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;
  final dynamic routeOption;

  const RouteDetailPage({
    Key? key,
    required this.origin,
    required this.destination,
    required this.routeOption,
  }) : super(key: key);

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  Map<String, dynamic>? routeData;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRoute();
  }

  double _toDoubleSafe(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final cleaned = v.trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (v is num) return v.toDouble();
    return 0.0;
  }

  // Flexible coordinate extraction: accept latitude/lat or nested latLng objects
  double _extractLat(Map<dynamic, dynamic> m) {
    if (m == null) return 0.0;
    final candidates = [
      m['latitude'],
      m['lat'],
      m['latLng']?['latitude'],
      m['latLng']?['lat'],
      m['location']?['lat'],
      m['location']?['latitude']
    ];
    for (final c in candidates) {
      if (c != null) return _toDoubleSafe(c);
    }
    return 0.0;
  }

  double _extractLng(Map<dynamic, dynamic> m) {
    if (m == null) return 0.0;
    final candidates = [
      m['longitude'],
      m['lng'],
      m['latLng']?['longitude'],
      m['latLng']?['lng'],
      m['location']?['lng'],
      m['location']?['longitude']
    ];
    for (final c in candidates) {
      if (c != null) return _toDoubleSafe(c);
    }
    return 0.0;
  }

  Future<void> loadRoute() async {
    // Defensive: ensure origin/destination maps are present
    if (widget.origin == null || widget.destination == null) {
      setState(() {
        loading = false;
        errorMessage = 'Missing origin or destination data.';
      });
      return;
    }

    final originMap = widget.origin!;
    final destMap = widget.destination!;

    final originLat = _extractLat(originMap);
    final originLng = _extractLng(originMap);
    final destLat = _extractLat(destMap);
    final destLng = _extractLng(destMap);

    // Validate coordinates
    if (originLat == 0.0 && originLng == 0.0) {
      // allow zero only if user intentionally passed zeros; otherwise warn
      print('Warning: origin resolved to 0,0. originMap: $originMap');
    }

    try {
      final service = RoutesService();
      final result = await service.getRouteDetails(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          loading = false;
          errorMessage = 'No route details returned from the API.';
        });
        return;
      }

      // store raw API response (caller UI will inspect shape)
      setState(() {
        routeData = result;
        loading = false;
        errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('Error loading route details: $e\n$st');
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Failed to load route details.';
        });
      }
    }
  }

  // Helper to safely read list of steps from common response shapes
  List<dynamic> _getStepsSafe(Map<String, dynamic>? data) {
    if (data == null) return [];
    // Common: Google Routes / Directions: routes -> legs -> steps
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final legs = routes[0]['legs'];
        if (legs is List && legs.isNotEmpty) {
          final steps = legs[0]['steps'];
          if (steps is List) return steps;
        }
      }
    } catch (_) {}
    // Alternate: computeRoutes (Routes API) shape - check common nested keys
    try {
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final route = routes[0] as Map<String, dynamic>;
        // v2 computeRoutes uses route['legs'] maybe with steps under 'legs' -> 'steps'
        final legs = route['legs'];
        if (legs is List && legs.isNotEmpty) {
          final steps = legs[0]['steps'];
          if (steps is List) return steps;
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: Center(child: Text(errorMessage!)),
      );
    }

    if (routeData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: const Center(child: Text("Unable to load route details.")),
      );
    }

    final steps = _getStepsSafe(routeData);

    if (steps.isEmpty) {
      // show returned JSON for debugging (developer) and friendly message
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No step-by-step directions found in API response.'),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    JsonEncoder.withIndent('  ').convert(routeData),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Route Details")),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index] as Map<String, dynamic>;

          // Support both v2 and v1 field names
          final mode = (step['travelMode'] ??
                  step['travel_mode'] ??
                  step['maneuver'] ??
                  'UNKNOWN')
              .toString();
          String instruction = '';
          if (step.containsKey('navigationInstruction')) {
            instruction = step['navigationInstruction']?['instructions']?.toString() ?? '';
          }
          instruction = instruction.isNotEmpty
              ? instruction
              : (step['html_instructions']?.toString() ??
                  step['instructions']?.toString() ??
                  step['text']?.toString() ??
                  'Follow path');

          final distance = (step['distance']?['text'] ??
                  step['distance'] ??
                  '')?.toString() ??
              '';
          final duration = (step['duration']?['text'] ??
                  step['duration'] ??
                  '')?.toString() ??
              '';

          final transit = step['transit_details'] ?? step['transitDetails'];

          return ListTile(
            leading: Icon(
              mode.toString().toUpperCase().contains('WALK')
                  ? Icons.directions_walk
                  : mode.toString().toUpperCase().contains('TRANSIT') ||
                          mode.toString().toUpperCase().contains('BUS')
                      ? Icons.directions_bus
                      : Icons.circle,
            ),
            title: Text(instruction),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (distance.isNotEmpty || duration.isNotEmpty)
                  Text("$distance • $duration"),
                if (transit != null) ...[
                  if ((transit['line']?['short_name'] ?? transit['transitLine']?['shortName']) !=
                      null)
                    Text(
                        "Line: ${transit['line']?['short_name'] ?? transit['transitLine']?['shortName']}"),
                  if ((transit['departure_stop']?['name'] ?? transit['stopDetails']?['departureStop']?['name']) != null)
                    Text(
                        "From: ${transit['departure_stop']?['name'] ?? transit['stopDetails']?['departureStop']?['name']}"),
                  if ((transit['arrival_stop']?['name'] ?? transit['stopDetails']?['arrivalStop']?['name']) != null)
                    Text(
                        "To: ${transit['arrival_stop']?['name'] ?? transit['stopDetails']?['arrivalStop']?['name']}"),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
