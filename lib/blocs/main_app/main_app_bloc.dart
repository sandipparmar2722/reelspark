
import 'package:flutter/material.dart';

import '../../core/base_bloc.dart';
import '../../core/screen_state.dart';
import '../../core/view_actions.dart';

import '../../services/main_app/theme_service.dart';
import 'main_app_contract.dart';

class MainAppBloc extends BaseBloc<MainAppEvent, MainAppData> {
  MainAppBloc(
    this._themeService,
  ) : super(initState) {
    on<InitEvent>(_initEvent);
    on<ChangeThemeEvent>(_changeTheme);
  }

  final ThemeService _themeService;


  static MainAppData get initState => (MainAppDataBuilder()
        ..state = ScreenState.loading
        ..appThemeData = ThemeData.light())
      .build();

  Future<void> _initEvent(_, emit) async {
    emit(
      state.rebuild(
        (u) {
          u
            ..state = ScreenState.loading
            ..errorMessage = null
            ..appThemeData = _themeService.getThemeData();
        },
      ),
    );

    try {
      await _bootstrapApp();
      emit(
        state.rebuild(
          (u) => u..state = ScreenState.content,
        ),
      );
    } catch (e) {
      emit(
        state.rebuild(
          (u) {
            u
              ..state = ScreenState.error
              ..errorMessage = e.toString();
          },
        ),
      );
    }
  }

  Future<void> _bootstrapApp() async {
    // Perform any startup work here (pre-fetch configs, hydrate caches, etc.)
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  Future<void> _changeTheme(_, emit) async {
    emit(
      state.rebuild(
        (u) {
          _themeService.changeTheme();
          u.appThemeData = _themeService.getThemeData();
        },
      ),
    );
    dispatchViewEvent(ChangeTheme());
  }
}
