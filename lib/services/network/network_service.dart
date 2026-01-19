import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _dataConnectionChecker;
  void Function(bool)? onConnectivityChanged;
  NetworkService(this._dataConnectionChecker) {
    _dataConnectionChecker.onConnectivityChanged.listen(
          (List<ConnectivityResult> connectivityResults) {
        for (var connectivityResult in connectivityResults) {
          if (connectivityResult == ConnectivityResult.none) {
            _onChanged(false);
          } else {
            _onChanged(true);
          }
        }
      },
    );
  }

  void _onChanged(bool isConnected) {
    if (onConnectivityChanged != null) {
      onConnectivityChanged!(isConnected);
    }
  }

  Future<bool> get isConnected async {
    var connectivityResult = await (_dataConnectionChecker.checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  }
}
