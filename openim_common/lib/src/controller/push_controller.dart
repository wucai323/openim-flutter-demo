import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:openim_common/openim_common.dart';

import 'firebase_options.dart';

enum PushType { FCM, none }

class PushController extends GetxService {
  PushType pushType = PushType.none;

  static void login(String alias, {void Function(String token)? onTokenRefresh}) {
    if (PushController().pushType == PushType.FCM) {
      assert((PushController().pushType == PushType.FCM && onTokenRefresh != null));

      FCMPushController()._initialize().then((_) {
        FCMPushController()._getToken().then((token) => onTokenRefresh!(token));
        FCMPushController()._listenToTokenRefresh((token) => onTokenRefresh);
      });
    }
  }

  static void logout() {
    if (PushController().pushType == PushType.FCM) {
      FCMPushController()._deleteToken();
    }
  }
}

class FCMPushController {
  static final FCMPushController _instance = FCMPushController._internal();
  factory FCMPushController() => _instance;

  FCMPushController._internal();

  Future<void> _initialize() async {
    GooglePlayServicesAvailability? availability = GooglePlayServicesAvailability.success;
    if (Platform.isAndroid) {
      availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
    }
    if (availability != GooglePlayServicesAvailability.serviceInvalid) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      Logger.print('Google Play Services are not available');
      return;
    }

    await _requestPermission();

    _configureForegroundNotification();

    _configureBackgroundNotification();

    return;
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    print('User granted permission: \${settings.authorizationStatus}');
  }

  void _configureForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground notification received: \${message.notification?.title}');

      if (message.notification != null) {}
    });
  }

  void _configureBackgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background: \${message.notification?.title}');
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state: \${message.notification?.title}');
      }
    });
  }

  Future<String> _getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    Logger.print("FCM Token: $token");

    if (token == null) {
      throw Exception('FCM Token is null');
    }

    return token;
  }

  Future<void> _deleteToken() {
    return FirebaseMessaging.instance.deleteToken();
  }

  void _listenToTokenRefresh(void Function(String token) onTokenRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      print("FCM Token refreshed: $newToken");
      onTokenRefresh(newToken);
    });
  }
}
