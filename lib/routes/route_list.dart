import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class RouteListPage extends StatefulWidget {
  final Map<String, dynamic>? destination;
  final Map<String, dynamic>? origin;

  const RouteListPage({Key? key, this.destination, this.origin}) : super(key: key);

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  List<RouteOption> options = [];
  bool _isLoading = true;
  String? _errorMessage;
  // SortBy _sortBy = SortBy.time;
  Map<String, double>? _originCoords;

  // Replace with your actual API key
  final String apiKey = "AIzaSyAJP6e_5eBGz1j8b6DEKqLT-vest54Atkc";

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    if (widget.destination == null) {
      setState(() {
        _errorMessage = "No destination provided";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final origin = await _resolveOrigin();
      if (!mounted) return;

      // Get origin coordinates (current location or provided origin)
      final originLat = origin['latitude'] ?? 10.3157; // Default to Cebu
      final originLng = origin['longitude'] ?? 123.8854;

      // Get destination coordinates
      final destLat = _toDouble(widget.destination!['latitude']);
      final destLng = _toDouble(widget.destination!['longitude']);

      if (destLat == null || destLng == null) {
        setState(() {
          _errorMessage = "Invalid destination coordinates";
          _isLoading = false;
        });
        return;
      }

      // Build the Directions API URL
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=transit'
        '&alternatives=true'
        '&key=$apiKey'
      );

      print('Fetching routes from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null) {
          final List<RouteOption> fetchedRoutes = [];

          for (var route in data['routes']) {
            if (route['legs'] != null && route['legs'].isNotEmpty) {
              final leg = route['legs'][0];
              
              // Extract departure and arrival times
              final departureTime = leg['departure_time']?['text'] ?? 
                                   DateTime.now().toString().substring(11, 16);
              final arrivalTime = leg['arrival_time']?['text'] ?? 'N/A';
              
              // Extract duration in minutes
              final durationValue = leg['duration']?['value'] ?? 0;
              final durationMinutes = (durationValue / 60).round();
              
              // Calculate estimated fare based on distance
              final distanceValue = leg['distance']?['value'] ?? 0;
              final distanceKm = distanceValue / 1000;
              final estimatedFare = _calculateFare(distanceKm);
              
              // Extract transport modes
              final List<String> transportModes = [];
              if (leg['steps'] != null) {
                for (var step in leg['steps']) {
                  final travelMode = step['travel_mode']?.toString().toLowerCase() ?? '';
                  final transitDetails = step['transit_details'];
                  
                  if (travelMode == 'walking') {
                    if (!transportModes.contains('walk')) {
                      transportModes.add('walk');
                    }
                  } else if (travelMode == 'transit' && transitDetails != null) {
                    final vehicleType = transitDetails['line']?['vehicle']?['type']?.toString().toLowerCase() ?? '';
                    
                    if (vehicleType.contains('bus') && !transportModes.contains('bus')) {
                      transportModes.add('bus');
                    } else if ((vehicleType.contains('rail') || vehicleType.contains('train')) 
                              && !transportModes.contains('train')) {
                      transportModes.add('train');
                    } else if (!transportModes.contains('jeep')) {
                      // Default to jeep for other transit types (common in Philippines)
                      transportModes.add('jeep');
                    }
                  }
                }
              }
              
              // Ensure at least one transport mode
              if (transportModes.isEmpty) {
                transportModes.add('jeep');
              }

              fetchedRoutes.add(RouteOption(
                depart: departureTime,
                arrive: arrivalTime,
                durationMinutes: durationMinutes,
                totalFare: estimatedFare,
                legs: transportModes,
              ));
            }
          }

          if (fetchedRoutes.isEmpty) {
            setState(() {
              _errorMessage = "No transit routes found for this destination";
              _isLoading = false;
            });
            return;
          }

          setState(() {
            options = fetchedRoutes;
            _isLoading = false;
          });
        } else {
          final status = data['status'] ?? 'UNKNOWN';
          setState(() {
            _errorMessage = "API Error: $status";
            _isLoading = false; 
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to fetch routes: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching routes: $message');
      setState(() {
        _errorMessage = message.isEmpty ? "Error fetching routes." : message;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, double>> _resolveOrigin() async {
    if (_originCoords != null) {
      return _originCoords!;
    }

    final providedOrigin = _extractCoordinates(widget.origin);
    if (providedOrigin != null) {
      _originCoords = providedOrigin;
      return providedOrigin;
    }

    final currentLocation = await _getCurrentLocation();
    _originCoords = currentLocation;
    return currentLocation;
  }

  Map<String, double>? _extractCoordinates(Map<String, dynamic>? data) {
    if (data == null) return null;
    final lat = _toDouble(data['latitude']);
    final lng = _toDouble(data['longitude']);

    if (lat == null || lng == null) return null;

    return {'latitude': lat, 'longitude': lng};
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<Map<String, double>> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied. Allow access to continue.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Enable them from Settings.');
    }

    final position =
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  int _calculateFare(double distanceKm) {
    // Basic fare calculation for PH jeepney/transit
    // Minimum fare: 15 PHP for first 4km, then 2.5 PHP per km
    if (distanceKm <= 4.0) {
      return 15;
    } else {
      return (15 + ((distanceKm - 4.0) * 2.5)).round();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final destLabel = widget.destination != null
        ? (widget.destination!['description'] ?? widget.destination!['name'] ?? 'Destination')
        : 'Destination';

    final originLabel = widget.origin != null
        ? (widget.origin!['description'] ?? widget.origin!['name'] ?? 'Your Location')
        : 'Your Location';

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: _handleBackToDashboard,
        ),
        title: Text(
          'Routes',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderChips(originLabel: originLabel, destLabel: destLabel),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              
              // Loading, Error, or Route List
              Expanded(
                child: _buildRouteContent(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Fetching routes...',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchRoutes,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (options.isEmpty) {
      return Center(
        child: Text(
          'No routes available right now.',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final opt = options[index];
        return _RouteCard(option: opt);
      },
    );
  }

  void _handleBackToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}


class _HeaderChips extends StatelessWidget {
  final String originLabel;
  final String destLabel;
  const _HeaderChips({required this.originLabel, required this.destLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onPrimary;

    Widget buildRow(String label, String value, IconData icon) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip summary',
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 13,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          buildRow('Your Location', originLabel, Icons.radio_button_checked),
          const SizedBox(height: 12),
          Divider(color: textColor.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          buildRow('Destination', destLabel, Icons.location_on_rounded),
        ],
      ),
    );
  }
}

class RouteOption {
  final String depart;
  final String arrive;
  final int durationMinutes;
  final int totalFare;
  final List<String> legs;

  RouteOption({
    required this.depart,
    required this.arrive,
    required this.durationMinutes,
    required this.totalFare,
    required this.legs,
  });
}

class _RouteCard extends StatelessWidget {
  final RouteOption option;
  const _RouteCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      color: colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: hook into route detail flow
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${option.depart} → ${option.arrive}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${option.durationMinutes} mins',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final leg in option.legs) _legChip(leg, colorScheme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  Text(
                    '₱${option.totalFare}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
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

  Widget _legChip(String leg, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForLeg(leg), size: 16, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            _formatLegLabel(leg),
            style: TextStyle(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLegLabel(String leg) {
    if (leg.isEmpty) return leg;
    return leg[0].toUpperCase() + leg.substring(1);
  }

  IconData _iconForLeg(String leg) {
    switch (leg) {
      case 'walk':
        return Icons.directions_walk;
      case 'jeep':
        return Icons.directions_bus;
      case 'bus':
        return Icons.directions_transit;
      case 'train':
        return Icons.train;
      default:
        return Icons.circle;
    }
  }
}