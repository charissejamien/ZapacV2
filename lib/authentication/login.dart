import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapac/application/dashboard.dart';
import 'signup.dart';
import 'reset_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  

  // Colors harmonized with signup.dart
  final blueColor = const Color(0xFF5072A7);
  final greenColor = const Color(0xFF6CA89A);
  // UPDATED: Background/fill color to #F9F9F9
  final beigeColor = const Color(0xFFF9F9F9);

  final appBarColor = const Color(0xFF4A6FA5);
  double appBarHeight = 230.0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final spacing = screenHeight * 0.006;
    
    // Requested AppBar color, slightly darker blue than _blue
    final appBarColor = const Color(0xFF4A6FA5);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      
      // START: Merged AppBar structure
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(230), // Requested height
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60),
          ),
          child: AppBar(
            backgroundColor: appBarColor, // Requested color
            toolbarHeight: 250, // Match PreferredSize height
            automaticallyImplyLeading: false, 
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use existing 'bus.png' asset
                SizedBox(height: 20),
                Image.asset('assets/Logo.png', height: 130),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SIGN UP (Unselected, navigates to SignUpPage)
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.normal, // Unselected style
                            fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),

                    // LOG IN (Selected, active page)
                    Column(
                      children: [
                        const Text(
                          "Log In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // Selected style
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 2, 
                          color: Colors.white,
                          margin: const EdgeInsets.only(top: 6),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // END: Custom AppBar structure

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
            padding: const EdgeInsets.symmetric(horizontal: 30), // Increased horizontal padding to 30 for consistency
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(" Email", style: TextStyle(fontSize: 15)),
                const SizedBox(height: 5),
                _buildTextField(emailController, "Email", beigeColor),
                const SizedBox(height: 30),
                const Text(" Password", style: TextStyle(fontSize: 15)),
                const SizedBox(height: 5),
                _buildTextField(passwordController, "Password", beigeColor,
                    isPassword: true),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
  UserCredential userCredential = await FirebaseAuth.instance
      .signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

  // Go to dashboard on success
 Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const DashboardPage()),
);
} on FirebaseAuthException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message ?? 'Login failed')),
  );
}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding for consistency
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Increased radius for consistency
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.black, 
                        fontSize: 16, 
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Forgotten your password? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Reset password",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _dividerWithText("or sign in with"),
                const SizedBox(height: 20),
                _buildSocialButtons(beigeColor), // Uses new social button structure
              ],
            ),
          ),
        ],
      ),

      // START: bottomNavigationBar copied from signup.dart
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: appBarColor, // Use the consistent AppBar color
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
        ),
      ),
      // END: bottomNavigationBar
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      Color fillColor,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3EEE6),
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
        // Using OutlineInputBorder with borderSide.none for consistency
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), // Harmonized radius
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16), // Harmonized padding
      ),
    );
  }

  Widget _dividerWithText(String text) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, endIndent: 10),
        ),
        Text(text, style: const TextStyle(fontSize: 13)),
        const Expanded(
          child: Divider(thickness: 1, indent: 10),
        ),
      ],
    );
  }

  // Social button structure copied from the latest version of the flow
  Widget _buildSocialButtons(Color canvasColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Google Button: width 0.45
        SizedBox(
          width: screenWidth * 0.45,
          child: _socialButton(Icons.g_mobiledata, "Google", Colors.black, Colors.white, Colors.white),
        ),
        // Facebook Button: width 0.40
        SizedBox(
          width: screenWidth * 0.40,
          child: _socialButton(Icons.facebook, "Facebook", beigeColor, Colors.blue, Colors.black),
        ),
      ],
    );
  }

  // Social button helper updated to handle text color
  Widget _socialButton(
      IconData icon, String text, Color bgColor, Color iconColor, Color textColor) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: iconColor, size: 20), // Harmonized icon size
      label: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0, // Harmonized elevation
      ),
    );
  }
}