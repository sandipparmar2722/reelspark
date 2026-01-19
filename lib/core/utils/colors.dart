// ignore_for_file: constant_identifier_names,avoid_classes_with_only_static_members
import 'package:flutter/material.dart';

abstract class GradientColors {
  static const primary = [
    Color(0x802F8E46),
    Color(0xFFEF5984),
    Color(0xFFFF3F5C)
  ];

  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [AppColors.primary, Colors.transparent],
  );
}

abstract class AppColors {
  static bool isLightTheme = false;
  static const primary = Color(0xFF000000);
  static const buttonBorderColor = Color(0xFFFFC727);
  static const buttonTextGray = Color(0xFF95A0A3);
  static const primaryDark = Color(0x802F8E46);
  static const buttonDarkGray = Color(0xFF2B2B2C);
  static const primaryAccent = Color(0xFFFFFFFF);
  static const contactFormTextColor = Color(0xFF95A0A3);
  static const white = Colors.white;
  static const black = Colors.black;
  static const scaffoldBackgroundColor = white;
  static const backgroundColor = white;
  static const appButtonBG = Color.fromRGBO(47, 142, 70, 0.5019607843137255);
  static const errorMsg = Color.fromARGB(255, 232, 60, 30);
  static const categoryName = Color(0xFF148B8A);

  static Color get buttonText => isLightTheme ? Colors.white : Colors.white;
  static Color get buttonBackground =>
      isLightTheme ? Colors.white : Colors.white;

  static Color textFieldHintColor = Colors.grey.shade400;


  static const primaryRed = Color(0xFFE53935);
  static const primaryPurple = Color(0xFF7C4DFF);

  static const backgroundGlass = Color(0x99FFFFFF);
  static const card = Colors.white;

  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);


  static const navInactive = Color(0xFF9E9E9E);
  static const navActive = Color(0xFF000000);

  /// 🎨 Gradient for active pill
  static const LinearGradient activeNavGradient = LinearGradient(
    colors: [
      Color(0xFF7C4DFF), // Purple
      Color(0xFFE53935), // Red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


}
