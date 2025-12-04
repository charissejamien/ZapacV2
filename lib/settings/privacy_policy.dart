import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String onlineUrl;

  const PrivacyPolicyPage({super.key, this.onlineUrl = 'https://zapac.ph/privacy'});

  Future<void> _openOnline(BuildContext context) async {
    final uri = Uri.parse(onlineUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open privacy URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white),),
        backgroundColor: cs.primary,
        iconTheme: IconThemeData(color: cs.onPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Image(image:  const AssetImage('assets/van.png'), 
              width: 100, height: 80,
            ),
            Text('ZAPAC Privacy Policy', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(
              'Last Updated: December 4, 2025',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: cs.onSurface.withOpacity(0.8)),
            ),
            const SizedBox(height: 25),
            Text(
              'Zapac is a commuter-centered mobile application designed to help users find transit routes and directions to their chosen destinations. We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, store, and protect your data when you use the Zapac app and related services.',
              style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
            ),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 18),
            Text(
              'For the complete privacy policy, please visit our website:',
              style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
            ),
          ]),
        ),
      ),
    );
  }
}