import 'package:openim_common/openim_common.dart';

class GetuiPushImpl {
  static final GetuiPushImpl _instance = GetuiPushImpl._internal();
  factory GetuiPushImpl() => _instance;

  GetuiPushImpl._internal();

  Future<void> initialize(String alias, void Function(String token)? onTokenRefresh) async {
    Logger.print("GeTui not available on this platform");
  }

  Future<void> unbindAlias() async {}
}
