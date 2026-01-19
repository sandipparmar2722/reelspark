import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cache/preference_store.dart';
import 'colors.dart';

class AppTheme {
  AppTheme(this._preferenceStore);

  final PreferenceStore _preferenceStore;

  late Brightness brightness;

  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryDark, // Change this to your desired color
      ),
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      primaryColorDark: AppColors.primary,
      primaryColorLight: AppColors.primary,
      highlightColor: AppColors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      unselectedWidgetColor: Colors.white,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          // Status bar color
          statusBarColor: Colors.white,

          // Status bar brightness (optional)
          statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
          statusBarBrightness: Brightness.light, // For iOS (dark icons)
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      primaryColorDark: AppColors.primary,
      primaryColorLight: AppColors.primary,
      highlightColor: AppColors.white,
      //backgroundColor: AppColors.scaffoldBackgroundColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      unselectedWidgetColor: Colors.white,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          // Status bar color
          statusBarColor: AppColors.primary,

          // Status bar brightness (optional)
          statusBarIconBrightness: Brightness.light, // For Android (dark icons)
          statusBarBrightness: Brightness.dark, // For iOS (dark icons)
        ),
      ),
    );
  }

  ThemeData get theme {
    AppColors.isLightTheme = _preferenceStore.isAppThemeLight();
    return AppColors.isLightTheme ? lightTheme : darkTheme;
  }

  bool get isLight {
    AppColors.isLightTheme = _preferenceStore.isAppThemeLight();
    return AppColors.isLightTheme;
  }

  bool changeTheme() {
    _preferenceStore.setAppThemeLight(!isLight);
    AppColors.isLightTheme = isLight;
    return AppColors.isLightTheme;
  }
}
