import 'package:getuiflut/getuiflut.dart';
import 'package:openim_common/openim_common.dart';

const appID = 'ovKF2KkTmC99F7luUa2T06';
const appKey = 'bFUTJhLCkr7pfTWvJ0UCY4';
const appSecret = '5sLKQk42zxAMUjJHWETRr7';

class GetuiPushImpl {
  static final GetuiPushController _instance = GetuiPushController._internal();
  factory GetuiPushController() => _instance;

  GetuiPushController._internal();

  Getuiflut? _getuiflut;

  Future<void> initialize(String alias, void Function(String token)? onTokenRefresh) async {
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

  Future<void> unbindAlias() async {
    if (_getuiflut == null) return;
    
    String? clientId = await _getuiflut?.getClientId();
    if (clientId != null) {
      await _getuiflut?.unbindAlias(clientId, true);
      Logger.print("GeTui alias unbound");
    }
  }
}
