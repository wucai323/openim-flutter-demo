// Stub for non-mobile platforms
class Getuiflut {
  Future<void> initGetuiSdk({String? appId, String? appKey, String? appSecret}) async {}
  Future<String?> getClientId() async => null;
  Future<void> bindAlias(String alias, String clientId) async {}
  Future<void> unbindAlias(String clientId, bool isSelf) async {}
  void addEventHandler({
    Function(String)? onReceiveClientId,
    Function(Map<String, dynamic>)? onReceiveMessageData,
    Function(Map<String, dynamic>)? onNotificationMessageArrived,
    Function(Map<String, dynamic>)? onNotificationMessageClicked,
  }) {}
}
