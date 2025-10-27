import 'package:flutter/material.dart';

class RouteListPage extends StatefulWidget {
  // ...existing code...
  final Map<String, dynamic>? destination;
  final Map<String, dynamic>? origin; // optional, if you want to pass origin too

  const RouteListPage({Key? key, this.destination, this.origin}) : super(key: key);

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  // sample model
  final List<RouteOption> options = List.generate(
    5,
    (i) => RouteOption(
      depart: '10:07',
      arrive: '10:36',
      durationMinutes: 21,
      totalFare: 50,
      legs: ['walk', 'jeep', 'bus'],
    ),
  );

  SortBy _sortBy = SortBy.time;

  @override
  Widget build(BuildContext context) {
    final destLabel = widget.destination != null
        ? (widget.destination!['description'] ?? widget.destination!['name'] ?? 'Destination')
        : 'SM City Cebu';

    final originLabel = widget.origin != null
        ? (widget.origin!['description'] ?? widget.origin!['name'] ?? 'Origin')
        : 'Filinvest Cyberzone Cebu Tower one';

    return Scaffold(
      backgroundColor: const Color(0xFF3C3F42), // dark outer area like screenshot
      body: SafeArea(
        child: Column(
          children: [
            // white card area
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
                  // use passed labels
                  _HeaderChips(
                    originLabel: originLabel,
                    destLabel: destLabel,
                  ),
                  const SizedBox(height: 12),
                  _SortRow(
                    sortBy: _sortBy,
                    onChanged: (s) => setState(() => _sortBy = s),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 420, // limit area for list in the white card
                    child: ListView.separated(
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
  const _HeaderChips({this.originLabel = 'Filinvest Cyberzone Cebu Tower one', this.destLabel = 'SM City Cebu'});

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
  final List<String> legs; // simple labels like 'walk','jeep','bus'

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
        // navigate to details or do action
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
                        const SizedBox(width: 6),
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
                Text('Total Fare: ${option.totalFare} php',
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