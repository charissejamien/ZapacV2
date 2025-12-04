import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'favorite_route.dart';
import 'favorite_routes_service.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:io' show Platform; 
import 'package:zapac/core/widgets/fare_accuracy_review.dart';

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
  final FavoriteRoutesService _routesService = FavoriteRoutesService(); 

  static const int alpha179 = 179;
  static const int alpha13 = 13;
  static const int alpha26 = 26;
  static const int alpha31 = 31;
  static const int alpha204 = 204;

  final Color angkasBlue = const Color(0xFF14b2d8);
  final Color maximYellow = const Color(0xFFFDDB0A); 
  final Color moveItRed = const Color(0xFFBB3329); 
  final Color grabGreen = const Color.fromARGB(255, 5, 199, 76);
  final Color joyrideBlue = const Color(0xFF1E21CD);


  static const Map<String, dynamic> appLinks = {
    'Angkas': {
      'scheme': 'angkasrider://', 
      'androidPackage': 'com.angkas.rider',
      'iosAppId': '1096417726', 
    },
    'Maxim': {
      'scheme': 'taximaxim://',
      'androidPackage': 'com.taxsee.taxsee',
      'iosAppId': '597956747',
    },
    'MoveIt': {
      'scheme': 'moveit://',
      'androidPackage': 'com.moveitph.rider',
      'iosAppId': '1465241038',
    },
    'JoyRide': {
      'scheme': 'joyride://', 
      'androidPackage': 'com.joyride.rider',
      'iosAppId': '1467478148', 
    },
    'Grab': {
      'scheme': 'grab://',
      'androidPackage': 'com.grab.passenger',
      'iosAppId': '643912198',
    },
  };

  LatLng _getCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }
  
  IconData _getTransportIcon(String transportName) {
    final lowerName = transportName.toLowerCase();
    if (lowerName.contains('moto taxi')) return Icons.two_wheeler;
    if (lowerName.contains('grab')) return Icons.directions_car_filled; 
    if (lowerName.contains('taxi')) return Icons.local_taxi;
    if (lowerName.contains('puj') || lowerName.contains('bus')) return Icons.directions_bus_filled;
    return Icons.directions_car; 
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
  
  // --- App Launch Logic (Unchanged from previous fix) ---
  Future<void> _launchAppOrStore(String appName) async {
    final data = appLinks[appName];
    if (data == null || !mounted) return;

    final String appScheme = data['scheme'];
    String storeLink;

    if (Platform.isAndroid) {
      storeLink = "https://play.google.com/store/apps/details?id=${data['androidPackage']}";
    } else if (Platform.isIOS) {
      storeLink = "https://apps.apple.com/app/id${data['iosAppId']}";
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App redirection not supported on this platform.')),
        );
      }
      return;
    }

    final appUri = Uri.parse(appScheme);
    final storeUri = Uri.parse(storeLink);

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } 
    else if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } 
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $appName or app store.')),
        );
      }
    }
  }
  // --------------------------------------------------------

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
              Text(title, style: TextStyle(fontSize: 14, color: textColor.withAlpha(alpha179))),
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
        Text(label, style: TextStyle(fontSize: 14, color: textColor.withAlpha(alpha179))),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
  
  Widget _buildTransportListItem(ColorScheme cs, Color textColor, String transportName, String fare, String duration) {
    const String timeRange = '10 am \u2192 10 am'; 
    final IconData icon = _getTransportIcon(transportName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withAlpha(alpha13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: cs.secondary),
          const SizedBox(width: 10),
          Flexible( 
            child: Text(
              transportName, 
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Spacer(),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeRange, 
                style: TextStyle(fontSize: 14, color: textColor.withAlpha(alpha204))
              ),
              const SizedBox(width: 8), 
              
              Text(
                duration, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary) 
              ),
            ],
          ),
          
          const SizedBox(width: 15),
          
          Text(
            fare, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)
          ),
        ],
      ),
    );
  }

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
      shadowColor: cs.shadow.withAlpha(alpha26), 
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Future detailed flow here
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeRange, 
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(alpha31), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      durationText, 
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              transportRow,
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: TextStyle(color: cs.onSurface.withAlpha(alpha179)),
                  ),
                  Text(
                    fare, 
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

  Widget _buildActionButton(ColorScheme cs, String appName, String imagePath, {required Color backgroundColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _launchAppOrStore(appName),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            minimumSize: const Size(0, 20),
            backgroundColor: backgroundColor, 
          ),
          child: Image.asset(
            imagePath,
            height: 24,
            fit: BoxFit.contain,
            color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, 
            colorBlendMode: BlendMode.modulate, 
          ),
        ),
      ),
    );
  }


  Widget _buildMotoTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Angkas
        _buildActionButton(
          cs, 
          'Angkas',
          'assets/angkas.png',
          backgroundColor: angkasBlue,
        ), 
        // Maxim
        _buildActionButton(
          cs, 
          'Maxim',
          'assets/maxim.png',
          backgroundColor: maximYellow,
        ), 
        // MoveIt
        _buildActionButton(
          cs, 
          'MoveIt',
          'assets/moveit.png',
          backgroundColor: moveItRed,
        ), 
        // JoyRide
        _buildActionButton(
          cs, 
          'JoyRide',
          'assets/joyride.png',
          backgroundColor: joyrideBlue,
        ),
      ],
    );
  }
  
  Widget _buildTaxiButtonsRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Grab
        _buildActionButton(
          cs, 
          'Grab',
          'assets/grab.png',
          backgroundColor: grabGreen,
        ),
        // JoyRide
        _buildActionButton(
          cs, 
          'JoyRide',
          'assets/joyride.png',
          backgroundColor: joyrideBlue,
        ),
      ],
    );
  }


  Widget _buildFareList(ColorScheme cs, Color textColor) {
    final List<Widget> fareWidgets = [];

    widget.route.estimatedFares.entries.forEach((entry) {
      final transportType = entry.key; // e.g., 'Moto Taxi', 'Taxi', 'PUJ'
      
      // 1. Add the main fare card
      fareWidgets.add(
        _buildFareOptionCard(
          cs, 
          transportType, 
          entry.value, 
          widget.route.duration
        )
      );

      // 2. Conditionally add the ride-hailing buttons row below the card
      if (transportType == 'Moto Taxi') {
        fareWidgets.add(
              Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 8, right: 8),
              child: _buildMotoTaxiButtonsRow(cs), // New Moto Taxi Row
            )
        );
      } else if (transportType == 'Taxi') {
          fareWidgets.add(
              Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 8.0, left: 16, right: 16),
              child: _buildTaxiButtonsRow(cs), // New Taxi Row
            )
        );
      }
      
      // Add a small divider or spacer between different transport type cards
      fareWidgets.add(const SizedBox(height: 10)); 
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

    final String estimatedFareLabel = widget.route.estimatedFares.values.isNotEmpty
        ? widget.route.estimatedFares.values.first
        :'N/A';

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), 
        title: Text(widget.route.routeName, style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        actions: [
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
      bottomNavigationBar: FareAccuracyReviewBar(
        routeName: widget.route.routeName,
        estimatedFareLabel: estimatedFareLabel, 
        onAnswer: (isAccurate) {
        },
    ),
    );
  }
  }