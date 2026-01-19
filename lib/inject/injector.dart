
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kiwi/kiwi.dart';


import '../api/product_api/product_api.dart';
import '../api/weather_api/weather_api.dart';
import '../blocs/information_block/info_bloc.dart';
import '../blocs/main_app/main_app_bloc.dart';
import '../blocs/navigation/nav_bloc.dart';
import '../core/cache/preference_store.dart';
import '../core/error/failures.dart';
import '../core/event_bus.dart';
import '../core/network/rest_api_client.dart';
import '../core/utils/app_theme.dart';
import '../services/main_app/theme_service.dart';

import '../services/network/network_service.dart';
import 'injector_updater.dart';

part 'injector.g.dart';

const String INJECT_KEY_HEADER = 'header';
const String INJECT_KEY_LOGGER = 'logger';
const String INJECT_KEY_DIO = 'dio';

abstract class Injector {
  static late KiwiContainer container;

  static Future<bool> setup() async {
    container = KiwiContainer();

    _$Injector()._configure();

    // initialize preference store
    final preferenceStore = container.resolve<PreferenceStore>();
    return preferenceStore.init();
  }

  // For use from classes trying to get top-level
  // dependencies such as ChangeNotifiers or BLoCs
  static final T Function<T>([String]) resolve = container.resolve;

  void _configure() {
    // Configure modules here
    _configureBus();
    _configureNetworkModule();
    _registerCache();
    _configureInjector();
    _registerApis();
    _registerServices();
    _registerMiscModules();
    _registerBlocProviders();
  }

  void _configureInjector() {
    container.registerSingleton<InjectorUpdator>((c) => InjectorUpdator());
  }

  void _configureBus() {
    container.registerSingleton<EventBus>((c) => EventBusImpl());
  }



  /// Register Network modules
  void _configureNetworkModule() {
    _configureLogInterceptor();
    _configureHeaderInterceptor();
    _configureDio();
  }

  void _configureDio() {
    // Register API key for weather API (unnamed so it can be resolved by WeatherApi)
    container.registerInstance<String>('9dec6553c4e773d1862104c4d848df23');

    container.registerSingleton<Dio>(
      (c) {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

        if (kDebugMode) {
          dio.interceptors.add(c.resolve<Interceptor>(INJECT_KEY_LOGGER));
        }
        dio.interceptors.add(c.resolve<Interceptor>(INJECT_KEY_HEADER));

        return dio;
      },
    );
  }

  void _configureLogInterceptor() {
    container.registerSingleton<Interceptor>(
      (c) => LogInterceptor(
        request: true,
        requestBody: true,
        responseHeader: true,
        requestHeader: true,
        responseBody: true,
        error: true,
      ),
      name: INJECT_KEY_LOGGER,
    );
  }

  void _configureHeaderInterceptor() {
    container.registerSingleton<Interceptor>(
      (c) => InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          return handler.next(options);
        },
      ),
      name: INJECT_KEY_HEADER,
    );
  }


  /// Register Data Stores
  @Register.singleton(PreferenceStore)
  void _registerCache();

  /// Register Apis
  @Register.singleton(RestApiClient)
  @Register.singleton(WeatherApi)
  @Register.singleton(ProductApi)


  void _registerApis();

  /// Register Services
  @Register.singleton(ThemeService)
  @Register.singleton(NetworkService)

  /// @Register.singleton(AnalyticsService, from: AnalyticsServiceImpl)
  ///
  void _registerServices();

  /// Register Misc
  @Register.singleton(CustomErrorHandler)
  @Register.singleton(AppTheme)
  @Register.singleton(Connectivity)
  void _registerMiscModules();

  /// Register Bloc dependencies

  @Register.factory(InfoBloc)
  @Register.factory(MainAppBloc)
  @Register.factory(NavBloc)




  void _registerBlocProviders();
}
