// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injector.dart';

// **************************************************************************
// KiwiInjectorGenerator
// **************************************************************************

class _$Injector extends Injector {
  @override
  void _registerCache() {
    final KiwiContainer container = KiwiContainer();
    container.registerSingleton((c) => PreferenceStore());
  }

  @override
  void _registerApis() {
    final KiwiContainer container = KiwiContainer();
    container
      ..registerSingleton((c) => RestApiClient(c.resolve<Dio>(),
          c.resolve<CustomErrorHandler>(), c.resolve<NetworkService>()))
      ..registerSingleton(
          (c) => WeatherApi(dio: c.resolve<Dio>(), apiKey: c.resolve<String>()))
      ..registerSingleton((c) => ProductApi(dio: c.resolve<Dio>()));
  }

  @override
  void _registerServices() {
    final KiwiContainer container = KiwiContainer();
    container
      ..registerSingleton((c) => ThemeService(c.resolve<AppTheme>()))
      ..registerSingleton((c) => NetworkService(c.resolve<Connectivity>()));
  }

  @override
  void _registerMiscModules() {
    final KiwiContainer container = KiwiContainer();
    container
      ..registerSingleton((c) => CustomErrorHandler())
      ..registerSingleton((c) => AppTheme(c.resolve<PreferenceStore>()))
      ..registerSingleton((c) => Connectivity());
  }

  @override
  void _registerBlocProviders() {
    final KiwiContainer container = KiwiContainer();
    container
      ..registerFactory((c) => InfoBloc(
          c.resolve<CustomErrorHandler>(), c.resolve<EventBus>(),
          weatherApi: c.resolve<WeatherApi>(),
          productApi: c.resolve<ProductApi>()))
      ..registerFactory((c) => MainAppBloc(c.resolve<ThemeService>()))
      ..registerFactory((c) =>
          NavBloc(c.resolve<CustomErrorHandler>(), c.resolve<EventBus>()));
  }
}
