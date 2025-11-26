import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'favorite_route.dart';
import 'favoriteRouteData.dart';

class RouteDetailPage extends StatefulWidget {
  final FavoriteRoute route;

  const RouteDetailPage({super.key, required this.route});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color textColor = cs.onSurface;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // ✅ FIX: This forces the back button color to white
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}