import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../favorites/favorite_route.dart';
import '../favorites/favoriteRouteData.dart';
import '../routes/stepDetail.dart';


class RouteDetailPage extends StatefulWidget {
  final FavoriteRoute route;
  final List<StepDetail>? steps;
  final int? totalDurationMinutes;
  final String? distanceText;

  const RouteDetailPage({
    super.key, 
    required this.route,
    this.steps,
    this.totalDurationMinutes,
    this.distanceText
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = const {};

  LatLng _getCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.route.polylinePoints.isNotEmpty) {
      _markers.add(Marker(
        markerId: const MarkerId('start'),
        position: widget.route.polylinePoints.first,
        infoWindow: InfoWindow(title: 'Start', snippet: widget.route.startAddress),
      ));
      _markers.add(Marker(
        markerId: const MarkerId('end'),
        position: widget.route.polylinePoints.last,
        infoWindow: InfoWindow(title: 'End', snippet: widget.route.endAddress),
      ));

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF4A6FA5),
          points: widget.route.polylinePoints,
          width: 5,
        )
      };
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(widget.route.bounds, 50.0),
    );
  }

  void _deleteRoute() {
    setState(() {
      // 'favoriteRoutes' is now correctly recognized due to the import
      favoriteRoutes.removeWhere((r) => r.routeName == widget.route.routeName);
    });
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route successfully deleted')),
    );
  }

  Widget _buildRouteInfoRow({required IconData icon, required String title, required String content, required Color textColor}) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: secondaryColor, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
              Text(content, style: TextStyle(fontSize: 16, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  // Widget to build the list of estimated fares
  Widget _buildFareList(ColorScheme cs, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Estimated Fares",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: cs.primary
            )
          ),
          const SizedBox(height: 10),
          // Iterate over the fares stored in the FavoriteRoute object
          ...widget.route.estimatedFares.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 20, color: cs.secondary),
                  const SizedBox(width: 10),
                  Text(
                    '${entry.key}:', 
                    style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.8))
                  ),
                  const Spacer(),
                  Text(
                    entry.value, 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

    Widget _buildStepsList(ColorScheme cs) {
    final steps = widget.steps;
    if (steps == null || steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Directions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
          const SizedBox(height: 12),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = steps[i];

              // format time label if startEpoch provided
              String timeLabel = '';
              if (s.startEpoch != null) {
                final dt = DateTime.fromMillisecondsSinceEpoch(s.startEpoch! * 1000);
                final tod = TimeOfDay.fromDateTime(dt);
                timeLabel = tod.format(context);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(timeLabel, style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 6),
                        _modeIcon(s.travelMode, cs),
                        if (i != steps.length - 1)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            width: 2,
                            height: 46,
                            color: cs.onSurface.withOpacity(0.12),
                          )
                        else
                          const SizedBox(height: 52),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: cs.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.instruction, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (s.transitInfo != null && (s.transitInfo!['line_name'] ?? '') != '')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${s.transitInfo!['line_name']}',
                                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                if (s.transitInfo != null) const SizedBox(width: 8),
                                Text(s.durationText, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                                const SizedBox(width: 8),
                                Text(s.distanceText, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                                const Spacer(),
                                if (s.transitInfo != null)
                                  Text('${s.transitInfo!['num_stops']} stops', style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _modeIcon(String mode, ColorScheme cs) {
    switch (mode) {
      case 'walk':
        return Icon(Icons.directions_walk, size: 20, color: cs.onSurface);
      case 'bus':
      case 'jeep':
        return Icon(Icons.directions_bus, size: 20, color: cs.onSurface);
      case 'train':
        return Icon(Icons.train, size: 20, color: cs.onSurface);
      default:
        return Icon(Icons.directions, size: 20, color: cs.onSurface);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color textColor = cs.onSurface;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), 
        title: Text(widget.route.routeName, style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: cs.onPrimary,
            onPressed: _deleteRoute,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: _getCenter(widget.route.bounds), zoom: 12),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: cs.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRouteInfoRow(icon: Icons.my_location, title: "Start", content: widget.route.startAddress, textColor: textColor),
                          const Divider(height: 30),
                          _buildRouteInfoRow(icon: Icons.location_on, title: "Destination", content: widget.route.endAddress, textColor: textColor),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn("Distance", widget.route.distance, textColor),
                              _buildStatColumn("Duration", widget.route.duration, textColor),
                              _buildStatColumn("", "", textColor), // Placeholder for balance
                            ],
                          ),
                          // New section for the detailed fare list
                          _buildFareList(cs, textColor),
                        ],
                      ),
                    ),
                  ),
                  _buildStepsList(cs),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}