import 'package:flutter/material.dart';
import 'package:zapac/authentication/authentication.dart';
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
        _isLoading = false;
        _isGoogleLoading = false;
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
        Navigator.pushReplacementNamed(context, '/onboarding/profile');
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
        Navigator.pushReplacementNamed(context, '/onboarding/profile');
      }
    } catch (e) {
      String message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Invalid email or password') ||
          message.contains('user-not-found')) {
        _setLocalError('Invalid email or password. Please try again.');
      } else {
        _setLocalError(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignUp() {
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2_) =>
              const SignUpPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
  }

  void _navigateToResetPassword() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ResetPasswordPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final socialButtonBgColor =
        isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor;
    final socialButtonFgColor = isDarkMode ? Colors.white : Colors.black;
    final bool disableAll =
        _isLoading || _isGoogleLoading;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AuthHeader(
        isSignUp: false,
        onSwitchTap: _navigateToSignUp,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: maxHeight * 0.02),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: maxHeight * 0.03),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: screenHeight * 0.035,
                      fontWeight: FontWeight.bold,
                      color: greenColor,
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.04),
                  _buildTextField(emailController, "Email",
                      screenHeight, screenWidth),
                  SizedBox(height: maxHeight * 0.03),
                  _buildTextField(passwordController, "Password",
                      screenHeight, screenWidth,
                      isPassword: true),
                  SizedBox(height: maxHeight * 0.015),
                  SizedBox(
                    height: maxHeight * 0.03,
                    child: Center(
                      child: _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: screenHeight * 0.018,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: disableAll ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: screenHeight * 0.025,
                              height: screenHeight * 0.025,
                              child: const CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenHeight * 0.018,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Forgotten your password? ",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: screenHeight * 0.017),
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToResetPassword,
                        child: Text(
                          "Reset password",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: screenHeight * 0.017),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: maxHeight * 0.04),
                  _dividerWithText("or sign in with", screenHeight),
                  SizedBox(height: maxHeight * 0.03),
                  _buildSocialButtons(
                      socialButtonBgColor, socialButtonFgColor, screenHeight),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: screenHeight * 0.1,
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

Widget _buildTextField(
    TextEditingController controller,
    String label,
    double screenHeight,
    double screenWidth, {
    bool isPassword = false,
  }) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword ? _obscurePassword : false,
    style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3EEE6),
      labelText: label, // floating label
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: screenHeight * 0.018,
      ),
      hintStyle: TextStyle(
        color: Colors.black54,
        fontSize: screenHeight * 0.018,
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: screenHeight * 0.025,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.transparent, // no border when not focused
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: const Color(0xFF6CA89A), // highlight color when focused
          width: 2.0,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenHeight * 0.022),
    ),
  );
}


  Widget _dividerWithText(String text, double screenHeight) {
    return Row(children: [
      const Expanded(child: Divider(thickness: 1, endIndent: 12)),
      Text(text,
          style: TextStyle(
            fontSize: screenHeight * 0.016,
            color: Colors.grey,
          )),
      const Expanded(child: Divider(thickness: 1, indent: 12)),
    ]);
  }

  Widget _buildSocialButtons(
      Color darkBgColor, Color darkFgColor, double screenHeight) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final googleBgLight =
        isDarkMode ? darkBgColor : const Color.fromARGB(255, 24, 24, 24);
    final googleFgLight = isDarkMode ? darkFgColor : Colors.white;

    final bool disableSocial = _isLoading || _isGoogleLoading;

    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.065,
      child: _socialButton(Icons.g_mobiledata, "Google", googleBgLight,
          googleFgLight, googleFgLight, _isGoogleLoading,
          disableSocial ? () {} : _onGoogleLogin),
    );
  }

  Widget _socialButton(IconData icon, String text, Color bgColor, Color iconColor,
      Color textColor, bool isLoading, VoidCallback onPressed) {
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
          : Icon(icon, color: iconColor, size: 24),
      label: Text(text,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
    );
  }
}
