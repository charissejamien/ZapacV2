import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServicePage extends StatelessWidget {
  final String onlineUrl;

  const TermsOfServicePage({super.key, this.onlineUrl = 'https://zapac.ph/terms'});

  Future<void> _openOnline(BuildContext context) async {
    final uri = Uri.parse(onlineUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open terms URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: cs.primary,
        iconTheme: IconThemeData(color: cs.onPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('Terms of Service', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 12),
            Text(
              'These Terms of Service govern your use of the Zapac app. Replace this placeholder with the full '
              'terms covering acceptable use, limitations of liability, dispute resolution, and other legal points.',
              style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 18),
            Text('User Responsibilities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              '- Provide accurate information when required\n'
              '- Respect other users and community guidelines\n'
              '- Do not attempt to reverse engineer the app\n\n'
              'Replace with your official terms.',
              style: TextStyle(color: cs.onSurface.withOpacity(0.85)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openOnline(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View full terms online'),
            ),
            const SizedBox(height: 40),
            Text('Effective date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text('These terms are effective as of the date of application release.', style: TextStyle(color: cs.onSurface.withOpacity(0.85))),
          ]),
        ),
      ),
    );
  }
}