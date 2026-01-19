import 'package:get_localization/get_localization.dart';

abstract class BaseLocalization extends Localization {
  BaseLocalization({
    required String code,
    required String name,
    String? country,
  }) : super(
          code: code,
          name: name,
          country: country,
        );

  static BaseLocalization currentLocalization() =>
      Localization.currentLocalization as BaseLocalization;
  String get appName;
  String get cancelApiRequestError;
  String get connectionTimeoutApiRequestError;
  String get sendTimeoutApiRequestError;
  String get receiveTimeoutApiRequestError;
  String get invalidStatusApiRequestError;

  String get errorTitle;
  String get errorRetry;
  String get noItem;
  String get noInternetConnection;
  String get dynamicText;
  String get users;
  String get theme;
  String get nextScreen;
  String get back;

  String get registration;
  String get login;
  String get home;
  String get settings;
}
