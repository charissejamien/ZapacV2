// auth_header.dart

import 'package:flutter/material.dart';

// The page imports are no longer needed here, preventing the circular dependency.

class AuthHeader extends StatelessWidget implements PreferredSizeWidget {
  
  final bool isSignUp;
  // This is the function passed by the parent page (SignUpPage or LoginPage)
  final VoidCallback onSwitchTap; 

  const AuthHeader({
    super.key, 
    required this.isSignUp,
    required this.onSwitchTap, // 👈 New required parameter
  });

  // Define the common AppBar properties
  final appBarColor = const Color(0xFF4A6FA5);
  final logoImage = 'assets/Logo.png'; 

  @override
  Size get preferredSize => const Size.fromHeight(150);

  // Helper to build the text tabs (Login/Sign Up)
  // 💥 REMOVED 'destinationPage' ARGUMENT 💥
  Widget _buildTab(BuildContext context, {required String text, required bool isActive}) { 
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withOpacity(0.85);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          // Now, we simply call the function passed from the parent widget
          onSwitchTap(); 
        }
      },
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Container(
            width: 48,
            height: 1.2,
            color: isActive ? activeColor : Colors.transparent,
            margin: const EdgeInsets.only(top: 6),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(60),
        bottomRight: Radius.circular(60),
      ),
      child: AppBar(
        backgroundColor: appBarColor,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            Image.asset(logoImage, height: 70),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab(
                  context,
                  text: "Sign Up",
                  isActive: isSignUp, // Active if this is the SignUpPage
                  // 💥 destinationPage is removed here 💥
                ),
                const SizedBox(width: 28),
                _buildTab(
                  context,
                  text: "Log In",
                  isActive: !isSignUp, // Active if this is the LoginPage
                  // 💥 destinationPage is removed here 💥
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}