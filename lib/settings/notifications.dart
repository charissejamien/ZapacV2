import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // State variables matching the image
  bool _showNotifications = true;
  bool _showAppIconBadges = true;
  bool _floatingNotifications = true;
  bool _lockScreenNotifications = true;
  bool _allowSound = true;
  bool _allowVibration = true;
  bool _allowLedLight = false;

  // The primary accent color from your Settings Page
  final Color _accentGreen = const Color(0xFF6CA89A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- MASTER SWITCH ---
          _buildSectionHeader('GENERAL'),
          _buildSwitchTile(
            title: 'Show notifications',
            icon: Icons.notifications_active_rounded,
            value: _showNotifications,
            onChanged: (v) => setState(() => _showNotifications = v),
          ),

          const SizedBox(height: 16),

          // --- BEHAVIOR ---
          _buildSectionHeader('BEHAVIOR'),
          
          _buildSwitchTile(
            title: 'Show app icon badges',
            icon: Icons.markunread_mailbox_rounded,
            value: _showAppIconBadges,
            onChanged: (v) => setState(() => _showAppIconBadges = v),
            enabled: _showNotifications,
          ),
          
          _buildSwitchTile(
            title: 'Floating notifications',
            subtitle: 'Allow floating notifications',
            icon: Icons.picture_in_picture_alt_rounded,
            value: _floatingNotifications,
            onChanged: (v) => setState(() => _floatingNotifications = v),
            enabled: _showNotifications,
          ),

          _buildSwitchTile(
            title: 'Lock screen notifications',
            subtitle: 'Allow notifications on the Lock screen',
            icon: Icons.screen_lock_portrait_rounded,
            value: _lockScreenNotifications,
            onChanged: (v) => setState(() => _lockScreenNotifications = v),
            enabled: _showNotifications,
          ),

          const SizedBox(height: 16),

          // --- ALERTS ---
          _buildSectionHeader('ALERTS'),
          
          _buildSwitchTile(
            title: 'Allow sound',
            icon: Icons.volume_up_rounded,
            value: _allowSound,
            onChanged: (v) => setState(() => _allowSound = v),
            enabled: _showNotifications,
          ),

          _buildSwitchTile(
            title: 'Allow vibration',
            icon: Icons.vibration_rounded,
            value: _allowVibration,
            onChanged: (v) => setState(() => _allowVibration = v),
            enabled: _showNotifications,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Dim the tile if disabled (when master switch is off)
    final double opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accentGreen, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: subtitle != null 
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13, 
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)
                )
              ) 
            : null,
          trailing: Switch(
            value: value,
            onChanged: enabled ? (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            } : null,
            activeColor: _accentGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5).withOpacity(0.1), // Blue-ish for navigation items
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF4A6FA5), size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.iconTheme.color?.withOpacity(0.5),
        ),
      ),
    );
  }
}