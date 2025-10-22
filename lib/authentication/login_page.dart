import 'package:flutter/material.dart';
import 'package:zapac/authentication/authentication.dart';
import 'package:zapac/dashboard/dashboard.dart';
import 'reset_password_page.dart';
import 'signup_page.dart';
import 'package:zapac/core/widgets/authheader.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final blueColor = const Color(0xFF5072A7);
  final greenColor = const Color(0xFF6CA89A);
  final beigeColor = const Color(0xFFF9F9F9);

  final appBarColor = const Color(0xFF4A6FA5);

  void _setLocalError(String message) {
      if (mounted) {
        setState(() {
          _errorMessage = message;
          if (_isLoading) _isLoading = false;
        });
      }
  }

  Future<void> _onGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
      }
    } catch (e) {
      String message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Google sign-in failed')) {
          _setLocalError('Google sign-in failed. Please try again.');
      } else {
          _setLocalError(message);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (email.isEmpty && password.isEmpty) {
      _setLocalError('Please enter email and password.');
      return;
    }
    if (email.isEmpty) {
      _setLocalError('Please enter your email to login.');
      return;
    }
    if (password.isEmpty) {
      _setLocalError('Please enter your password to login.');
      return;
    }

    try {
      await _authService.signInWithEmail(email, password);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } catch (e) {
      String message = 'Invalid email or password. Please try again.';
      _setLocalError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

   void _navigateToSignUp() {
  Navigator.pushReplacement(
    context, 
    PageRouteBuilder(
      pageBuilder: (context, animation1, animation2_) => const SignUpPage(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    )
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final socialButtonBgColor = isDarkMode
        ? theme.cardColor
        : theme.scaffoldBackgroundColor;

    final socialButtonFgColor = isDarkMode
        ? Colors.white
        : Colors.black;

    return Scaffold(
      resizeToAvoidBottomInset: true,

     // INSERT THIS:

      appBar: 
      AuthHeader(
        isSignUp: false,
        onSwitchTap: _navigateToSignUp,
      ),

      body: ListView(
        children: [
          const SizedBox(height: 25),
          Center(
            child: Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: greenColor,
              ),
            ),
          ),
          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(" Email", style: TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                _buildTextField(emailController, ""),
                const SizedBox(height: 30),
                const Text(" Password", style: TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                _buildTextField(passwordController, "", isPassword: true),
                const SizedBox(height: 10),

                SizedBox(
                  height: 35,
                  child: Center(
                    child: _errorMessage != null
                        ? Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Container(),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Forgotten your password? ", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Reset password",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _dividerWithText("or sign in with"),
                const SizedBox(height: 20),
                _buildSocialButtons(socialButtonBgColor, socialButtonFgColor, _isGoogleLoading),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: appBarColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,

      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3EEE6),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  Widget _dividerWithText(String text) {
    return Row(children: [
      const Expanded(child: Divider(thickness: 1, endIndent: 10)),
      Text(text, style: const TextStyle(fontSize: 13)),
      const Expanded(child: Divider(thickness: 1, indent: 10)),
    ]);
  }

  Widget _buildSocialButtons(Color darkBgColor, Color darkFgColor, bool isGoogleLoading) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final googleBgLight = isDarkMode ? darkBgColor : const Color.fromARGB(255, 24, 24, 24);
    final googleFgLight = isDarkMode ? darkFgColor : Colors.white;

    final facebookBgLight = isDarkMode ? darkBgColor : Theme.of(context).scaffoldBackgroundColor;
    final facebookFgLight = isDarkMode ? darkFgColor : Colors.black;
    final isFacebookLoading = false;
    final bool disableFacebook = isGoogleLoading;


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: screenWidth * 0.42,
          child: _socialButton(
            Icons.g_mobiledata,
            "Google",
            googleBgLight,
            googleFgLight,
            googleFgLight,
            isGoogleLoading,
            _onGoogleLogin,
          ),
        ),
        SizedBox(
          width: screenWidth * 0.42,
          child: _socialButton(
            Icons.facebook,
            "Facebook",
            facebookBgLight,
            isDarkMode ? darkFgColor : Colors.blue,
            facebookFgLight,
            isFacebookLoading,
            disableFacebook ? () {} : () {},
          ),
        ),
      ],
    );
  }

  Widget _socialButton(
      IconData icon, String text, Color bgColor, Color iconColor, Color textColor, bool isLoading, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(icon, color: iconColor, size: 20),
      label: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
    );
  }
}
