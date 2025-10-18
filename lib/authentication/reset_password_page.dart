import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}


class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
  final email = _emailController.text.trim();
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your email')),
    );
    return;
  }

  try {
    print("Sending email: $email");
    final callable = FirebaseFunctions.instance.httpsCallable('sendResetCode');
    final result = await callable.call({'email': email});
    print("Response: ${result.data}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code sent successfully')),
    );
  } catch (e) {
    print('Error sending code: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending code: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password?')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the email associated with your account and we'll send a code to your email to reset your password.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
