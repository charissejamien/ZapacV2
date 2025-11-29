import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'favorite_route.dart';
// import 'favoriteRouteData.dart'; // REMOVED: Replaced by Firebase service

// NEW IMPORTS for Firebase deletion
import 'package:firebase_auth/firebase_auth.dart';
import 'favorite_routes_service.dart';

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
  // NEW: Instantiate the service for deletion
  final FavoriteRoutesService _routesService = FavoriteRoutesService(); 

  LatLng _getCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }
  
  // NEW: Helper function to map transport names to Icons
  IconData _getTransportIcon(String transportName) {
    final lowerName = transportName.toLowerCase();
    if (lowerName.contains('moto taxi')) return Icons.two_wheeler;
    if (lowerName.contains('grab')) return Icons.directions_car_filled; 
    if (lowerName.contains('taxi')) return Icons.local_taxi;
    if (lowerName.contains('puj') || lowerName.contains('bus')) return Icons.directions_bus_filled;
    return Icons.directions_car; // Default fallback
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
  
  // MODIFIED: Delete route using Firebase service
  void _deleteRoute() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${widget.route.routeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.route.id != null) {
        try {
          await _routesService.deleteFavoriteRoute(widget.route.id!);
          if (mounted) {
            Navigator.pop(context); // Pop RouteDetailPage
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Route successfully deleted from cloud.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete route: ${e.toString()}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot delete route: ID missing.')),
          );
        }
      }
    }
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
  
  // MODIFIED: _buildTransportListItem to use Flexible and Spacer correctly
  Widget _buildTransportListItem(ColorScheme cs, Color textColor, String transportName, String fare, String duration) {
    // Fixed placeholder for time range as requested
    const String timeRange = '10 am \u2192 10 am'; // Arrow character: →
    final IconData icon = _getTransportIcon(transportName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. LEFT SIDE: Icon + Transport Name (Wrapped in Flexible to avoid overflow)
          Icon(icon, size: 24, color: cs.secondary),
          const SizedBox(width: 10),
          // Use Flexible to let the name take up remaining space until the spacer
          Flexible( 
            child: Text(
              transportName, 
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          Spacer(), // Pushes content to the right
          
          // 2. MIDDLE-RIGHT: Time Range + Duration (Side-by-Side)
          Row(
            mainAxisSize: MainAxisSize.min, // Ensure this group doesn't take unnecessary space
            children: [
              // Time Range
              Text(
                timeRange, 
                style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8))
              ),
              const SizedBox(width: 8), 
              
              // Duration (in blue, beside Time Range)
              Text(
                duration, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary) 
              ),
            ],
          ),
          
          const SizedBox(width: 15), // Separator before Fare
          
          // 3. FAR RIGHT: Estimated Fare
          Text(
            fare, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)
          ),
        ],
      ),
    );
  }

  // NEW: Widget to build a single fare option, using the exact UI structure provided by the user.
  Widget _buildFareOptionCard(ColorScheme cs, String transportName, String fare, String durationText) {
    const String timeRange = '10 am \u2192 10 am';
    
    Widget transportRow = Row(
      children: [
        Icon(_getTransportIcon(transportName), size: 20, color: cs.secondary),
        const SizedBox(width: 8),
        Text(
          transportName,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: cs.shadow.withOpacity(0.1),
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Navigator.push... (Future detailed flow here)
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Time Row (Schedule Icon, Time Range, Duration Badge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeRange, // Fixed Time Range placeholder
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    // Duration Badge styling
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      durationText, // Route duration as placeholder
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 2. Transport Info (Replacing the Wrap of leg chips)
              transportRow,
              
              const SizedBox(height: 12),
              
              // 3. Fare Row (Estimated Fare Label and Price)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                  ),
                  Text(
                    fare, // Actual calculated fare
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODIFIED: Helper for building individual logo buttons (no text)
  Widget _buildActionButton(ColorScheme cs, String imagePath, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12), // Adjust padding for image
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(0, 20), // Set minimum height for visibility
          ),
          child: Image.asset(
            imagePath,
            height: 24, // Control image size
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // MODIFIED: _buildRideHailingButtonsRow now uses Image assets instead of icons/text
  Widget _buildRideHailingButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Angkas: images.png
        _buildActionButton(cs, 'assets/angkas.jng', () { /* Handle Angkas tap */ }), 
        // Maxim: images.jpg
        _buildActionButton(cs, 'assets/maxim.png', () { /* Handle Maxim tap */ }), 
        // MoveIt: 1737959726Move It.png
        _buildActionButton(cs, 'assets/moveit.png', () { /* Handle MoveIt tap */ }), 
      ],
    );
  }

  // MODIFIED: _buildFareList now iterates and inserts the new card structure
  Widget _buildFareList(ColorScheme cs, Color textColor) {
    final List<Widget> fareWidgets = [];

    widget.route.estimatedFares.entries.forEach((entry) {
      final isMotoTaxi = entry.key == 'Moto Taxi';
      
      // 1. Add the main fare card
      fareWidgets.add(
        _buildFareOptionCard(
          cs, 
          entry.key, 
          entry.value, 
          widget.route.duration
        )
      );

      // 2. Conditionally add the ride-hailing buttons row below the card
      if (isMotoTaxi) {
        fareWidgets.add(
             Padding(
              // Adds space between buttons and next card, but links buttons closely to the Moto Taxi card
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 16, right: 16),
              child: _buildRideHailingButtonsRow(cs),
            )
        );
      }
    });

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
          // Display the list of fare items and buttons
          ...fareWidgets,
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
        iconTheme: const IconThemeData(color: Colors.white), 
        title: Text(widget.route.routeName, style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        actions: [
          // Only allow deletion if a Firebase ID is available 
          if (widget.route.id != null) 
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
                              _buildStatColumn("", "", textColor), 
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