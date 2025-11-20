import 'package:flutter/material.dart';
import 'routes_service.dart';

class RouteListPage extends StatefulWidget {
  final Map<String, dynamic>? destination;
  final Map<String, dynamic>? origin;

  const RouteListPage({Key? key, this.destination, this.origin})
      : super(key: key);

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  List<RouteOption> options = [];
  bool isLoading = true;
  bool hasError = false;

  SortBy _sortBy = SortBy.time;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final origin = widget.origin?['description'] ??
          widget.origin?['name'] ??
          "Filinvest Cyberzone Cebu Tower One";

      final destination = widget.destination?['description'] ??
          widget.destination?['name'] ??
          "SM City Cebu";

      final result = await RoutesService.getRoutes(
        origin: origin,
        destination: destination,
      );

      setState(() {
        options = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final destLabel = widget.destination != null
        ? (widget.destination!['description'] ??
            widget.destination!['name'] ??
            'Destination')
        : 'SM City Cebu';

    final originLabel = widget.origin != null
        ? (widget.origin!['description'] ??
            widget.origin!['name'] ??
            'Origin')
        : 'Filinvest Cyberzone Cebu Tower One';

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
                  _HeaderChips(
                    originLabel: originLabel,
                    destLabel: destLabel,
                  ),
                  const SizedBox(height: 12),
                  _SortRow(
                    sortBy: _sortBy,
                    onChanged: (s) => setState(() => _sortBy = s),
                  ),
                  const SizedBox(height: 12),

                  /// MAIN ROUTE LIST
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.60,
                    child: Builder(builder: (context) {
                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                        );
                      }

                      if (hasError) {
                        return const Center(
                          child: Text(
                            "Failed to load routes",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (options.isEmpty) {
                        return const Center(
                          child: Text("No routes found"),
                        );
                      }

                      return ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          return _RouteCard(option: opt);
                        },
                      );
                    }),
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
          onPressed: (i) {
            onChanged(i == 0 ? SortBy.fare : SortBy.time);
          },
        ),
      ],
    );
  }
}

class _HeaderChips extends StatelessWidget {
  final String originLabel;
  final String destLabel;

  const _HeaderChips({
    required this.originLabel,
    required this.destLabel,
  });

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
        // TODO: Navigate to route details
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
                      fontWeight: FontWeight.w600,
                    ),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total Fare: ${option.totalFare} php',
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 12),
                ),
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
        icon = Icons.directions_bus; // use bus icon for jeepney
        break;
      case 'bus':
        icon = Icons.directions_bus_filled;
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
