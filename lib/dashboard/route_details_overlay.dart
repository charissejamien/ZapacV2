import 'package:flutter/material.dart';

class RouteDetailsOverlay extends StatelessWidget {
  final String destinationName;
  final String distance;
  final String duration;
  final VoidCallback onClose;

  const RouteDetailsOverlay({
    super.key,
    required this.destinationName,
    required this.distance,
    required this.duration,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 350, // Increased width
          padding: const EdgeInsets.all(25), // Increased padding
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route Details',
                    style: TextStyle(
                      fontSize: 20, // Slightly larger title
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 15, thickness: 1),
              _buildDetailRow(
                icon: Icons.my_location,
                label: 'Start:',
                value: 'Your Current Location',
                color: colorScheme.secondary,
                isDestination: false,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.flag,
                label: 'Destination:',
                value: destinationName,
                color: colorScheme.error,
                isDestination: true, // Mark this row for special text handling
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                icon: Icons.social_distance,
                label: 'Distance:',
                value: distance,
                color: colorScheme.onSurface,
                isDestination: false,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.timer,
                label: 'Duration:',
                value: duration,
                color: colorScheme.onSurface,
                isDestination: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDestination,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color.withAlpha(179)),
            ),
            // FIX: Use a ConstrainedBox with Text wrapping for long destination names
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color),
                softWrap: true, // Key to fixing overflow
              ),
            ),
          ],
        ),
      ],
    );
  }
}