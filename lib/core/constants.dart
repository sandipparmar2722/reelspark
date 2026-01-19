// ignore_for_file: constant_identifier_names, type_annotate_public_apis

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/navigator_middleware.dart';

abstract class Routes {
  static const ROOT = '/';
  static const HOME = 'home';
}

enum DeviceType { android, ios }

enum PaymentStatus { Active, Paused, Canceled, Expired, Pending, Trialing }

String referralCode = '';

abstract class PrefKey {
  static const IS_LOGGED_IN = 'is_logged_in';
  static const IS_APP_THEME_LIGHT = 'is_app_theme_light';
  static const USER_ID = 'user_id';
  static const AUTH_TOKEN = 'auth_token';
  static const REMAINING_LIKES = 'remaining_likes';
  static const USER_INFO = 'user_info';
  static const SUBSCRIPTION_INFO = 'subscription_info';
  static const IOS_IAP_SUBSCRIBED = 'is_ios_IAP_subscribed';
  static const FIREBASE_TOKEN = 'firebase_token';
  static const PENDING_CALL_DATA = 'pending_call_data';
  static const PENDING_CALL_ACCEPTED = 'pending_call_accepted';
}

abstract class UserType {
  static const HOST = 'host';
  static const CO_HOST = 'co_host';
  static const AUDIENCE = 'audience';
}

abstract class InviteeStatus {
  static const REJECTED = 'Rejected';
  static const ACCEPTED = 'Accepted';
  static const PENDING = 'Pending';
}

const double MAXIMUM_CTA_WIDTH_TABLETS = 375.0;
const double LARGE_SCREEN_WIDTH_THRESHOLD = 600.0;
const int USER_SESSION_EXPIRY_TIME_BUFFER = 600; // in seconds
const int PAGE_SIZE = 20;

String PayKey = "";
const CONNECTION_TIMEOUT = 50000;
const RECEIVE_TIMEOUT = 30000;
const COUNTRY_CODE = '+91';
const ABC_KEY = '234mk3m324233k4lklkjkhjhhjhjhj2342k43';
const termsConditionUrl =
    'https://www.dereksbgglive.com/api/terms-and-conditions/';
const privacyUrl = 'https://www.dereksbgglive.com/api/privacy-policy/';

var navigatorKey = GlobalKey<NavigatorState>();
NavigatorMiddleware<PageRoute> middleware = NavigatorMiddleware<PageRoute>();
var currentRouteName = '';
var isInForeground = true;

dateDDMMYY(String apiDate) {
  // Parse it into a DateTime
  final DateTime? dateTime = DateTime.tryParse(apiDate);

  if (dateTime != null) {
    final DateFormat usFormat = DateFormat('MM/dd/yyyy');
    return usFormat.format(dateTime);
  }
}

Future<void> launchEmail() async {
  final Uri emailUri = Uri(scheme: 'mailto', path: "dereksbgglive@gmail.com");
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    debugPrint("Could not open email client");
  }
}

String podcastInviteDateTIme(String isoDate) {
  // Parse the ISO 8601 date string
  DateTime dateTime = DateTime.parse(isoDate);

  // Format the date to "December 12, 2024 12:00 PM"
  String formattedDate =
      DateFormat('MMMM dd, yyyy hh:mm a').format(dateTime.toLocal());

  return formattedDate;
}
