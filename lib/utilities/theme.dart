import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData light = ThemeData(
    primaryColor: Colors.lightBlue,
    brightness: Brightness.light,
  );

  static final ThemeData dark = ThemeData(
    primaryColor: Colors.blueGrey,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blue[900],
  );
}
