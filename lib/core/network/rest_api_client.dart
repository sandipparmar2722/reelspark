// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dio/dio.dart';

import '../../api/entities/common.dart';
import '../../services/network/network_service.dart';
import '../error/failures.dart';
import '../logging.dart';

enum RequestMethod { get, post, put, delete, head, patch, multiPart }

extension RequestMethodExtension on RequestMethod {
  String get methodName {
    switch (this) {
      case RequestMethod.get:
        return 'GET';

      case RequestMethod.post:
        return 'POST';

      case RequestMethod.put:
        return 'PUT';

      case RequestMethod.delete:
        return 'DELETE';

      case RequestMethod.head:
        return 'HEAD';

      case RequestMethod.patch:
        return 'PATCH';

      case RequestMethod.multiPart:
        return 'POST';
    }
  }
}

enum RequestDataType { body, query, formData }

class RequestData {
  RequestData({required this.data, required this.type});

  RequestDataType type;
  Map<String, dynamic>? data;

  dynamic get getData {
    switch (type) {
      case RequestDataType.formData:
        return FormData.fromMap(data ?? {});

      case RequestDataType.body:
        return data;

      case RequestDataType.query:
        return data;


      default:
        return null;
    }
  }
}

class RestApiClient {
  RestApiClient(this._dio, this._customErrorHandler, this._networkService);

  final Dio _dio;
  final CustomErrorHandler _customErrorHandler;
  final NetworkService _networkService;

  Future<ResponseEntity<Map<String, dynamic>?>> request({
    required String path,
    required RequestData data,
    required RequestMethod requestMethod,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    /* if (!await _networkService.isConnected) {
      return ResponseEntity(
        null,
        ErrorResult(
          errorMessage:
              BaseLocalization.currentLocalization().noInternetConnection,
          type: ErrorResultType.noInternetConnection,
        ),
      );
    } */

    final _options = options ?? Options();
    _options.method = requestMethod.methodName;
    _options.headers = headers;

    final requestOption = _options
        .compose(
          _dio.options,
          path,
          queryParameters:
              requestMethod == RequestMethod.get ? data.getData : null,
          data: data.getData,
          cancelToken: cancelToken,
        )
        .copyWith(
          baseUrl: _dio.options.baseUrl,
        );

    try {
      final response = await _dio.fetch(
        requestOption,
      );
      return ResponseEntity(response.data, null);
    } on DioError catch (dioError) {
      if (dioError.type == DioErrorType.badResponse) {
        // return ResponseEntity(dioError.response?.data, null);
        if (dioError.response?.data is Map<String, dynamic>) {
          final _data = dioError.response?.data as Map<String, dynamic>;
          var message = 'Something went wrong...';
          if (_data.containsKey('message')) {
            message = _data['message'] as String;
          }
          if (dioError.response?.statusCode == 401) {
            return ResponseEntity(
              null,
              ErrorResult(
                errorMessage: 'Invalid token please login again.',
                type: ErrorResultType.invalidToken,
              ),
            );
          }
          return ResponseEntity(
            null,
            ErrorResult(
              errorMessage: message,
              type: ErrorResultType.response,
            ),
          );
        } else {
          return ResponseEntity(
            null,
            _customErrorHandler.getErrorMessage(dioError),
          );
        }
      }
      log(error: dioError);
      return ResponseEntity(
        null,
        _customErrorHandler.getErrorMessage(dioError),
      );
    } on Exception catch (error) {
      log(error: error);
      return ResponseEntity(
        null,
        _customErrorHandler.getErrorMessage(error),
      );
    }
  }
}
