// Export mobile implementation if getuiflut is available, otherwise stub
export 'getui_push_mobile.dart'
    if (dart.library.html) 'getui_push_stub.dart';
