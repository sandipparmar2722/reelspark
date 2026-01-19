import 'base_localization.dart';

class EnglishLocalization extends BaseLocalization {
  EnglishLocalization() : super(code: 'en', name: 'English');

  @override
  String get appName => 'Flutter';

  @override
  String get dynamicText => 'Dynamic text %s';

  @override
  String get errorRetry => 'Retry';

  @override
  String get errorTitle => 'Error';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get noItem => 'Oops! There were no characters to display.';

  @override
  String get users => 'Users';

  @override
  String get cancelApiRequestError => 'Request to API server was cancelled';

  @override
  String get connectionTimeoutApiRequestError =>
      'Connection timeout with API server';

  @override
  String get invalidStatusApiRequestError => 'Received invalid status code %s';

  @override
  String get receiveTimeoutApiRequestError =>
      'Receive timeout in connection with API server';

  @override
  String get sendTimeoutApiRequestError => 'Connection timeout with API server';

  @override
  String get theme => 'Theme';

  @override
  String get nextScreen => 'Next screen';

  @override
  String get back => 'Back';

  @override
  String get home => 'Home';

  @override
  String get login => 'Login';

  @override
  String get registration => 'Registration';

  @override
  String get settings => 'Settings';
}
