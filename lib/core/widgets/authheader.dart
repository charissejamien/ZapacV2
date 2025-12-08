import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isSignUp;
  final VoidCallback onSwitchTap;

  const AuthHeader({
    super.key,
    required this.isSignUp,
    required this.onSwitchTap,
  });

  final Color appBarColor = const Color(0xFF4A6FA5);
  final String logoImage = 'assets/Logo.png';

  @override
  Size get preferredSize => const Size.fromHeight(180);

  @override
  Widget build(BuildContext context) {
    final height = preferredSize.height;
    final width = MediaQuery.of(context).size.width;

    final logoHeight = height * 0.5; // 50% of appBar height
    final tabFontSize = height * 0.09; // scale tab text
    final underlineWidth = width * 0.15; // scale tab underline
    final spacingBetweenTabs = width * 0.07;

    Widget _buildTab(String text, bool isActive) {
      final activeColor = Colors.white;
      final inactiveColor = Colors.white.withAlpha(217);

      return GestureDetector(
        onTap: () {
          if (!isActive) onSwitchTap();
        },
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: tabFontSize,
              ),
            ),
            Container(
              width: underlineWidth,
              height: 1.2,
              color: isActive ? activeColor : Colors.transparent,
              margin: const EdgeInsets.only(top: 6),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(60),
        bottomRight: Radius.circular(60),
      ),
      child: AppBar(
        backgroundColor: appBarColor,
        automaticallyImplyLeading: false,
        toolbarHeight: height,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: height * 0.06),
            Image.asset(
              logoImage,
              height: logoHeight,
              fit: BoxFit.contain,
            ),
            SizedBox(height: height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab("Sign Up", isSignUp),
                SizedBox(width: spacingBetweenTabs),
                _buildTab("Log In", !isSignUp),
              ],
            ),
            SizedBox(height: height * 0.02),
          ],
        ),
      ),
    );
  }
}
