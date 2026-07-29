import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Nocturne palette ────────────────────────────────────────────────────────
const kBackground = Color(0xFF161826); // app ground
const kNavBar = Color(0xFF0A0B14); // bottom nav (deep)
const kSurface = Color(0xFF232532); // cards, inputs, assistant bubbles
const kSurfaceLight = Color(0xFF3F424D); // neutral-800: borders, tracks

const kAccent = Color(0xFF968AE0); // blurple — buttons, mic, selected nav
const kAccentText = Color(0xFFD2CEFD); // accent-300: accent text on dark
const kAccent200 = Color(0xFFE7E5FE);
const kAccent100 = Color(0xFFF5F4FF);
const kAccent600 = Color(0xFF796CBF); // user bubble gradient start
const kAccent700 = Color(0xFF5D5294); // user bubble gradient end
const kAccent800 = Color(0xFF423A6A); // tinted fills, "Related" tag
const kAccent900 = Color(0xFF2B2741); // card grounds

const kTextPrimary = Color(0xFFE9E9ED);
const kTextSecondary = Color(0xFF9397AB); // neutral-500: muted text
const kDivider = Color(0x29E9E9ED); // rgba(233,233,237,0.16)

// Semantic
const kSuccess = Color(0xFF4EC98A);
const kSuccessBg = Color(0xFF123524);
const kWarning = Color(0xFFE0A53D);
const kDanger = Color(0xFFE0563D);
const kDangerBg = Color(0xFF3A1512);

// Back-compat alias: older code referenced `kRed` as the accent.
const kRed = kAccent;

const _onAccent = Color(0xFF151327); // dark ink on accent fills

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      secondary: kAccent,
      surface: kSurface,
      onPrimary: _onAccent,
      onSurface: kTextPrimary,
      error: kDanger,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: kTextPrimary,
    displayColor: kTextPrimary,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: const CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      hintStyle: const TextStyle(color: kTextSecondary),
      labelStyle: const TextStyle(color: kTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    ),
    // Nocturne uses OUTLINED primary buttons (accent border on transparent).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: kAccent,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: kAccent, width: 1),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kDivider),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kAccentText),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccent,
      foregroundColor: _onAccent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kNavBar,
      selectedItemColor: kAccent,
      unselectedItemColor: kTextSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurface,
      side: const BorderSide(color: kDivider),
      labelStyle: const TextStyle(color: kTextPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kSurface,
      contentTextStyle: TextStyle(color: kTextPrimary),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kAccent),
    listTileTheme: const ListTileThemeData(
      textColor: kTextPrimary,
      iconColor: kTextSecondary,
    ),
    dividerTheme: const DividerThemeData(color: kDivider),
    dialogTheme: const DialogThemeData(backgroundColor: kSurface),
  );
}
