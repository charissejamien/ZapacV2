import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy.dart';
import 'terms_of_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Zapac', 
        style:TextStyle(color: Colors.white)),
        backgroundColor: cs.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- App Icon/Logo Placeholder ---
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Icon(
                  Icons.near_me_rounded, 
                  size: 80, 
                  color: cs.primary,
                ),
              ),
            ),
            
            // --- Mission/Vision ---
            Text(
              'Your Guide to Cebuano Transit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Zapac aims to make navigating Cebu's public and private transportation simple, safe, and community-driven. We provide real-time routes, accurate fare estimates, and crowdsourced insights to help commuters move smarter across the city.",
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 16),
            
            // --- App Info ---
            _buildInfoTile(
              context, 
              title: 'Version', 
              subtitle: '1.0.0 (Build 42)',
              icon: Icons.code_rounded,
            ),
            _buildInfoTile(
              context, 
              title: 'Region', 
              subtitle: 'Cebu, Philippines',
              icon: Icons.location_city_rounded,
            ),
            
            const SizedBox(height: 24),

            // --- Legal Section ---
            Text(
              'Legal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegalTile(
              context,
              title: 'Privacy Policy',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
            ),
            _buildLegalTile(
              context,
              title: 'Terms of Service',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              ),
            ),
            _buildLegalTile(
              context,
              title: 'Licenses',
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Zapac',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(Icons.near_me_rounded, color: cs.primary),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper for static info tiles
  Widget _buildInfoTile(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.secondary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for legal link tiles
  Widget _buildLegalTile(BuildContext context, {required String title, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.gavel_rounded, color: cs.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: cs.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.4)),
      onTap: onTap,
    );
  }
  
  // Placeholder launch URL function
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // In a real app, this should display a ScaffoldMessenger error.
      // For this context, a placeholder print is used.
      print('Could not launch $url'); 
    }
  }
}