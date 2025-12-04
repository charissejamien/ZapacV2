import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/authentication/login_page.dart';
import 'package:zapac/app/main.dart';
import 'profile_page.dart';
import 'help_feedback_page.dart';
import 'about_page.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


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
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async { 
    _currentUser = FirebaseAuth.instance.currentUser;
    _userEmail = _currentUser?.email ?? 'N/A';
    _displayName = _currentUser?.displayName ?? _userEmail.split('@').first;
    if (_displayName.isEmpty) {
      _displayName = 'Welcome User';
    }
    if (_displayName.isNotEmpty) {
      _initials = _displayName[0].toUpperCase();
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_pic_path');
    if (savedPath != null && File(savedPath).existsSync()) {
      _profileImageFile = File(savedPath);
    } else {
      _profileImageFile = null;
    }

    if (mounted) setState(() {});
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final tileIconColor = iconColor ?? 
        (isDanger 
            ? Colors.red[400] 
            : (isDarkMode ? Colors.blue[300] : const Color(0xFF4A6FA5)));
    
    final titleColor = isDanger 
        ? Colors.red[400] 
        : theme.textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileIconColor?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: tileIconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded,
          color: theme.iconTheme.color?.withOpacity(0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildResponsiveSettingsList() {
    final greenButtonColor = const Color(0xFF6CA89A);

    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingsSection(
              'PREFERENCES',
              [
                _buildSettingsTile(
                  title: 'Dark Mode',
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeNotifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                    activeColor: greenButtonColor,
                  ),
                ),
                _buildSettingsTile(
                  title: 'Notifications',
                  icon: Icons.notifications_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              'SUPPORT',
              [
                _buildSettingsTile(
                  title: 'Help & Feedback',
                  icon: Icons.help_outline_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpAndFeedbackPage()),
                    );
                  },
                ),
                _buildSettingsTile(
                  title: 'About',
                  icon: Icons.info_outline_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              'ACCOUNT',
              [
                _buildSettingsTile(
                  title: 'Logout',
                  icon: Icons.logout_rounded,
                  isDanger: true,
                  trailing: const SizedBox.shrink(),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[400],
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: _profileImageFile != null
                ? CircleAvatar(
                    radius: 48,
                    backgroundImage: FileImage(_profileImageFile!),
                  )
                : (_currentUser?.photoURL != null
                    ? CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(_currentUser!.photoURL!),
                      )
                    : CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF4A6FA5),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6CA89A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _loadUserData());
              },
              child: _buildProfileAvatar(),
            ),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.commute_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _userStatus,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: _buildResponsiveSettingsList(),
          ),
        ],
      ),
    );
  }
}