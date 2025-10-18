import 'package:flutter/material.dart';
import 'package:zapac/core/widgets/bottomNavBar.dart';
import 'package:zapac/dashboard/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/authentication/login_page.dart';
import 'package:zapac/app/main.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? _currentUser;
  String _initials = '';
  String _displayName = 'New User';
  String _userEmail = 'newzapacuser@example.com';
  static const String _userStatus = 'Daily Commuter';
  static const Color primaryColor = Color(0xFF4A6FA5);
  static const Color greenButtonColor = Color(0xFF6CA89A);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    _userEmail = _currentUser?.email ?? 'N/A';
    _displayName = _currentUser?.displayName ?? _userEmail.split('@').first;
    if (_displayName.isEmpty) {
        _displayName = 'Welcome User';
    }
    if (_displayName.isNotEmpty) {
      _initials = _displayName[0].toUpperCase();
    }
    if (mounted) setState(() {});
  }

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

  Widget _buildResponsiveSettingsList() {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSettingsTile(
              title: 'Dark Mode',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
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
            _buildSettingsTile(
              title: 'Logout',
              onTap: () {
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

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: _currentUser?.photoURL != null
          ? CircleAvatar(
              radius: 38,
              backgroundImage: NetworkImage(_currentUser!.photoURL!),
            )
          : CircleAvatar(
              radius: 38,
              backgroundColor: primaryColor,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildProfileAvatar(),
                const SizedBox(height: 10),
                Text(
                  _displayName,
                  style: const TextStyle(
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
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          } else if (index == 1) {
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
