import 'package:flutter/material.dart';
import 'new_password.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final String sentCode;

  const VerifyCodePage({super.key, required this.email, required this.sentCode});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final codeController = TextEditingController();

  void _verifyCode() {
    if (codeController.text.trim() == widget.sentCode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordPage(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color(0xFF5072A7);
    final greenColor = const Color(0xFF6CA89A);
    final beigeColor = const Color(0xFFF9F9F9);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Code"),
        backgroundColor: blueColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              "Enter the 6-digit code sent to\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: codeController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: beigeColor,
                hintText: "Enter code",
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
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Verify",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
