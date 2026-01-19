
import '../logging.dart';

extension FutureHelpers<T> on Future<T> {
  Future<T> logError() => catchError((error) async {
        log(error: error);
        throw error;
      });
}
