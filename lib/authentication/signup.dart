// lib/signup.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'authentication.dart';

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

  String? _emailError;
  String? _passwordHint;
  Color _passwordHintColor = Colors.transparent;
  String? _confirmHint;
  Color _confirmHintColor = Colors.transparent;
  String? _generalError;

  final Color _blue = const Color(0xFF5072A7);
  final Color _green = const Color(0xFF6CA89A);
  final Color _beige = const Color(0xFFF3EEE6);

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
        // loose email check — change to stricter if you want
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
        // Navigate to Login as in screenshot flow (or home)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Social handlers
  Future<void> _onGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onFacebook() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithFacebook();
      if (user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    String? hintTextBelow,
    Color hintColorBelow = Colors.transparent,
  }) {
    final borderColor = (controller == _emailCtrl && _emailError != null)
        ? Colors.red
        : (isPassword && hintColorBelow == Colors.red)
            ? Colors.red
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword ? (controller == _passwordCtrl ? _obscurePassword : _obscureConfirm) : false,
          decoration: InputDecoration(
            filled: true,
            fillColor: _beige,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor == Colors.transparent ? _green : borderColor, width: 2.0),
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
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
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
    required VoidCallback onPressed,
    double width = 150,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight * 0.006;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ListView(
        children: [
          // top blue curved header
          ClipPath(
            clipper: _CurvedClipper(),
            child: Container(
              height: 220,
              color: _blue,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/bus.png', height: 80),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(width: 48, height: 2, color: Colors.white, margin: const EdgeInsets.only(top: 6)),
                        ],
                      ),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        },
                        child: Text(
                          "Log In",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          Center(
            child: Text(
              "Create an Account",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _green),
            ),
          ),
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputField(
                  label: 'Email',
                  controller: _emailCtrl,
                  isPassword: false,
                  hintTextBelow: _emailError,
                  hintColorBelow: _emailError != null ? Colors.red : Colors.transparent,
                ),

                const SizedBox(height: 14),
                _inputField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  isPassword: true,
                  hintTextBelow: _passwordHint,
                  hintColorBelow: _passwordHintColor,
                ),

                const SizedBox(height: 14),
                _inputField(
                  label: 'Confirm Password',
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Sign Up", style: TextStyle(color: Colors.black, fontSize: 16)),
                ),

                SizedBox(height: spacing * 8),
                _dividerWithText("or sign in with"),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _socialBtn(
                      icon: Icons.g_mobiledata,
                      label: "Google",
                      bg: Colors.black,
                      iconColor: Colors.white,
                      onPressed: _onGoogle,
                      width: MediaQuery.of(context).size.width * 0.55,
                    ),
                    _socialBtn(
                      icon: Icons.facebook,
                      label: "Facebook",
                      bg: Colors.white,
                      iconColor: Colors.blue,
                      onPressed: _onFacebook,
                      width: MediaQuery.of(context).size.width * 0.25,
                    ),
                  ],
                ),

                const SizedBox(height: 34),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// same curved clipper used in login.dart so visuals match
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
