import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_page.dart';
import 'authentication.dart';
import 'package:zapac/core/widgets/authheader.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  String? _emailError;
  String? _passwordHint;
  Color _passwordHintColor = Colors.transparent;
  String? _confirmHint;
  Color _confirmHintColor = Colors.transparent;
  String? _generalError;

  final Color _green = const Color(0xFF6CA89A);
  final Color _beige = const Color(0xFFF3EEE6);
  final Color _red = Colors.red;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_validateEmail);
    _passwordCtrl.addListener(_validatePassword);
    _confirmCtrl.addListener(_validateConfirm);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final txt = _emailCtrl.text.trim();
    setState(() {
      if (txt.isEmpty) {
        _emailError = null;
      } else {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        _emailError = emailRegex.hasMatch(txt) ? null : 'Please enter a valid email address.';
      }
    });
  }

  void _validatePassword() {
    final pw = _passwordCtrl.text;
    setState(() {
      if (pw.isEmpty) {
        _passwordHint = 'Must be at least 8 characters.';
        _passwordHintColor = Colors.grey;
      } else if (pw.length < 8) {
        _passwordHint = 'Password must be at least 8 characters.';
        _passwordHintColor = _red;
      } else {
        _passwordHint = 'Password looks good!';
        _passwordHintColor = _green;
      }
      _validateConfirm();
    });
  }

  void _validateConfirm() {
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    setState(() {
      if (confirm.isEmpty) {
        _confirmHint = 'Both passwords must match.';
        _confirmHintColor = Colors.grey;
      } else if (pw == confirm) {
        _confirmHint = 'Passwords match!';
        _confirmHintColor = _green;
      } else {
        _confirmHint = 'Passwords do not match.';
        _confirmHintColor = _red;
      }
    });
  }

  Future<void> _onSignUp() async {
    setState(() => _generalError = null);
    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pw.isEmpty || confirm.isEmpty) {
      setState(() => _generalError = 'All fields must be filled.');
      return;
    }
    if (_emailError != null) {
      setState(() => _generalError = _emailError);
      return;
    }
    if (pw.length < 8) {
      setState(() => _generalError = 'Password must be at least 8 characters long.');
      return;
    }
    if (pw != confirm) {
      setState(() => _generalError = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await AuthService().signUpWithEmail(email, pw);
      if (cred != null && mounted) _showSuccessDialog();
    } catch (e) {
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _generalError = null;
    });
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const LoginPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final height = media.size.height;
    final width = media.size.width;

    final disableEmailPassSignup = _isLoading || _isGoogleLoading;
    final socialButtonBgColor = isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AuthHeader(
        isSignUp: true,
        onSwitchTap: _navigateToLogin,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: height * 0.035,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
              // Form Fields
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _responsiveTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    screenHeight: height,
                    screenWidth: width,
                    errorText: _emailError,
                  ),
                  SizedBox(height: height * 0.02),
                  _responsiveTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    screenHeight: height,
                    screenWidth: width,
                    isPassword: true,
                    errorText: _passwordHint,
                    hintColor: _passwordHintColor,
                  ),
                  SizedBox(height: height * 0.02),
                  _responsiveTextField(
                    controller: _confirmCtrl,
                    label: 'Confirm Password',
                    screenHeight: height,
                    screenWidth: width,
                    isPassword: true,
                    errorText: _confirmHint,
                    hintColor: _confirmHintColor,
                  ),
                ],
              ),
              // Error and Button Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_generalError != null)
                    Container(
                      margin: EdgeInsets.only(bottom: height * 0.01),
                      padding: EdgeInsets.all(width * 0.02),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _generalError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w500,
                          fontSize: height * 0.015,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: disableEmailPassSignup ? null : _onSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: height * 0.025,
                              width: height * 0.025,
                              child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                            )
                          : Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: height * 0.01726,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              // Footer Social Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dividerWithText("or sign in with", width, height),
                  SizedBox(height: height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: width * 0.6,
                        height: height * 0.065,
                        child: _socialBtn(
                          icon: Icons.g_mobiledata,
                          label: "Google",
                          bg: socialButtonBgColor == theme.scaffoldBackgroundColor
                              ? const Color.fromARGB(255, 24, 24, 24)
                              : socialButtonBgColor,
                          iconColor: Colors.white,
                          textColor: Colors.white,
                          onPressed: _isGoogleLoading ? () {} : _onGoogle,
                          isLoading: _isGoogleLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: height * 0.01),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: height * 0.09,
        decoration: const BoxDecoration(
          color: Color(0xFF4A6FA5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
        ),
      ),
    );
  }

  // Responsive Text Field with floating label
  Widget _responsiveTextField({
    required TextEditingController controller,
    required String label,
    required double screenHeight,
    required double screenWidth,
    bool isPassword = false,
    String? errorText,
    Color hintColor = Colors.transparent,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm) : false,
      style: TextStyle(fontSize: screenHeight * 0.02, color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: _beige,
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(fontSize: screenHeight * 0.018, color: Colors.grey[700]),
        hintStyle: TextStyle(fontSize: screenHeight * 0.018, color: Colors.black54),
        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.022),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: hintColor == _red ? _red : Colors.transparent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: hintColor == _red ? _red : _green, width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey[700],
                  size: screenHeight * 0.025,
                ),
                onPressed: () {
                  setState(() {
                    if (controller == _passwordCtrl) {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirm = !_obscureConfirm;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Icon(icon, color: iconColor, size: 24),
      label: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
    );
  }

  Widget _dividerWithText(String text, double width, double height) {
    return Row(children: [
      Expanded(child: Divider(thickness: 1, endIndent: width * 0.03)),
      Text(text, style: TextStyle(fontSize: height * 0.016, color: Colors.grey)),
      Expanded(child: Divider(thickness: 1, indent: width * 0.03)),
    ]);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(51),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: _green, size: MediaQuery.of(context).size.height * 0.08),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  "Sign up successful! Please check your email inbox to verify your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.018, color: Colors.black87),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.018),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
