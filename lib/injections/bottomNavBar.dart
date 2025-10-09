import 'package:flutter/material.dart';
import 'package:zapac/application/dashboard.dart';
// import 'favorite_routes_page.dart';
import 'package:zapac/account/settings.dart';

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

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    // Determine colors based on the current theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors for both modes or use Theme.of(context) directly
    final Color navBarColor = isDarkMode ? Colors.grey[900]! : const Color(0xFF4A6FA5);
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.white;
    final Color selectedIconColor = isDarkMode ? Colors.tealAccent[100]! : Colors.tealAccent[100]!;


    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: navBarColor, // Use theme-dependent color
        boxShadow: [BoxShadow(blurRadius: 4, offset: Offset(0, 4), color: isDarkMode ? Colors.black54 : Colors.black26)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              widget.onItemTapped(0);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );
              }
            },
            child: Icon(
              Icons.home,
              size: 30,
              color: widget.selectedIndex == 0
                  ? selectedIconColor
                  : iconColor,
            ),
          ),
          GestureDetector(
            onTap: () {
              // widget.onItemTapped(1);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const FavoriteRoutesPage()),
              // );
            },
            child: Icon(
              Icons.favorite,
              size: 30,
              color: widget.selectedIndex == 1
                  ? selectedIconColor
                  : iconColor,
            ),
          ),
          GestureDetector(
            onTap: (){
              widget.onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: Icon(
              Icons.menu,
              size: 30,
              color: widget.selectedIndex == 2
                  ? selectedIconColor
                  : iconColor,
            ),
          ),
        ],
      ),
    );
  }
}