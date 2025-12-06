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

  static const Color _red = Colors.red;
  static const double _borderWidth = 1.5;
  static const Color _googleBgDark = Color.fromARGB(255, 24, 24, 24);

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

  // --- VALIDATION LOGIC ---
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
        _passwordHintColor = Colors.green;
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
        _confirmHintColor = Colors.green;
      } else {
        _confirmHint = 'Passwords do not match.';
        _confirmHintColor = _red;
      }
    });
  }

  // --- ACTIONS ---
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
                Icon(Icons.check_circle, color: _green, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "Sign up successful! Please check your email inbox to verify your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Log In",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
      if (cred != null && mounted) {
        _showSuccessDialog();
      }
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool disableEmailPassSignup = _isLoading || _isGoogleLoading;
    
    final socialButtonBgColor = isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor;

    return Scaffold(
      // CRITICAL: This ensures the layout is static and doesn't scroll when keyboard opens
      resizeToAvoidBottomInset: false, 
      appBar: AuthHeader(
        isSignUp: true,
        onSwitchTap: _navigateToLogin,
      ),
      
      // Changed from ListView to Column for a non-scrollable layout
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            // Use MainAxisAlignment to distribute space evenly
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Header
              Center(
                child: Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
              
              // Form Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inputField(
                    label: 'Email',
                    controller: _emailCtrl,
                    isPassword: false,
                    hintTextBelow: _emailError,
                    hintColorBelow: _emailError != null ? _red : Colors.transparent,
                  ),
                  const SizedBox(height: 16),
                  
                  _inputField(
                    label: 'Password',
                    controller: _passwordCtrl,
                    isPassword: true,
                    hintTextBelow: _passwordHint,
                    hintColorBelow: _passwordHintColor,
                  ),
                  const SizedBox(height: 16),
                  
                  _inputField(
                    label: 'Confirm Password',
                    controller: _confirmCtrl,
                    isPassword: true,
                    hintTextBelow: _confirmHint,
                    hintColorBelow: _confirmHintColor,
                  ),
                ],
              ),

              // Error & Button Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (_generalError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _generalError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _red, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: disableEmailPassSignup ? null : _onSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                          : const Text(
                              "Sign Up",
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),

              // Footer Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dividerWithText("or sign in with"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 50,
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
              
              // Small spacer at bottom to keep it off the wave
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 75,
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

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    String? hintTextBelow,
    Color hintColorBelow = Colors.transparent,
  }) {
    Color borderColor;

    if (controller == _emailCtrl) {
      if (_emailError == null && controller.text.isNotEmpty) {
        borderColor = _green;
      } else {
        borderColor = _emailError != null ? _red : Colors.transparent;
      }
    } else if (isPassword) {
      if (hintColorBelow == _red) {
        borderColor = _red;
      } else if (hintColorBelow == Colors.green) {
        borderColor = _green;
      } else {
        borderColor = Colors.transparent;
      }
    } else {
      borderColor = Colors.transparent;
    }

    Color focusedBorderColor = borderColor == Colors.transparent 
        ? (hintColorBelow == _red ? _red : _green) 
        : borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword
              ? (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm)
              : false,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: _beige,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: _borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: focusedBorderColor, width: _borderWidth),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[700],
                      size: 22,
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
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6.0, top: 4.0),
          child: Text(
            hintTextBelow ?? '',
            style: TextStyle(
              fontSize: 12, 
              color: hintColorBelow == Colors.transparent ? Colors.grey : hintColorBelow,
              fontWeight: FontWeight.w500
            ),
          ),
        ),
      ],
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
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  Widget _dividerWithText(String text) {
    return Row(children: [
      const Expanded(child: Divider(thickness: 1, endIndent: 12)),
      Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      const Expanded(child: Divider(thickness: 1, indent: 12)),
    ]);
  }
}