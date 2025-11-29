import 'package:flutter/material.dart';

class OnboardingHeader extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingHeader({super.key});

  // Color matching the one used in your LoginPage/AuthFooter
  final Color headerColor = const Color(0xFF4A6FA5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(60), // Rounded bottom edges
          bottomRight: Radius.circular(60),
        ),
      ),
      // SafeArea is included for consistent padding on modern devices
      child: const SafeArea(
        // The container is empty to ensure a plain look
        child: SizedBox.expand(), 
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0); // Define a fixed height for the header
}