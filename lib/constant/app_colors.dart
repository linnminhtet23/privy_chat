import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkAppbarColor = Color(0xFF1A1A1A);
  static const Color darkAccentColor = Color(0xFF1E88E5);
  static const Color darkIncomingBubbleColor = Color(0xFF424242);
  static const Color darkOutgoingBubbleColor = Color(0xFF1E88E5);
  static const Color darkTextColorIncoming = Color(0xFFFFFFFF);
  static const Color darkTextColorOutgoing = Color(0xFFFFFFFF);
  static const Color darkStatusColor = Color(0xFF00E676);
  static const Color darkInputFieldColor = Color(0xFF333333);
  static const Color darkIconColor = Color(0xFFFFFFFF);
  
  // Dark Theme Navigation Bar
  static const Color darkNavBarBackground = Color(0xFF1A1A1A);
  static const Color darkNavBarIconColor = Color(0xFFFFFFFF);
  static const Color darkNavBarSelectedIconColor = Color(0xFF1E88E5); // Dark Button color
  
  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFFFFFFF);
  static const Color lightAppbarColor = Color(0xFFFFFFFF);
  static const Color lightAccentColor = Color(0xFF1976D2);
  static const Color lightIncomingBubbleColor = Color(0xFFE0E0E0);
  static const Color lightOutgoingBubbleColor = Color(0xFF1976D2);
  static const Color lightTextColorIncoming = Color(0xFF000000);
  static const Color lightTextColorOutgoing = Color(0xFFFFFFFF);
  static const Color lightStatusColor = Color(0xFF388E3C);
  static const Color lightInputFieldColor = Color(0xFFF5F5F5);
  static const Color lightIconColor = Color(0xFF000000);

  // Light Theme Navigation Bar
  static const Color lightNavBarBackground = Color(0xFFFFFFFF);
  static const Color lightNavBarIconColor = Color(0xFF000000);
  static const Color lightNavBarSelectedIconColor = Color(0xFF1976D2); // Light Button color
  
  // New Button Colors
  static const Color lightButtonColor = Color(0xFF1976D2); // Button color for light mode
  static const Color darkButtonColor = Color(0xFF1E88E5); // Button color for dark mode

  // Error Color (can be used in both themes)
  static const Color errorColor = Color(0xFFB00020);

  // Font Styles
  static TextStyle get bodyStyle => GoogleFonts.poppins(
    textStyle: TextStyle(
      fontSize: 16,
      color: Colors.black, // Default color, can be customized
    ),
  );
}
