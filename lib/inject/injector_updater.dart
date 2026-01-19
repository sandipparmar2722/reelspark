import 'package:dio/dio.dart';
import 'package:kiwi/kiwi.dart';

import 'injector.dart';

class InjectorUpdator {
  InjectorUpdator();
  KiwiContainer get container {
    return Injector.container;
  }

  void registerToken(String token) {
    if (token.isEmpty) {
      return;
    }
    final finalToken = 'Bearer $token';

    updateDioHeader({
      'Authorization': finalToken,
    });
  }

  void clearDioHeader() {
    final dio = container.resolve<Dio>();
    dio.options.headers = {};
  }

  void updateDioHeader(Map<String, dynamic> headers) {
    if (headers.isEmpty) {
      return;
    }
    final dio = container.resolve<Dio>();
    dio.options.headers.addEntries(headers.entries);
  }
}
