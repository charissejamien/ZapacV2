import 'package:flutter/material.dart';
import 'package:zapac/injections/bottomNavBar.dart';
import 'package:zapac/application/dashboard.dart';
import 'package:zapac/authentication/login.dart';
import 'package:zapac/main.dart'; // Needed for themeNotifier
import 'profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User details (made const for optimization)
  static const String _userEmail = 'charisjmn@gmail.com';
  static const String _userName = 'Charisse Jamien T';
  static const String _userStatus = 'Daily Commuter';
  static const String _userProfileImageUrl = 'https://plus.unsplash.com/premium_vector-1744196876628-cdd656d88ed3?q=80&w=880&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D?w=500&h=500&fit=crop';

  static const Color primaryColor = Color(0xFF4A6FA5);
  static const Color greenButtonColor = Color(0xFF6CA89A);

  // Removed empty initState

  // Helper method for the ListTile structure (optimized with local theme access)
  Widget _buildSettingsTile({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
          ),
          trailing: trailing,
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 1, color: Colors.black12),
      ],
    );
  }
  
  // FIX: Extracted the responsive list section into a separate widget
  Widget _buildResponsiveSettingsList() {
    // 1. Use ListenableBuilder to rebuild only the list when themeNotifier changes
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        // 2. Get the current dark mode status inside the builder
        final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSettingsTile(
              title: 'Dark Mode',
              trailing: Switch(
                // 3. The Switch value uses the live state of isDarkMode
                value: isDarkMode,
                onChanged: (value) {
                  // This updates the global notifier, which triggers this builder to run again
                  themeNotifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
                activeColor: greenButtonColor,
              ),
            ),
            _buildSettingsTile(
              title: 'Share our app',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share app functionality coming soon!')),
                );
              },
            ),
            // Logout ListTile
            _buildSettingsTile(
              title: 'Logout',
              onTap: () {
                // Ensure all routes are removed before pushing Login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false, 
                );
              },
              trailing: Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Optimized: Get Theme properties once at the start
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header section (user profile - static, outside the listener)
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  _userEmail,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 15),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(_userProfileImageUrl),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  _userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  _userStatus,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          // Settings options - uses the responsive ListenableBuilder widget
          Expanded(
            child: _buildResponsiveSettingsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          } else if (index == 1) {
            // Placeholder navigation
          } else if (index == 3) {
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}