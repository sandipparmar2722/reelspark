// ignore_for_file: constant_identifier_names, unused_field
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class PreferenceStore {
  late SharedPreferences _sharedPreferences;

  PreferenceStore();

  Future<bool> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    return true;
  }

  Future<bool> reset() async {
    await setToken('');
    final isClear = await _sharedPreferences.clear();
    return isClear;
    /* final userInfo = getUserInfo();
    if (userInfo?.isApplePayEnabled ?? false) {
      await setToken('');
      final isIOSSubscribed =
          _sharedPreferences.getBool(_IOS_IAP_SUBSCRIBED) ?? false;
      final subcriptionInfo = getSubscriptionInfo();
      final isClear = await _sharedPreferences.clear();
      await _sharedPreferences.setBool(_IOS_IAP_SUBSCRIBED, isIOSSubscribed);
      if (subcriptionInfo != null) {
        await setSubscriptionInfo(subcriptionInfo.toRawData());
      }
      return isClear;
    } else {
      await setToken('');
      final isClear = await _sharedPreferences.clear();
      return isClear;
    } */
  }

  bool isIOSSubscribed() {
    return _sharedPreferences.getBool(PrefKey.IOS_IAP_SUBSCRIBED) ?? false;
  }

  Future<bool> setIsIOSSubscribed(bool value) {
    return _sharedPreferences.setBool(PrefKey.IOS_IAP_SUBSCRIBED, value);
  }

  bool isAppThemeLight() {
    return _sharedPreferences.getBool(PrefKey.IS_APP_THEME_LIGHT) ?? true;
  }

  Future<bool> setAppThemeLight(bool isLight) async {
    return _sharedPreferences.setBool(PrefKey.IS_APP_THEME_LIGHT, isLight);
  }

  Future<bool> setUserId(String userId) async {
    return _sharedPreferences.setString(PrefKey.USER_ID, userId);
  }

  String? getUserId() {
    return _sharedPreferences.getString(PrefKey.USER_ID);
  }

  Future<bool> setToken(String token) async {
    return _sharedPreferences.setString(PrefKey.AUTH_TOKEN, token);
  }

  Future<bool> setRemainingLikes(int count) async {
    return _sharedPreferences.setInt(PrefKey.REMAINING_LIKES, count);
  }

  Future<bool> setFcmToken(String count) async {
    return _sharedPreferences.setString(PrefKey.FIREBASE_TOKEN, count);
  }

  Future<bool> setString(String key, String value) => _sharedPreferences.setString(key, value);
  Future<bool> setBool(String key, bool value) => _sharedPreferences.setBool(key, value);
  String? getString(String key) => _sharedPreferences.getString(key);
  bool? getBool(String key) => _sharedPreferences.getBool(key);
  Future<bool> remove(String key) => _sharedPreferences.remove(key);

  String getToken() {
    return _sharedPreferences.getString(PrefKey.AUTH_TOKEN) ?? '';
  }

  String getFcmToken() {
    return _sharedPreferences.getString(PrefKey.FIREBASE_TOKEN) ?? '';
  }

  int getRemainingLikes() {
    return _sharedPreferences.getInt(PrefKey.REMAINING_LIKES) ?? 0;
  }

  Future<bool> setUserInfo(String user) async {
    return _sharedPreferences.setString(PrefKey.USER_INFO, user);
  }


}
