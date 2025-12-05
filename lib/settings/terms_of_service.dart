import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {

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
Align(
              alignment: Alignment.center,
              child: Image(image: const AssetImage('assets/van.png'), 
              width: 150,)
            ),
            const SizedBox(height: 20),
            Text('ZAPAC TERMS OF SERVICE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(
              'Last Updated: December 4, 2025',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: cs.onSurface.withOpacity(0.8)),
            ),
            const SizedBox(height: 25),
            Text(
              'These Terms of Service govern your access to and use of Zapac. By using the App, you agree to these Terms. If you do not agree, please discontinue use.',
              style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
            ),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 18),
            Text(
              '1. Use of the App',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('You must use Zapac in accordance with:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'These Terms',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Applicable Laws',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Google/Apple developers policies',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Divider(height: 32, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 18),
            Text(
              '2. Account Responsibilities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('You are responsible for:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Keepong your login credentials secure',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Providing accurate information',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Not sharing your account with others',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('We may suspend or terminated accounts that violate these Terms.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '3. App Functionality & Limitations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('Zapac provides transit directions based on available data sources (e.g., Google Maps API). We do not guarantee:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    '100% accuracy of routing information',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Real-time availability of public transportation',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Error-free or uninterrupted service',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Users rely on the app at their own discretion.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '4. Acceptable Use',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('You agree not to:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Use the app for unlawful activities',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Input harmful or malicious content',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
                        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Interfere with servers or networks',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Attempt unauthorized data extraction or scraping',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Reproduce or distribute app content without permission',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '5. Intellectual Property',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('All content, design, logos, and features of Zapac belong to Zapac and are protected by copyright and trademark laws.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text('You may not copy, modify, distribute, or create derivative works without written consent.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '6. Third-Party Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('Zapac uses external services such as:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Google Maps Platform',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Firebase Authentication',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Firebase Database',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Your use of the app is also subject to those third parties’ terms and privacy policies.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '5. ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text('Your use of the app is also subject to those third parties’ terms and privacy policies.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '7. Disclaimer of Warranties',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('Zapac is provided “as is” and “as available” without warranties of any kind. We disclaim responsibility for:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Incorrect route results',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Transit delays or service interruptions',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Losses resulting from reliance on the app',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Use the app at your own risk.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '8. Limitation of Liability',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('To the fullest extent permitted by law:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Zapac is not liable for indirect, incidental, or consequential damages.',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '9. Termination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('We may suspend or terminate access for:',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Violations of these Terms',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Fraudulent activity',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20),
                Text('\u2022   ', style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),),
                Expanded(
                  child: Text(
                    'Abuse or misuse of the service',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Users may stop using the app at any time.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '10. Governing Law',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('These Terms are governed by the laws of the Philippines. Any disputes will be handled by competent courts in that jurisdiction.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text('',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '11. Changes to These Terms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('We may modify these Terms from time to time. Continued use of the app means you accept the updated Terms.',
            style: TextStyle(fontSize: 15, color: cs.onSurface),),
            const SizedBox(height: 10),
            Text(
              '12. Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text('If you have questions or concerns about this Terms, contact:',
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