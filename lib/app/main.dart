import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';
import '../authentication/onboarding_profile.dart';
import 'main_shell.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) async {
    if (mode != _themeMode) {
      _themeMode = mode;

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    }
  }

  void setInitialTheme(ThemeMode mode) {
    _themeMode = mode;
  }
}

late ThemeNotifier themeNotifier = ThemeNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.setInitialTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);

  // AUTHENTICATION PERSISTENCE AND NAVIGATION LOGIC
  final currentUser = FirebaseAuth.instance.currentUser;
  // NOTE FOR TESTING: The onboardingComplete check is removed to force
  // signed-in users to always go through the onboarding/location flow.
  // final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

  // FIX: Initialize the variable immediately to guarantee it's a non-null String.
  String determinedInitialRoute = '/login';

  if (currentUser != null) {
    // === MODIFIED FOR TESTING ===
    // User is signed in. Always go to the start of onboarding/profile page.
    determinedInitialRoute = '/onboarding/profile'; //
  } 
  // If currentUser is null, it remains '/login'.

  // PASS determinedInitialRoute to ZapacApp
  runApp(ZapacApp(initialRoute: determinedInitialRoute));
}

class ZapacApp extends StatelessWidget {
  final String initialRoute; // Field to hold the calculated route
  
  // Constructor requires the initial route
  const ZapacApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {

    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zapac',

          // --- Light Theme ---
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF4A6FA5),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A6FA5),
              onPrimary: Colors.white,
              background: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              secondary: Color(0xFF6CA89A),
              error: Color(0xFFE97C7C),
              outlineVariant: Color(0xFFDDDDDD),
            ),
            appBarTheme: const AppBarTheme(
              color: Color(0xFF4A6FA5),
            ),
          ),

          // --- Dark Theme ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF273238),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF273238),
              onPrimary: Colors.white,
              background: Color(0xFF121212),
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
              secondary: Color(0xFF9DBEBB),
              error: Color(0xFFCF6679),
              outlineVariant: Color(0xFF444444),
            ),
            appBarTheme: const AppBarTheme(color: Color(0xFF1E1E1E)),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),

          themeMode: themeNotifier.themeMode,

          initialRoute: initialRoute, // Use the passed route
          routes: {
            '/login': (context) => const LoginPage(),
            '/onboarding/profile': (context) => const OnboardingProfilePage(),
            '/app': (context) => const MainShell(),
          },
        );
      },
    );
  }
}