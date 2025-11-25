import 'package:flutter/material.dart';
import 'dart:convert';
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
  SortBy _sortBy = SortBy.time;

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

    try {
      // Get origin coordinates (current location or provided origin)
      final originLat = widget.origin?['latitude'] ?? 10.3157; // Default to Cebu
      final originLng = widget.origin?['longitude'] ?? 123.8854;

      // Get destination coordinates
      final destLat = widget.destination!['latitude'];
      final destLng = widget.destination!['longitude'];

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
      print('Error fetching routes: $e');
      setState(() {
        _errorMessage = "Error: $e";
        _isLoading = false;
      });
    }
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

  void _sortRoutes() {
    setState(() {
      if (_sortBy == SortBy.fare) {
        options.sort((a, b) => a.totalFare.compareTo(b.totalFare));
      } else {
        options.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final destLabel = widget.destination != null
        ? (widget.destination!['description'] ?? widget.destination!['name'] ?? 'Destination')
        : 'Destination';

    final originLabel = widget.origin != null
        ? (widget.origin!['description'] ?? widget.origin!['name'] ?? 'Your Location')
        : 'Your Location';

    return Scaffold(
      backgroundColor: const Color(0xFF3C3F42),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Routes',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _HeaderChips(originLabel: originLabel, destLabel: destLabel),
                  const SizedBox(height: 12),
                  _SortRow(
                    sortBy: _sortBy,
                    onChanged: (s) {
                      setState(() => _sortBy = s);
                      _sortRoutes();
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Loading, Error, or Route List
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.60,
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Fetching routes...', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLoading = true;
                                          _errorMessage = null;
                                        });
                                        _fetchRoutes();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : options.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No routes available',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final opt = options[index];
                                      return _RouteCard(option: opt);
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

enum SortBy { fare, time }

class _SortRow extends StatelessWidget {
  final SortBy sortBy;
  final ValueChanged<SortBy> onChanged;

  const _SortRow({required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Sort', style: TextStyle(color: Colors.black54)),
        const Spacer(),
        ToggleButtons(
          isSelected: [sortBy == SortBy.fare, sortBy == SortBy.time],
          borderRadius: BorderRadius.circular(6),
          selectedColor: Colors.white,
          color: Colors.black54,
          fillColor: Colors.blueGrey,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Fare', style: TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Time', style: TextStyle(fontSize: 12)),
            ),
          ],
          onPressed: (i) => onChanged(i == 0 ? SortBy.fare : SortBy.time),
        ),
      ],
    );
  }
}

class _HeaderChips extends StatelessWidget {
  final String originLabel;
  final String destLabel;
  const _HeaderChips({required this.originLabel, required this.destLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _roundedChip(originLabel),
        const SizedBox(height: 8),
        _roundedChip(destLabel),
      ],
    );
  }

  Widget _roundedChip(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87),
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
    return InkWell(
      onTap: () {
        // TODO: navigate to route details
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${option.depart} - ${option.arrive}',
                    style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var leg in option.legs) ...[
                        _iconForLeg(leg),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${option.durationMinutes} mins',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text('Total Fare: ₱${option.totalFare}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconForLeg(String leg) {
    IconData icon;
    switch (leg) {
      case 'walk':
        icon = Icons.directions_walk;
        break;
      case 'jeep':
        icon = Icons.directions_bus;
        break;
      case 'bus':
        icon = Icons.directions_transit;
        break;
      case 'train':
        icon = Icons.train;
        break;
      default:
        icon = Icons.circle;
    }
    return Icon(icon, size: 16, color: Colors.black54);
  }
}