import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart' show ThemeData;

import '../../core/screen_state.dart';

part 'main_app_contract.g.dart';

abstract class MainAppData implements Built<MainAppData, MainAppDataBuilder> {
  factory MainAppData([void Function(MainAppDataBuilder) updates]) =
      _$MainAppData;
  MainAppData._();

  ScreenState get state;

  String? get errorMessage;

  ThemeData get appThemeData;
}

abstract class MainAppEvent {}

class InitEvent extends MainAppEvent {}

class ChangeThemeEvent extends MainAppEvent {}


abstract class MainAppTarget {
  static const String loginScreen = 'loginScreen';
}
