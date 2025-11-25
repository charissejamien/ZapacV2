import 'package:flutter/material.dart';
import 'package:zapac/app/app_theme.dart';
import 'package:zapac/authentication/login_page.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final String sentCode;

  const VerifyCodePage({
    super.key,
    required this.email,
    required this.sentCode,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.colors.blue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50.0),
          bottomRight: Radius.circular(50.0),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 80, 
        decoration: BoxDecoration(
          color: AppTheme.colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50.0),
            topRight: Radius.circular(50.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 30),

                      Text(
                        "Verification Sent!",
                        style: TextStyle(
                          color: AppTheme.colors.green,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),

                      // Description Message
                      Text(
                        "A password reset link has been sent to ${widget.email}. Please check your email inbox (and spam folder) to continue.",
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 60),

                      // Back to Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false, 
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colors.blue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Back to Login",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }
}