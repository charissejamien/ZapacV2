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

  @override
  void initState() {
    super.initState();
    loadRoute();
  }

  Future<void> loadRoute() async {
    // 1. Safety Check: Ensure data exists before calling API
    if (widget.origin == null || widget.destination == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    final service = RoutesService();

    // 2. flexible coordinate extraction
    // Accepts both 'lat' (common in APIs) and 'latitude' (used in your app)
    double getLat(Map<dynamic, dynamic> m) => (m["latitude"] ?? m["lat"] ?? 0.0).toDouble();
    double getLng(Map<dynamic, dynamic> m) => (m["longitude"] ?? m["lng"] ?? 0.0).toDouble();

    try {
      final result = await service.getRouteDetails(
        originLat: getLat(widget.origin!),
        originLng: getLng(widget.origin!),
        destLat: getLat(widget.destination!),
        destLng: getLng(widget.destination!),
      );

      if (mounted) {
        setState(() {
          routeData = result;
          loading = false;
        });
      }
    } catch (e) {
      print("Error loading route details: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Check if routeData is null (API failure)
    if (routeData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Route Details")),
        body: const Center(child: Text("Unable to load route details.")),
      );
    }

    final steps = routeData?["routes"]?[0]?["legs"]?[0]?["steps"] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Route Details")),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];

          final mode = step["travelMode"] ?? "UNKNOWN";
          final instruction = step["navigationInstruction"]?["instructions"] ?? "Follow path";
          final distance = step["distance"]?["text"] ?? "";
          final duration = step["duration"]?["text"] ?? "";

          final transit = step["transitDetails"];

          return ListTile(
            leading: Icon(
              mode == "WALK" ? Icons.directions_walk :
              mode == "TRANSIT" ? Icons.directions_bus :
              Icons.circle,
            ),
            title: Text(instruction),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$distance • $duration"),
                // 4. Safe access for nested Transit objects to prevent crashes
                if (transit != null) ...[
                  if (transit["transitLine"] != null)
                    Text("Bus/Jeep: ${transit["transitLine"]?["shortName"] ?? 'N/A'}"),
                  if (transit["stopDetails"]?["arrivalStop"] != null)
                    Text("From: ${transit["stopDetails"]?["arrivalStop"]?["name"] ?? 'Unknown'}"),
                  if (transit["stopDetails"]?["departureStop"] != null)
                    Text("To: ${transit["stopDetails"]?["departureStop"]?["name"] ?? 'Unknown'}"),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
