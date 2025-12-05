import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {

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
            Align(
              alignment: Alignment.center,
              child: Image(image: const AssetImage('assets/van.png'), 
              width: 150,)
            ),
            const SizedBox(height: 20),
            Text('ZAPAC PRIVACY POLICY', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: cs.onSurface)),
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
              '1. Information We Collect',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('1.1 Information You Provide',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Account Information: Name, email address, phone number, or other details when you create an account (if applicable).',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Feedback and Support: Information you provide when you contact support or submit feedback.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('1.2 Information Collected Automatically',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Location Data: Precise or approximate location to determine available routes and transit directions.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Device Information: Device model, OS version, app version, unique identifiers, language settings.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
             Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Usage Data: App interactions, search history, selected routes, crash reports, performance logs.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
             Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Cookies or Similar Technologies: Used to remember preferences and enhance functionality.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('1.3 Information from Third-Party Services',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Google Maps Platform Services: We may receive geolocation, mapping, and routing information from Google Maps APIs.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('We use collected information to:',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Provide transit directions and route recommendations',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Improve accuracy of directions and app performance',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Maintain and secure app functionality',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Send app updates, announcements, or service-related messages',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Analyze usage trends to enhance user experience',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Comply with legal and security requirements',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
             const SizedBox(height: 10),
            Text('We do not sell your personal data.',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              '3. Changes to This Privacy Policy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('We may update this policy from time to time. The updated version will be posted in-app',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 10),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              '4. Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('If you have questions or concerns about this Privacy Policy, contact:',
            style: TextStyle(fontSize: 17, color: cs.onSurface),),
            const SizedBox(height: 15),
            Text('📧: developers@zapac.com'),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}