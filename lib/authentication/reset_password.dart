import 'dart:math';
import 'package:flutter/material.dart';
import 'verify_code.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailController = TextEditingController();
  bool _isLoading = false;

  void _sendCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate sending a 6-digit code
    final random = Random();
    final code = (random.nextInt(900000) + 100000).toString();

    await Future.delayed(const Duration(seconds: 2)); // simulate network delay

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('A verification code was sent to $email')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyCodePage(email: email, sentCode: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color(0xFF5072A7);
    final greenColor = const Color(0xFF6CA89A);
    final beigeColor = const Color(0xFFF9F9F9);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password?"),
        backgroundColor: blueColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Enter the email associated with your account and we'll send a code to reset your password.",
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 30),
            const Text("Email", style: TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: beigeColor,
                hintText: "Enter your email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send Code",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
