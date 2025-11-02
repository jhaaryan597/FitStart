import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand Color Palette
const Color neonGreen = Color(0xFF656D4A); // #656D4A - Primary brand color
const Color colorWhite = Color(0xFFFFFFFF); // #FFFFFF - White
const Color lightGray = Color(0xFFE3E3E3); // #E3E3E3 - Light gray
const Color colorBlack =
    Color(0xFF333D29); // #333D29 - Dark green for text/icons
const Color lightGreen = Color(0xFFA4AC86); // #A4AC86 - Light accent green

// Derived colors for better UI
const Color primaryColor = neonGreen;
const Color backgroundColor =
    Color(0xFFA4AC86); // #A4AC86 - Sage green background
const Color surfaceColor = Color(0xFFA4AC86); // #A4AC86 - Sage green for cards
const Color textPrimary =
    Color(0xFF333D29); // #333D29 - Dark green for primary text
const Color textSecondary =
    Color(0xFF5A6650); // Slightly lighter green for secondary text
const Color borderColor = Color(0xFF8B9475); // Darker sage for borders
const Color accentColor = lightGreen;

// Legacy color names for backward compatibility
const Color primaryColor100 = lightGreen;
const Color primaryColor300 = neonGreen;
const Color primaryColor500 = neonGreen;
const Color darkBlue300 = textSecondary;
const Color darkBlue500 = textPrimary;
const Color darkBlue700 = textPrimary;

// Additional legacy colors mapped to new palette
const Color lightBlue100 = surfaceColor; // Sage green surface
const Color lightBlue300 = borderColor;
const Color lightBlue400 = borderColor;
const Color neutral50 = surfaceColor; // Sage green surface
const Color neutral200 = borderColor;
const Color neutral400 = textSecondary;
const Color neutral500 = textSecondary;
const Color neutral700 = textPrimary;

const double borderRadiusSize = 16.0;

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
      displayMedium: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: GoogleFonts.poppins(color: textPrimary),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSize),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: textPrimary,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      background: Color(0xFF333D29),
      surface: Color(0xFF2A3322),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: colorWhite),
      displayMedium: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: colorWhite),
      titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w500, color: colorWhite),
      bodyLarge: GoogleFonts.poppins(color: colorWhite),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFB8BFB0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSize),
        ),
      ),
    ),
  );
}

TextStyle greetingTextStyle = GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);

TextStyle titleTextStyle = GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary);

TextStyle subTitleTextStyle = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary);

TextStyle normalTextStyle = GoogleFonts.poppins(color: textPrimary);

TextStyle descTextStyle = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary);

TextStyle addressTextStyle = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary);

TextStyle facilityTextStyle = GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary);

TextStyle priceTextStyle = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary);

TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);

TextStyle bottomNavTextStyle = GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500, color: primaryColor);

TextStyle tabBarTextStyle =
    GoogleFonts.poppins(fontWeight: FontWeight.w500, color: primaryColor);

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
