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
  final Color _beige = const Color (0xFFF3EEE6);

  static const Color _red = Colors.red;
  static const double _borderWidth = 2.0;
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
        _passwordHintColor = Colors.transparent;
      } else if (pw.length < 8) {
        _passwordHint = 'Password must be at least 8 characters.';
        _passwordHintColor = Colors.red;
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
        _confirmHintColor = Colors.transparent;
      } else if (pw == confirm) {
        _confirmHint = 'Passwords match!';
        _confirmHintColor = Colors.green;
      } else {
        _confirmHint = 'Passwords do not match.';
        _confirmHintColor = Colors.red;
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white, 
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(
                  Icons.check_circle,
                  color: _green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                
                // Success Message
                const Text(
                  "Sign up successful! Please check your email inbox (and spam folder) to verify your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
                
                // Log In Button
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
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold
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

  Future<void> _onSignUp() async {
    setState(() {
      _generalError = null;
    });

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

  // Future<void> _onFacebook() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final user = await AuthService().signInWithFacebook();
  //     if (user != null && mounted) {
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  //     }
  //   } catch (e) {
  //     setState(() => _generalError = e.toString());
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

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

    Color focusedBorderColor;

    if (borderColor == Colors.transparent) {
        focusedBorderColor = _red;
    }
    else if (borderColor == _red) {
        focusedBorderColor = _red;
    }
    else {
        focusedBorderColor = _green;
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          obscureText: isPassword ? (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm) : false,
          decoration: InputDecoration(
            filled: true,
            fillColor: _beige,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        const SizedBox(height: 2),
        SizedBox(
          height: 12,
          child: Text(
            hintTextBelow ?? '',
            style: TextStyle(fontSize: 11.5, color: hintColorBelow),
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
    double width = 150,
    bool isLoading = false,
    bool isGoogle = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color finalBg;
    Color finalIconColor;
    Color finalTextColor;

    if (isGoogle) {
      finalBg = isDarkMode ? Theme.of(context).cardColor : _googleBgDark;
      finalIconColor = Colors.white;
      finalTextColor = Colors.white;
    } else {
      finalBg = isDarkMode ? Theme.of(context).cardColor : Colors.white;
      finalIconColor = isDarkMode ? Colors.white : Colors.blue;
      finalTextColor = isDarkMode ? Colors.white : Colors.black;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: finalBg,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((_) => finalBg),
    );

    final loadingIndicator = const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? loadingIndicator
            : Icon(icon, color: finalIconColor, size: 20),
        label: Text(label, style: TextStyle(fontSize: 14, color: finalTextColor)),
        style: buttonStyle,
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

 void _navigateToLogin() {
  Navigator.pushReplacement(
    context, 
    PageRouteBuilder(
      pageBuilder: (context, animation1, animation2_) => const LoginPage(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    )
  );
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight * 0.006;
    final bool disableEmailPassSignup = _isLoading || _isGoogleLoading;


    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AuthHeader(
        isSignUp: true,
        onSwitchTap: _navigateToLogin,
      ),

      body: ListView(
        children: [
          const SizedBox(height: 30),
          Center(
            child: Text(
              "Create an Account",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _green),
            ),
          ),
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputField(
                  label: ' Email',
                  controller: _emailCtrl,
                  isPassword: false,
                  hintTextBelow: _emailError,
                  hintColorBelow: _emailError != null ? _red : Colors.transparent,
                ),

                const SizedBox(height: 10),
                _inputField(
                  label: ' Password',
                  controller: _passwordCtrl,
                  isPassword: true,
                  hintTextBelow: _passwordHint,
                  hintColorBelow: _passwordHintColor,
                ),

                const SizedBox(height: 10),
                _inputField(
                  label: ' Confirm Password',
                  controller: _confirmCtrl,
                  isPassword: true,
                  hintTextBelow: _confirmHint,
                  hintColorBelow: _confirmHintColor,
                ),

                const SizedBox(height: 10),
                if (_generalError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(_generalError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: 6),
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
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("Sign Up", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.normal,)),
                  ),
                ),

                SizedBox(height: spacing * 4),
                _dividerWithText("or sign in with"),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialBtn(
                      icon: Icons.g_mobiledata,
                      label: "Google",
                      bg: Colors.black,
                      iconColor: Colors.white,
                      textColor: Colors.white,
                      onPressed: _isGoogleLoading ? (){} : _onGoogle,
                      width: 250,
                      isLoading: _isGoogleLoading,
                      isGoogle: true,
                    ),
                    // _socialBtn(
                    //   icon: Icons.facebook,
                    //   label: "Facebook",
                    //   bg: Colors.white,
                    //   iconColor: Colors.blue,
                    //   textColor: Colors.black,
                    //   onPressed: disableEmailPassSignup ? (){} : _onFacebook,
                    //   width: MediaQuery.of(context).size.width * 0.42,
                    //   isLoading: false,
                    //   isGoogle: false,
                    // ),
                  ],
                ),

                const SizedBox(height: 34),
              ],
            ),
          ),
        ],

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
}