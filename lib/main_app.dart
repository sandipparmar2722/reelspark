import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reelspark/ui/templates/screens/templates_home_screen.dart';

import 'blocs/main_app/main_app_bloc.dart';
import 'blocs/main_app/main_app_contract.dart';
import 'blocs/navigation/nav_bloc.dart';
import 'inject/injector.dart';

import 'core/base_state.dart';
import 'core/constants.dart';
import 'core/utils/navigator_middleware.dart';

import 'ui/root/root_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends BaseState<MainAppBloc, MainApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    /// Navigator middleware (analytics / tracking)
    middleware = NavigatorMiddleware<PageRoute>(
      onPush: (route, previousRoute) {
        currentRouteName = route.settings.name ?? '';
      },
      onReplace: (route, previousRoute) {
        currentRouteName = route.settings.name ?? '';
      },
      onPop: (route, previousRoute) {
        currentRouteName = previousRoute?.settings.name ?? '';
      },
      onRemove: (route, previousRoute) {
        currentRouteName = previousRoute?.settings.name ?? '';
      },
    );

    WidgetsBinding.instance.addObserver(this);
    bloc.add(InitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        /// App-level theme / config bloc
        BlocProvider<MainAppBloc>(
          create: (_) => bloc,
        ),

        /// 🔥 Navigation Bloc (Bottom Nav / Deep Links / Analytics)
        BlocProvider<NavBloc>(
          create: (_) => Injector.resolve<NavBloc>(),
        ),
      ],
      child: BlocBuilder<MainAppBloc, MainAppData>(
        builder: (context, data) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            navigatorObservers: [middleware],
            theme: data.appThemeData,

            /// ✅ SINGLE ENTRY POINT
            home: const RootScreen(),

            /// Overlay support (keep as-is)
            builder: (context, child) {
              return Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => child!,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
