import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _previousIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationController.forward().then((_) => _animationController.reverse());
      _previousIndex = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Blue color scheme
    final Color navBarColor = isDarkMode 
        ? const Color(0xFF1A2332)
        : const Color(0xFF4A6FA5);
    final Color iconColor = isDarkMode 
        ? Colors.blue[200]!.withOpacity(0.6)
        : Colors.white.withOpacity(0.7);
    final Color selectedIconColor = isDarkMode 
        ? Colors.lightBlueAccent
        : Colors.white;
    final Color indicatorColor = isDarkMode
        ? Colors.lightBlueAccent.withOpacity(0.2)
        : Colors.white.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        color: navBarColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -2),
            color: isDarkMode ? Colors.black45 : Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  isSelected: widget.selectedIndex == 0,
                  iconColor: iconColor,
                  selectedColor: selectedIconColor,
                  indicatorColor: indicatorColor,
                  onTap: () {
                    widget.onItemTapped(0);
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  index: 1,
                  isSelected: widget.selectedIndex == 1,
                  iconColor: iconColor,
                  selectedColor: selectedIconColor,
                  indicatorColor: indicatorColor,
                  onTap: () {
                    widget.onItemTapped(1);
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 2,
                  isSelected: widget.selectedIndex == 2,
                  iconColor: iconColor,
                  selectedColor: selectedIconColor,
                  indicatorColor: indicatorColor,
                  onTap: () {
                    widget.onItemTapped(2);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required Color iconColor,
    required Color selectedColor,
    required Color indicatorColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? indicatorColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? selectedColor : iconColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : iconColor,
                  height: 1.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}