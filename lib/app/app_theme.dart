import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _AppThemeColors {
  // Primary color
  final Color blue = const Color(0xFF4A6FA5);
  // Secondary color
  final Color green = const Color(0xFF6CA89A);
  // Custom Dark Green
  final Color darkGreen = const Color(0xFF38645C);
}

class AppTheme {
  static final _AppThemeColors colors = _AppThemeColors();
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;

  const AppColors({required this.success, required this.warning});

  @override
  AppColors copyWith({Color? success, Color? warning}) =>
      AppColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
    }
}

const List<String> _fallbackFonts = <String>[
  'SF Pro Text',
  'Istok Web',
  'Inter',
  'Lexend Zetta',
  'Nunito',
  'Roboto',
  'sans-serif',
];

class ZapacTheme {

  static TextTheme _textTheme(Brightness b) {
    final base = ThemeData(brightness: b, useMaterial3: true).textTheme;

    final body = GoogleFonts.interTextTheme(base);

    return body.copyWith(
      headlineLarge: GoogleFonts.lexendZetta(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineMedium: GoogleFonts.lexendZetta(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),

      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),

      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),


      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600),


      displaySmall: GoogleFonts.istokWeb(fontSize: 12, fontWeight: FontWeight.w400),
    );
  }

  static List<ThemeExtension<dynamic>> _extensions(Brightness b) => [
    AppColors(
      success: b == Brightness.light ? const Color(0xFF2E7D32) : const Color(0xFF81C784),
      warning: b == Brightness.light ? const Color(0xFFF9A825) : const Color(0xFFFFD54F),
    ),
  ];

  // ---- LIGHT ----
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    primaryColor: AppTheme.colors.blue,
    fontFamily: GoogleFonts.manrope().fontFamily,
    fontFamilyFallback: _fallbackFonts,
    colorScheme: ColorScheme.light(
      primary: AppTheme.colors.blue,
      onPrimary: Colors.white,
      background: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      secondary: AppTheme.colors.green,
      error: const Color(0xFFE97C7C),
      outlineVariant: const Color(0xFFDDDDDD),
    ),
    textTheme: _textTheme(Brightness.light),
    appBarTheme: AppBarTheme(backgroundColor: AppTheme.colors.blue),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    extensions: _extensions(Brightness.light),
  );

  // ---- DARK ----
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: const Color(0xFF273238),
    fontFamily: GoogleFonts.manrope().fontFamily,
    fontFamilyFallback: _fallbackFonts,
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
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: _textTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    extensions: _extensions(Brightness.dark),
  );
}