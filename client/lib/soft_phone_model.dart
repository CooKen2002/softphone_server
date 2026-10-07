// // ignore_for_file: constant_identifier_names, camel_case_types

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:ffi';
// import 'dart:typed_data';

// import 'package:ffi/ffi.dart';
// import 'package:talkie_v2/models/action_result.dart';
// import 'package:talkie_v2/utils/constants.dart';
// import 'package:talkie_v2/utils/date_utils.dart';
// import 'package:talkie_v2/utils/string_utils.dart';
// import 'package:talkie_v2/utils/wave_file.dart';
// import 'package:vad/vad.dart';

// class CallLog {
//   int customerID = 0;
//   int userID = 0;
//   String userName = "";
//   String fullName = "";
//   String type = "";
//   bool starMark = false;
//   String fileID = "";
//   String fileName = "";
//   DateTime? createDate;
//   DateTime? startDate;
//   DateTime? endDate;
//   String callingNumber = "";
//   String calledNumber = "";
//   String callingName = "Unknow";
//   String calledName = "Unknow";
//   String token = "";
//   Uint8List? data;
//   //UI
//   bool isPlayBack = false;
//   bool isHover = false;
//   int indexPlay = -1;
//   String? pathFileRecord;

//   CallLog();

//   Map<String, dynamic> toStoreCallLogJson() {
//     Map<String, dynamic> map = {
//       F_ID: userID,
//       F_TYPE: type,
//       F_FILE_NAME: fileName,
//       F_START_DATE: startDate!.formatDateTimeTz(),
//       F_END_DATE: endDate!.formatDateTimeTz(),
//       F_CALLING_NUMBER: callingNumber,
//       F_CALLED_NUMBER: calledNumber,
//       F_CALLING_NAME: callingName,
//       F_CALLED_NAME: calledName,
//       F_FULL_NAME: fullName,
//       F_FILE_DATA: data != null ? base64.encoder.convert(data!) : null,
//     };
//     return map;
//   }

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> map = {
//       F_CUSTOMER_ID: customerID,
//       F_USER_ID: userID,
//       F_USER_NAME: userName,
//       F_FULL_NAME: fullName,
//       F_TYPE: type,
//       F_STAR_MARK: starMark,
//       F_FILE_ID: fileID,
//       F_FILE_NAME: fileName,
//       F_CREATE_DATE: createDate?.formatDateTimeTz(),
//       F_START_DATE: startDate,
//       F_END_DATE: endDate,
//       F_CALLING_NUMBER: callingNumber,
//       F_CALLED_NUMBER: calledNumber,
//       F_CALLING_NAME: callingName,
//       F_CALLED_NAME: calledName,
//       F_TOKEN: token,
//       F_PATH_FILE_RECORDED: pathFileRecord,
//       F_FILE_DATA: data,
//     };

//     return map;
//   }

//   factory CallLog.fromJson(Map<String, dynamic> json) {
//     CallLog model = CallLog();

//     model.customerID = json[F_CUSTOMER_ID] ?? 0;
//     model.userID = json[F_USER_ID] ?? 0;
//     model.userName = nvl(json[F_USER_NAME]);
//     model.fullName = nvl(json[F_FULL_NAME]);
//     model.type = nvl(json[F_TYPE]);
//     model.starMark = json[F_STAR_MARK] ?? false;
//     model.fileID = nvl(json[F_FILE_ID]);
//     model.fileName = nvl(json[F_FILE_NAME]);
//     model.createDate = nvl(json[F_CREATE_DATE]).parseTz;
//     model.startDate = nvl(json[F_END_DATE]).parseTz;
//     model.endDate = nvl(json[F_CREATE_DATE]).parseTz;
//     model.callingNumber = nvl(json[F_CALLING_NUMBER]);
//     model.calledNumber = nvl(json[F_CALLED_NUMBER]);

//     String callingName = nvl(json[F_CALLING_NAME]);
//     model.callingName = callingName.isNotEmpty ? callingName : "Unknow";

//     String calledName = nvl(json[F_CALLED_NAME]);
//     model.calledName = calledName.isNotEmpty ? calledName : "Unknow";
//     model.token = nvl(json[F_TOKEN]);
//     model.pathFileRecord = nvl(json[F_PATH_FILE_RECORDED]);

//     return model;
//   }

//   String getPhoneNo() {
//     String phoneNo = type;
//     if (phoneNo.isEmpty) return phoneNo;
//     if (phoneNo == TYPE_IN || phoneNo == TYPE_FIN) {
//       phoneNo = callingNumber;
//     } else if (phoneNo == TYPE_OUT || phoneNo == TYPE_FOUT) {
//       phoneNo = calledNumber;
//     }
//     return phoneNo;
//   }

//   void setPhoneName(String name) {
//     if (type == TYPE_IN || type == TYPE_FIN) {
//       callingName = name;
//     } else if (type == TYPE_OUT || type == TYPE_FOUT) {
//       calledName = name;
//     }
//   }

//   String getPhoneName() {
//     String phoneName = type;
//     if (phoneName == TYPE_IN || phoneName == TYPE_FIN) {
//       phoneName = callingName;
//     } else if (phoneName == TYPE_OUT || phoneName == TYPE_FOUT) {
//       phoneName = calledName;
//     }
//     return phoneName;
//   }
// }

// class CallLogsResponse extends ActionResult {
//   CallLog callLog = CallLog();
//   List<CallLog> callLogs = [];

//   CallLogsResponse(super.errorCode, super.errorMessage);

//   factory CallLogsResponse.fromJson(Map<String, dynamic> json) {
//     CallLogsResponse response = CallLogsResponse(nvl(json[F_ERROR_CODE]), nvl(json[F_ERROR_MESSAGE]));

//     if (response.errorMessage.isNotEmpty) {
//       return response;
//     }

//     if (json[F_LOG] != null) {
//       response.callLog = CallLog.fromJson(json[F_LOG]);
//     }

//     var logs = json[F_LOGS];
//     if (logs != null) {
//       response.callLogs = (logs as List).map((e) => CallLog.fromJson(e)).toList();
//     }

//     return response;
//   }
// }
// // MARK: UA
// class UA {
//   STATUS_UA status = STATUS_UA.NOTCONNECT;
//   String? server;
//   String? hotLine;
//   String? name;
//   String? exprires;
//   String? pass;
//   PROTOCOL_UA? protocol;
//   bool? autoConnect;
//   String? outBound;

//   // UI
//   bool showPass = true;
//   UA();

//   factory UA.fromJson(Map<String, dynamic> json) {
//     UA model = UA();
//     model.server = json[F_SOFTPHONE_REGISTER_SERVER] ?? "";
//     model.name = json[F_SOFTPHONE_NAME] ?? "";
//     model.hotLine = json[F_SOFTPHONE_USER] ?? "";
//     model.exprires = json[F_SOFTPHONE_REGISTRATION_EXPIRES] ?? "";
//     model.pass = json[F_SOFTPHONE_PASSWORD] ?? "";
//     model.autoConnect = json[F_SOFTPHONE_AUTOCONNECT] ?? false;
//     model.protocol = PROTOCOL_UA.values[json[F_SOFTPHONE_PROTOCOL] ?? 0];
//     model.outBound = json[F_SOFTPHONE_OUTBOUND] ?? "";
//     return model;
//   }

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> map = {
//       F_SOFTPHONE_REGISTER_SERVER: server ?? "",
//       F_SOFTPHONE_USER: hotLine ?? "",
//       F_SOFTPHONE_NAME: name ?? "",
//       F_SOFTPHONE_REGISTRATION_EXPIRES: exprires ?? "",
//       F_SOFTPHONE_PASSWORD: pass ?? "",
//       F_SOFTPHONE_AUTOCONNECT: autoConnect ?? false,
//       F_SOFTPHONE_STATUS: status.index,
//       F_SOFTPHONE_PROTOCOL: protocol?.index ?? PROTOCOL_UA.DEFAULT.index,
//       F_SOFTPHONE_OUTBOUND: outBound,
//     };

//     return map;
//   }

//   Map<String, dynamic> toJsonEq() {
//     Map<String, dynamic> map = {
//       F_SOFTPHONE_REGISTER_SERVER: server,
//       F_SOFTPHONE_USER: hotLine,
//       F_SOFTPHONE_NAME: name,
//       F_SOFTPHONE_REGISTRATION_EXPIRES: exprires,
//       F_SOFTPHONE_PASSWORD: pass,
//       F_SOFTPHONE_PROTOCOL: protocol?.index ?? PROTOCOL_UA.DEFAULT.index,
//       F_SOFTPHONE_OUTBOUND: outBound,
//     };

//     return map;
//   }

//   bool checkEqualUaModel(UA obj) {
//     bool result = false;
//     if (obj.toJsonEq().toString() == toJsonEq().toString()) {
//       result = true;
//     }
//     return result;
//   }

//   String getUri() {
//     if (hotLine!.isEmpty || pass!.isEmpty || server!.isEmpty) {
//       return "";
//     }

//     String uri = "<sip:$hotLine@$server>;auth_pass=$pass";
//     return uri;
//   }
// }

// enum STATUS_UA { NOTCONNECT, CONNECTED, INUSE, WAITING }

// enum PROTOCOL_UA { DEFAULT, UDP, TCP, TLS }

// // MARK: AudioStreamReader
// class AudioStreamReader {
//   late Pointer<Void> _ringBufferPtr;
//   int frameSamples = 320;
//   Timer? _timer;

//   // Các hàm callback
//   Function(Uint8List data)? dataOnVAD;
//   Function(Uint8List data)? dataOnVOSK;
//   Function(Uint8List data)? dataOnFile;

//   // Các hàm FFI đã lookup từ DLL
//   late final Pointer<Uint8> Function(Pointer<Void>) _arbPeek;
//   late final void Function(Pointer<Void>) _arbConsume;
//   late final void Function(Pointer<Void>) _arbReset;
//   late final Pointer<Void> Function() getRingBufferPtr;

//   AudioStreamReader(DynamicLibrary? dylib) {
//     if (dylib == null) return;
//     _arbPeek = dylib.lookupFunction<Pointer<Uint8> Function(Pointer<Void>), Pointer<Uint8> Function(Pointer<Void>)>('rx_arb_peek');
//     _arbConsume = dylib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('rx_arb_consume');
//     _arbReset = dylib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('rx_arb_reset');
//     getRingBufferPtr = dylib.lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>('get_rx_ring_buffer_ptr');
//     _ringBufferPtr = getRingBufferPtr();
//   }

//   // Nhận vào
//   void _readBuffer() {
//     final ptr = _arbPeek(_ringBufferPtr);
//     if (ptr.address == 0) {
//       // print("ptr.address empty");
//       return; // buffer empty
//     }
//     // Copy từ native sang Dart
//     final frame = ptr.asTypedList(frameSamples);

//     // Tạo bản copy an toàn (rất quan trọng)
//     final safeCopy = Uint8List.fromList(frame);

//     dataOnFile?.call(safeCopy);
//     dataOnVOSK?.call(safeCopy);
//     dataOnVAD?.call(safeCopy);
//     // Consume sau khi copy
//     _arbConsume(_ringBufferPtr);
//   }

//   void startReading() {
//     _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
//       _readBuffer();
//     });
//   }

//   void stop() {
//     _timer?.cancel();
//     _arbReset(_ringBufferPtr);
//   }
// }

// class AudioStreamWriter {
//   late Pointer<Void> _ringBufferPtr;
//   int frameSamples = 320;
//   Timer? interval;

//   // Các hàm FFI đã lookup từ DLL
//   late final Pointer<Void> Function() getRingBufferPtr;
//   late void Function(Pointer<Void>, Pointer<Void>) _arbPush;
//   late void Function(Pointer<Void>) _arbReset;

//   AudioStreamWriter(DynamicLibrary? dylib) {
//     if (dylib == null) return;
//     _arbPush = dylib.lookupFunction<Void Function(Pointer<Void>, Pointer<Void>), void Function(Pointer<Void>, Pointer<Void>)>('push_tx_ring_buffer_ptr');
//     _arbReset = dylib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('tx_arb_reset');
//     getRingBufferPtr = dylib.lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>('get_tx_ring_buffer_ptr');
//     _ringBufferPtr = getRingBufferPtr();
//   }

//   // Stop send frame
//   void stopSendFrame(){
//     interval?.cancel();
//   }

//   // read file
//   void readFileSendFrame(String filePath) async {
//     Uint8List audioBytes = await WavFile.readRawPcmOnly(filePath);
//     return readDataSendFrame(audioBytes);
//   }

//   void readDataSendFrame(Uint8List rawPcm) {
//     int pos = 0;
//     stopSendFrame();
//     interval = Timer.periodic(const Duration(milliseconds: 20), (timer) {
//       if (pos > rawPcm.length) {
//         timer.cancel();
//         return;
//       }
//       pushAudioFrame(Uint8List.fromList(rawPcm.getRange(pos, (pos + frameSamples) < rawPcm.length ? pos + frameSamples : rawPcm.length).toList()));
//       pos += frameSamples;
//     });
//   }

//   // Gửi đi
//   void pushAudioFrame(Uint8List frame) {
//     if (frame.isNotEmpty) {
//       final Pointer<Uint8> tempPtr = malloc.allocate<Uint8>(frame.length);
//       try {
//         tempPtr.asTypedList(frame.length).setAll(0, frame);
//         _arbPush(_ringBufferPtr, tempPtr.cast<Void>());
//       } catch (e) {
//         print("pushAudioFrame error");
//       } finally {
//         malloc.free(tempPtr);
//       }
//     }
//   }

//   void stop() {
//     _arbReset(_ringBufferPtr);
//   }
// }

// class VAD {
//   VadHandler? _vadHandler;
//   Stream<Uint8List>? audioStream;
//   Function(VadHandler vadHandler)? onListener;
  
//   static const int _frameSamples = 1536;
//   static const double _msPerFrame = _frameSamples / 16000 * 1000; // 96ms

//   void create() {
//     if (_vadHandler != null) return;
//     _vadHandler = VadHandler.create(isDebug: true);
//     onListener?.call(_vadHandler!);
//   }

//   void startListening({
//     double preRollMs = 5000,
//     double tailSilenceMs = 2000,
//     double positiveSpeechThreshold = 0.5,
//     double negativeSpeechThreshold = 0.35,
//     int minSpeechFrames = 4,
//   }) async {
//     try {
//       final int preSpeechPadFrames = (preRollMs / _msPerFrame).ceil();
//       final int redemptionFrames = (tailSilenceMs / _msPerFrame).ceil();

//       await _vadHandler?.startListening(
//         baseAssetPath: "assets/dll/",
//         audioStream: audioStream,
//         frameSamples: _frameSamples,
//         minSpeechFrames: minSpeechFrames,
//         preSpeechPadFrames: preSpeechPadFrames,
//         redemptionFrames: redemptionFrames,
//         positiveSpeechThreshold: positiveSpeechThreshold,
//         negativeSpeechThreshold: negativeSpeechThreshold,
//       );
//     } catch (e) {
//       log(e.toString());
//     }
//   }

//   void dispose() {
//     stopListening();
//     _vadHandler?.dispose();
//     _vadHandler = null;
//   }

//   void stopListening() async {
//     await _vadHandler?.stopListening();
//   }
// }

// enum STATE_SOFT_PHONE { INCOMING, OUTGOING, HISTORY, CONTACT }

// enum CALL_HISTORY_STATUS { IN_SUSSCESS, OUT_SUSSCESS, IN_FAILURE, OUT_FAILURE, DEFAULT }

// enum STATE_CALL { CALLING, ACCPECT, REFUSE, INVITED }

// class CallContact {
//   int customerID = 0;
//   String fullName = "";
//   String phoneNo = "";
//   DateTime? createDate;
//   CallContact();

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> map = {F_CUSTOMER_ID: customerID, F_FULL_NAME: fullName, F_CREATE_DATE: createDate?.formatDateTimeTz()};

//     return map;
//   }

//   factory CallContact.fromJson(Map<String, dynamic> json) {
//     CallContact model = CallContact();

//     model.customerID = json[F_CUSTOMER_ID] ?? 0;
//     model.fullName = nvl(json[F_FULL_NAME]);
//     model.phoneNo = nvl(json[F_PHONE_NO]);
//     model.createDate = nvl(json[F_CREATE_DATE]).parseTz;
//     return model;
//   }
// }

// class CallContactsResponse extends ActionResult {
//   CallContact? contact;
//   List<CallContact> contacts = [];

//   CallContactsResponse(super.errorCode, super.errorMessage);

//   factory CallContactsResponse.fromJson(Map<String, dynamic> json) {
//     CallContactsResponse response = CallContactsResponse(nvl(json[F_ERROR_CODE]), nvl(json[F_ERROR_MESSAGE]));

//     if (response.errorMessage.isNotEmpty) {
//       return response;
//     }

//     var messages = json[F_LOGS];
//     if (messages != null) {
//       response.contacts = (messages as List).map((e) => CallContact.fromJson(e)).toList();
//       // log("RequestCallLogResult: not null");
//     }

//     var message = json[F_CONTACT];
//     if (message != null) {
//       response.contact = CallContact.fromJson(message);
//     }

//     return response;
//   }
// }
