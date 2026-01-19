import 'dart:async';
import 'package:built_collection/built_collection.dart';
import '../../core/base_bloc.dart';
import '../../core/error/failures.dart';
import '../../core/event_bus.dart';
import '../../core/screen_state.dart';
import 'info_contract.dart';
import '../../api/weather_api/weather_api.dart';
import '../../api/product_api/product_api.dart';

class InfoBloc extends BaseBloc<InfoEvent, InfoData> {
  final CustomErrorHandler _errorHandler;
  final EventBus _eventBus;
  final WeatherApi _weatherApi;
  final ProductApi _productApi;

  InfoBloc(this._errorHandler, this._eventBus,
      {WeatherApi? weatherApi, ProductApi? productApi})
      : _weatherApi = weatherApi ?? WeatherApi(),
        _productApi = productApi ?? ProductApi(),
        super(initState) {
    on<InitEvent>(_initEvent);
    on<GetWeatherEvent>(_getWeatherEvent);
    on<ProductDataEvent>(_getProductDataEvent);
    _eventBus.events.listen(_handleBusEvents).bindToLifecycle(this);
  }

  static InfoData get initState => (InfoDataBuilder()
        ..state = ScreenState.content
        ..cityName = null
        ..temperature = null
        ..description = null
        ..errorMessage = null
        ..productsdata = ListBuilder<dynamic>()
        ..phone = '6256132')
      .build();

  Future<void> _initEvent(InitEvent event, emit) async {
    emit(state.rebuild((b) => b..state = ScreenState.content));
  }

  Future<void> _getProductDataEvent(ProductDataEvent event, emit) async {
    try {
      emit(state.rebuild((b) => b..state = ScreenState.loading));
      final products = await _productApi.fetchProducts();
      emit(state.rebuild((b) => b
        ..state = ScreenState.content
        ..productsdata = ListBuilder<dynamic>(products)));
    } catch (e) {
      emit(state.rebuild((b) => b
        ..state = ScreenState.error
        ..errorMessage = 'Failed to load product data: ${e.toString()}'));
    }
  }

  Future<void> _getWeatherEvent(GetWeatherEvent event, emit) async {
    try {
      emit(state.rebuild((b) => b..state = ScreenState.loading));
      final data = await _weatherApi.fetchWeather(event.city);
      emit(state.rebuild((b) => b
        ..state = ScreenState.content
        ..cityName = event.city
        ..temperature = (data['main']['temp'] as num).toDouble()
        ..description = data['weather'][0]['description'] as String));
    } catch (e) {
      emit(state.rebuild((b) => b
        ..state = ScreenState.error
        ..errorMessage = 'Failed to get weather data: ${e.toString()}'));
    }
  }

  void _handleBusEvents(BusEvent event) async {
    // Handle global events if needed
  }
}
