import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (iOS + Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permission status: ${settings.authorizationStatus}');

    // Get token
    String? token = await messaging.getToken();

    if (token != null) {
      print('🔥 FCM TOKEN: $token');
    } else {
      print('❌ Failed to get FCM token');
    }
  }
}
