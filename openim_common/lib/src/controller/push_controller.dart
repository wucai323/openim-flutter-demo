import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:openim_common/openim_common.dart';

import 'firebase_options.dart';

// Conditional import for GeTui (only on mobile)
import 'package:getuiflut/getuiflut.dart' if (dart.library.html) 'push_controller_stub.dart';

enum PushType { GeTui, FCM, none }

const appID = 'ovKF2KkTmC99F7luUa2T06';
const appKey = 'bFUTJhLCkr7pfTWvJ0UCY4';
const appSecret = '5sLKQk42zxAMUjJHWETRr7';

class PushController extends GetxService {
  PushType pushType = PushType.GeTui;

  static void login(String alias, {void Function(String token)? onTokenRefresh}) {
    if (PushController().pushType == PushType.GeTui && (Platform.isAndroid || Platform.isIOS)) {
      GetuiPushController()._initialize(alias, onTokenRefresh);
    } else if (PushController().pushType == PushType.FCM) {
      assert((PushController().pushType == PushType.FCM && onTokenRefresh != null));

      FCMPushController()._initialize().then((_) {
        FCMPushController()._getToken().then((token) => onTokenRefresh!(token));
        FCMPushController()._listenToTokenRefresh((token) => onTokenRefresh);
      });
    }
  }

  static void logout() {
    if (PushController().pushType == PushType.GeTui && (Platform.isAndroid || Platform.isIOS)) {
      GetuiPushController()._unbindAlias();
    } else if (PushController().pushType == PushType.FCM) {
      FCMPushController()._deleteToken();
    }
  }
}

class GetuiPushController {
  static final GetuiPushController _instance = GetuiPushController._internal();
  factory GetuiPushController() => _instance;

  GetuiPushController._internal();

  Getuiflut? _getuiflut;

  Future<void> _initialize(String alias, void Function(String token)? onTokenRefresh) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      Logger.print("GeTui only supports Android/iOS");
      return;
    }

    _getuiflut = Getuiflut();
    
    await _getuiflut!.initGetuiSdk(
      appId: appID,
      appKey: appKey,
      appSecret: appSecret,
    );

    String? clientId = await _getuiflut!.getClientId();
    Logger.print("GeTui ClientID: $clientId");
    
    if (clientId != null && onTokenRefresh != null) {
      onTokenRefresh(clientId);
    }

    if (alias.isNotEmpty && clientId != null) {
      await _getuiflut!.bindAlias(alias, clientId);
      Logger.print("GeTui alias bound: $alias");
    }

    _getuiflut!.addEventHandler(
      onReceiveClientId: (String clientId) {
        Logger.print("GeTui ClientID received: $clientId");
        if (onTokenRefresh != null) {
          onTokenRefresh(clientId);
        }
      },
      onReceiveMessageData: (Map<String, dynamic> message) {
        Logger.print("GeTui message received: $message");
      },
      onNotificationMessageArrived: (Map<String, dynamic> message) {
        Logger.print("GeTui notification arrived: $message");
      },
      onNotificationMessageClicked: (Map<String, dynamic> message) {
        Logger.print("GeTui notification clicked: $message");
      },
    );
  }

  Future<void> _unbindAlias() async {
    if (_getuiflut == null) return;
    
    String? clientId = await _getuiflut?.getClientId();
    if (clientId != null) {
      await _getuiflut?.unbindAlias(clientId, true);
      Logger.print("GeTui alias unbound");
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
