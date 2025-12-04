import 'package:flutter/material.dart';

class FloatingButton extends StatelessWidget {
  final bool isCommunityInsightExpanded;
  // REQUIRED: Added the required parameter
  final bool isShowingTerminals; 
  final VoidCallback onAddInsightPressed;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onTerminalPressed;

  const FloatingButton({
    super.key,
    required this.isCommunityInsightExpanded,
    // REQUIRED: The fix for the error in the Dashboard instantiation
    required this.isShowingTerminals, 
    required this.onAddInsightPressed,
    required this.onMyLocationPressed,
    required this.onTerminalPressed,
  });

  // Helper for the standard FAB design
  Widget _buildActionButton({
    required BuildContext context,
    required String heroTag,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4E7D71)
        : const Color(0xFF6CA89A);

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: backgroundColor, 
      foregroundColor: Colors.white,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // HIDE FAB: If the sheet is expanded AND showing terminals.
    if (isCommunityInsightExpanded && isShowingTerminals) {
        return const SizedBox.shrink(); 
    }
    
    if (isCommunityInsightExpanded) {
      // Show ADD INSIGHT FAB only if NOT showing terminals
      return _buildActionButton(
        context: context,
        heroTag: 'add_insight',
        onPressed: onAddInsightPressed,
        icon: Icons.add,
      );
    } else {
      // State 2: Sheet Collapsed (Show MY LOCATION and TERMINAL buttons)
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Terminal Button 
          _buildActionButton(
            context: context,
            heroTag: 'show_terminals',
            onPressed: onTerminalPressed,
            icon: Icons.directions_bus,
          ),
          const SizedBox(height: 10), 
          // Existing My Location Button
          _buildActionButton(
            context: context,
            heroTag: 'my_location',
            onPressed: onMyLocationPressed,
            icon: Icons.my_location,
          ),
        ],
      );
    }
  }
}