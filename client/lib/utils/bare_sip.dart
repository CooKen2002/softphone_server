import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Define the callback type
typedef VoidFuncChar = Void Function(Pointer<Utf8>);
typedef VoidFuncCharDart = void Function(Pointer<Utf8>);

typedef PEventCallBack = Void Function(Pointer<NativeFunction<VoidFuncChar>>);
typedef PEventCallBackDart = void Function(Pointer<NativeFunction<VoidFuncChar>>);

typedef Poiter = Pointer<NativeFunction<VoidFuncChar>>;

typedef ExportVoid = Void Function();
typedef ExportVoidDart = void Function();

typedef PointerChar = Pointer<Uint8> Function();
typedef PointerCharDart = String Function();

typedef EventCallBackData = Void Function(Pointer<Utf8> data, Int32 len);
typedef EventCallBackDataDart = void Function(Pointer<Utf8> data, int len);

enum ActionUA { REGISTER, UNREGISTER, AUTOCONNECT, REGISTERING }

enum CMD_SOFTPHONE {
  CMD_RE_INIT,
  CMD_RE_MAIN,
  CMD_UA_INIT,
  CMD_UA_REGISTER,
  CMD_UA_START,
  CMD_UA_STOP,
  CMD_UA_NEXT,
  CMD_UA_CUR,
  CMD_UA_RESUME,
  CMD_CALL_OUT,
  CMD_CALL_IN,
  CMD_CALL_CLOSED,
  CMD_CALL_ESTABLISHED,
  CMD_CALL_HANGUP,

  CMD_APP_CLOSE,
  CMD_BARESIP_START,
  CMD_UA_NEW,
  CMD_UA_DEL,
}

base class MessageNative extends Struct {
  @Int32()
  external int type;

  @Int32()
  external int lenData;

  @Int32()
  external int lenName;

  @Array(128)
  external Array<Uint8> name;

  @Array(1024)
  external Array<Uint8> data;
}

class BareSip {
  String url_release = "baresip-window.dll";
  Timer? _timer;
  Function(int type, String name, List<int> msgByte)? onProcessCallBack;

  // Các hàm FFI đã lookup từ DLL
  late final void Function(Pointer<Utf8>) _uaNew;
  late final void Function(Pointer<Utf8>) _unRegister;
  late final void Function(Pointer<Utf8>) _hangup;
  late final void Function(Pointer<Utf8>) _answer;
  late final void Function(Pointer<Utf8>, Pointer<Utf8>) _dial;
  late final Pointer<MessageNative> Function() _dequeueMsg;
  late final void Function() _start;
  late final void Function() _stop;

  BareSip(DynamicLibrary? dylib) {
    if (dylib == null) {
      log("[BareSip] : lib null");
      return;
    }
    _uaNew = dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('ua_new');
    _unRegister = dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('ua_unRegister');
    _dial = dylib.lookupFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>), void Function(Pointer<Utf8>, Pointer<Utf8>)>('dial');
    _hangup = dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('hangup');
    _answer = dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('answer');
    _start = dylib.lookupFunction<Void Function(), void Function()>('libBaresip_init');
    _dequeueMsg = dylib.lookupFunction<Pointer<MessageNative> Function(), Pointer<MessageNative> Function()>('dequeue');
    _stop = dylib.lookupFunction<Void Function(), void Function()>('stop');
  }

  void uaNew(String sip) {
    log("uaNew: $sip");
    _uaNew(sip.toNativeUtf8());
  }

  void unRegister(String sip) {
    log("uaUnRegister: $sip");
    _unRegister(sip.toNativeUtf8());
  }

  void hangup(String sip) {
    log("hangup: $sip");
    _hangup(sip.toNativeUtf8());
  }

  void dial(String src, String des) {
    log("dial: $src -> $des");
    _dial(src.toNativeUtf8(), des.toNativeUtf8());
  }

  void answer(String src) {
    log("anwser: $src");
    _answer(src.toNativeUtf8());
  }

  void start() {
    _start();
  }

  void stop() {
    _timer?.cancel();
    _stop();
  }

  void startListener() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (timer) {
      Pointer<MessageNative> msgPtr = _dequeueMsg();
      if (msgPtr == nullptr) return;
      final msg = msgPtr.ref;
      int type = msg.type;
      int len = msg.lenName;
      List<int> nameBytes = [];
      for (int i = 0; i < len; i++) {
        if (msg.name[i] == 0) break;
        nameBytes.add(msg.name[i]);
      }
      String name = String.fromCharCodes(nameBytes);
      len = msg.lenData;
      List<int> dataByte = [];
      for (int i = 0; i < len; i++) {
        dataByte.add(msg.data[i]);
      }
      onProcessCallBack?.call(type, name, dataByte);
    });
  }
}
