import 'package:dio/dio.dart';

class WeatherApi {
  final Dio _dio;
  final String apiKey;

  WeatherApi({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        apiKey = apiKey ?? '9dec6553c4e773d1862104c4d848df23';

  /// Fetch weather data for [city]. Returns the raw response map on success.
  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final response = await _dio.get(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'q': city,
        'appid': apiKey,
        'units': 'metric',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data as Map);
    }

    throw Exception('Failed to fetch weather: ${response.statusCode}');
  }
}
