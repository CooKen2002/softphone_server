// // ignore_for_file: constant_identifier_names

// import 'dart:ffi';
// import 'dart:io';
// import 'dart:isolate';

// import 'package:ffi/ffi.dart';
// import 'package:path/path.dart' as path;
// import 'package:flutter/foundation.dart';

// typedef EventCallback = Void Function(Pointer<Utf8>);
// typedef EventCallbackDart = void Function(Pointer<Utf8>);

// typedef ExportIntPointer = Int32 Function(Pointer<Utf8>);
// typedef ExportIntPointerDart = int Function(Pointer<Utf8>);

// typedef ExportIntPoiterPointer = Int32 Function(Pointer<Utf8>, Pointer<Utf8>);
// typedef ExportIntPoiterPointerDart = int Function(Pointer<Utf8>, Pointer<Utf8>);

// typedef ExportInt = Int32 Function();
// typedef ExportIntDart = int Function();

// typedef ExportIntInt = Int32 Function(Int32);
// typedef ExportIntIntDart = int Function(int);

// typedef ExportVoid = Void Function();
// typedef ExportVoidDart = void Function();

// typedef GetModExportFunc = Int32 Function();
// typedef GetModExport = int Function();

// typedef UaNextFunc = void Function();
// typedef UaNext = void Function();
// //
// typedef CurrentAccountNative = Int32 Function(Pointer<Utf8>);
// typedef CurrentAccountDart = int Function(Pointer<Utf8>);

// typedef ExportPointerChar = Pointer<Utf8> Function();

// class BareSipReceiver {
//   static BareSipReceiver? _instance;
//   static BareSipReceiver get instance =>
//       _instance ??= BareSipReceiver._internal();

//   factory BareSipReceiver() => instance;

//   BareSipReceiver._internal() {
//     _initializeFunctions();
//   }

//   SendPort? _sendPort;
//   late final DynamicLibrary dylib;

//   late final void Function(Pointer<NativeFunction<EventCallback>>)
//   registerCallback;
//   late final ExportIntIntDart resetCountTerminal;
//   late final ExportIntDart resumeCall;
//   late final ExportIntDart unRegisterCallback;
//   late final ExportIntPoiterPointerDart covertToMp3;
//   late final GetModExport bareStart;
//   late final GetModExport bareAppInit;
//   late final GetModExport bareAppStart;
//   late final GetModExport bareStop;
//   late final ExportVoidDart bareUaExit;
//   late final GetModExport bareGetReMain;
//   late final GetModExport bareAnswer;
//   late final GetModExport hangupUA;
//   late final ExportIntPointerDart bareRegisterUA;
//   late final ExportPointerChar nextAccount;
//   late final ExportPointerChar getCurrentAccount;
//   late final ExportIntPointerDart connectUA;
//   late final ExportPointerChar getCurrentPath;
//   late final EventCallbackDart setPathRecord;
//   late final ExportPointerChar getMessageFromQueue;

//   late final Pointer<NativeFunction<EventCallback>> callbackPointer;

//   void _initializeFunctions() {
//     dylib = loadLibrary();

//     registerCallback = dylib
//         .lookup<
//           NativeFunction<Void Function(Pointer<NativeFunction<EventCallback>>)>
//         >('register_callback')
//         .asFunction();

//     resetCountTerminal = dylib
//         .lookup<NativeFunction<ExportIntInt>>('reset_count_terminal')
//         .asFunction();

//     resumeCall = dylib.lookup<NativeFunction<ExportInt>>('resume').asFunction();

//     // covertToMp3 = dylib
//     //     .lookup<NativeFunction<ExportIntPoiterPointer>>('convert_wav_to_mp3')
//     //     .asFunction();

//     bareStart = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('start')
//         .asFunction();

//     bareAppInit = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('app_init')
//         .asFunction();

//     bareAppStart = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('app_start')
//         .asFunction();

//     bareStop = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('stop')
//         .asFunction();

//     bareUaExit = dylib
//         .lookup<NativeFunction<ExportVoid>>('ua_exit')
//         .asFunction();

//     bareGetReMain = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('get_re_main')
//         .asFunction();

//     bareAnswer = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('answer')
//         .asFunction();

//     hangupUA = dylib
//         .lookup<NativeFunction<GetModExportFunc>>('hangupUA')
//         .asFunction();

//     bareRegisterUA = dylib
//         .lookup<NativeFunction<ExportIntPointer>>('registerUA')
//         .asFunction();

//     nextAccount = dylib
//         .lookup<NativeFunction<ExportPointerChar>>('nextAccount')
//         .asFunction();

//     getCurrentAccount = dylib
//         .lookup<NativeFunction<ExportPointerChar>>('getCurrentAccount')
//         .asFunction();

//     // Call - Gọi điện
//     connectUA = dylib
//         .lookup<NativeFunction<ExportIntPointer>>('connectUA')
//         .asFunction();

//     getCurrentPath = dylib
//         .lookup<NativeFunction<ExportPointerChar>>('getCurrentPath')
//         .asFunction();

//     setPathRecord = dylib
//         .lookup<NativeFunction<EventCallback>>('setPathRecord')
//         .asFunction();

//     getMessageFromQueue = dylib
//         .lookup<NativeFunction<ExportPointerChar>>("dequeue")
//         .asFunction();

//     callbackPointer = Pointer.fromFunction<EventCallback>(_handleEventStatic);
//   }

//   DynamicLibrary loadLibrary() {
//     String dllPath = "";
//     final exeDir = File(Platform.resolvedExecutable).parent.path;
//     if (kReleaseMode) {
//       dllPath = path.join(exeDir, 'data', 'flutter_assets', 'assets', 'dll');
//     } else {
//       dllPath = path.join(Directory.current.path, 'assets', 'dll');
//     }
//     // dllPath = path.join(exeDir, 'data', 'flutter_assets', 'assets', 'dll');
//     String libsndfileDllPath = path.join(dllPath, "sndfile.dll");
//     String baresipDllPathth = path.join(dllPath, "baresip-window.dll");
//     DynamicLibrary.open(libsndfileDllPath);
//     DynamicLibrary lib = DynamicLibrary.open(baresipDllPathth);
//     return lib;
//   }

//   // Static callback handler - required for FFI
//   static void _handleEventStatic(Pointer<Utf8> message) {
//     final dartString = message.toDartString();
//     instance._sendPort?.send(dartString);
//   }

//   void eventIsolate(Map<String, dynamic> args) {
//     _sendPort = args['sendPort'];

//     // Gửi Port cho SoftPhone
//     ReceivePort receivePort = ReceivePort();
//     _sendPort!.send(receivePort.sendPort);

//     receivePort.listen((message) {
//       // Nhận lệnh từ SoftPhone{
//       if (message is String) {
//       } else if (message is CmdSoftPhone) {
//         processCMD(message);
//       } else if (message is Map) {
//         processMap(message);
//       } else if (message is SendPort) {
//       } else if (message is String) {
//         if (message == "END") {
//           Isolate.exit();
//         }
//       }
//     });

//     try {
//       bareAppInit();
//     } catch (e) {
//       if (kDebugMode) {
//         print(e);
//       }
//     }
//   }

//   void registerCallBack() {
//     registerCallback(callbackPointer);
//   }

//   void unRegisterCallBack() {
//     registerCallback(nullptr);
//   }

//   Future<void> callUser(String phoneNum) async {
//     connectUA(phoneNum.toNativeUtf8());
//     // connectUA("sip:$phoneNum@203.171.21.51".toNativeUtf8());
//   }

//   void reCAll(String userId) {
//     connectUA("sip:$userId@203.171.21.51".toNativeUtf8());
//   }

//   void register(String uri) {
//     bareRegisterUA(uri.toNativeUtf8());
//   }

//   String getCurrentNumber() {
//     String result = "";
//     Pointer<Utf8> temp = getCurrentAccount();
//     if (temp != nullptr) {
//       result = temp.toDartString();
//     }
//     return result;
//   }

//   void processMap(Map map) {
//     CmdSoftPhone msg = map["cmd"];
//     String arg = map["arg"];
//     switch (msg) {
//       case CmdSoftPhone.CMD_RE_INIT:
//         bareAppInit();
//         break;
//       case CmdSoftPhone.CMD_RE_MAIN:
//         getReMain();
//         break;
//       case CmdSoftPhone.CMD_UA_REGISTER:
//         register(arg);
//         break;
//       case CmdSoftPhone.CMD_UA_START:
//         bareAppStart();
//         break;
//       case CmdSoftPhone.CMD_UA_NEXT:
//         nextAccount();
//         break;
//       case CmdSoftPhone.CMD_UA_RESUME:
//         resumeCall();
//         break;
//       default:
//     }
//   }

//   void getReMain() {
//     try {
//       bareGetReMain();
//     } catch (e) {
//       if (kDebugMode) {
//         print("getReMain: $e");
//       }
//     }
//   }

//   void processCMD(CmdSoftPhone msg) {
//     // Implementation placeholder
//   }

//   void processString(String msg) {
//     // Implementation placeholder
//   }
// }

// enum CmdSoftPhone {
//   CMD_RE_INIT,
//   CMD_RE_MAIN,
//   CMD_UA_INIT,
//   CMD_UA_REGISTER,
//   CMD_UA_START,
//   CMD_UA_STOP,
//   CMD_UA_NEXT,
//   CMD_UA_CUR,
//   CMD_UA_RESUME,
//   CMD_CALL_OUT,
//   CMD_CALL_IN,
//   CMD_CALL_CLOSED,
//   CMD_CALL_ESTABLISHED,
//   CMD_CALL_HANGUP,
// }
