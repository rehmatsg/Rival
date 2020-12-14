import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.indigo,
  accentColor: Colors.indigoAccent,
  splashColor: Colors.indigoAccent,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  appBarTheme: AppBarTheme(color: Colors.white, elevation: 1.5, brightness: Brightness.light, actionsIconTheme: IconThemeData(color: Colors.black), iconTheme: IconThemeData(color: Colors.black), textTheme: TextTheme(headline6: TextStyle(color: Colors.black, fontSize: 22, fontFamily: RivalFonts.feature))),
  canvasColor: Colors.white,
  popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10))
    ),
    elevation: 1
  ),
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10))
    )
  ),
  tooltipTheme: TooltipThemeData(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    preferBelow: true,
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10))
    ),
  )
);

ThemeData darkTheme = ThemeData(
  splashColor: Colors.indigo,
  accentColor: Colors.indigoAccent,
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(color: Colors.white10, elevation: 1, brightness: Brightness.dark, actionsIconTheme: IconThemeData(color: Colors.white), iconTheme: IconThemeData(color: Colors.white), textTheme: TextTheme(headline6: TextStyle(color: Colors.white, fontSize: 22, fontFamily: RivalFonts.feature))),
  backgroundColor: Colors.black54,
  scaffoldBackgroundColor: Colors.black12,
  canvasColor: Color(0xFF000000),
  popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10))
    ),
    elevation: 1
  ),
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(13))
    )
  ),
  tooltipTheme: TooltipThemeData(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    preferBelow: true,
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10))
    ),
  ),
);

// -------------- FONTS ------------------
class RivalFonts {
  static String get rival => 'DMSerifText';
  @Deprecated('Use the getter rival instead')
  static String get main => 'Playfair Display';
  static String get body => 'Roboto';
  static String get feature => 'Product Sans';
}