import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zapac/dashboard/dashboard.dart';
import '../authentication/login_page.dart';
import '../authentication/onboarding_profile.dart';

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

  runApp(const ZapacApp());
}

class ZapacApp extends StatelessWidget {
  const ZapacApp({super.key});

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

          initialRoute: '/',
          routes: {
            '/': (context) => const OnboardingProfilePage(),
            // '/dashboard': (context) => const Dashboard(),
          },
        );
      },
    );
  }
}