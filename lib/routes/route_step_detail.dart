import 'package:flutter/material.dart';
import 'stepDetail.dart';

class RouteStepDetailPage extends StatelessWidget {
  final String originLabel;
  final String destLabel;
  final List<StepDetail> steps;
  final int totalDurationMinutes;
  final String distanceText;

  const RouteStepDetailPage({
    super.key,
    required this.originLabel,
    required this.destLabel,
    required this.steps,
    required this.totalDurationMinutes,
    required this.distanceText,
  });

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$originLabel → $destLabel', style: const TextStyle(fontSize: 14)),
          Text('$distanceText • ${totalDurationMinutes} mins', style: const TextStyle(fontSize: 12)),
        ]),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = steps[i];

          String timeLabel = '';
          if (s.startEpoch != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(s.startEpoch! * 1000);
            timeLabel = TimeOfDay.fromDateTime(dt).format(context);
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
                              Text('${s.transitInfo!['num_stops']} stops',
                                  style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
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
    );
  }
}