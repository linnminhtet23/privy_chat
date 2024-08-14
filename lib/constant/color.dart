import 'dart:ui' show Color;

class KColors {
  final Color primaryDark;
  final Color secondaryDark;
  final Color activeColor;
  final Color grey;
  final Color black;
  // final Color white;

  const KColors({
    required this.primaryDark,
    required this.secondaryDark,
    required this.activeColor,
    required this.grey,
    required this.black,
    // required this.white,
  });
}

 const KColors colorScheme1 = KColors(
  primaryDark:  Color.fromRGBO(26,32,52, 1.0),
  secondaryDark:  Color.fromRGBO(32,41,64, 1.0),
  activeColor:  Color.fromRGBO(52,70,102, 1.0), 
  grey: Color(0xFFE0E0E0),
  black:  Color(0xFF1C1C1C),
  // white: Color.white,
);
