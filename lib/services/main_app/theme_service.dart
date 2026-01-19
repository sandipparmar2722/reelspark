import 'package:flutter/material.dart';

import '../../core/utils/app_theme.dart';

class ThemeService {
  ThemeService(this._appTheme);

  final AppTheme _appTheme;
  ThemeData getThemeData() {
    return _appTheme.theme;
  }

  bool isLightTheme() {
    return _appTheme.isLight;
  }

  bool changeTheme() {
    return _appTheme.changeTheme();
  }
}
