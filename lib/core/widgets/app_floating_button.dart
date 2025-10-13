import 'package:flutter/material.dart';

class FloatingButton extends StatelessWidget {
  final bool isCommunityInsightExpanded;
  final VoidCallback onAddInsightPressed;
  final VoidCallback onMyLocationPressed;

  const FloatingButton({
    super.key,
    required this.isCommunityInsightExpanded,
    required this.onAddInsightPressed,
    required this.onMyLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color based on theme
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4E7D71)
        : const Color(0xFF6CA89A);

    return FloatingActionButton(
      onPressed: isCommunityInsightExpanded
          ? onAddInsightPressed
          : onMyLocationPressed,
      backgroundColor: backgroundColor,
      heroTag: isCommunityInsightExpanded ? 'addInsightBtn' : 'myLocationBtn',
      child: Icon(
        isCommunityInsightExpanded ? Icons.add : Icons.my_location,
        color: Colors.white,
        size: isCommunityInsightExpanded ? 30 : 24,
      ),
    );
  }
}
