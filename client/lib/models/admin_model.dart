import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/string_utils.dart';

class User {
  int userID;
  String userName;
  String fullName = "";
  String userCode = "";
  String mobileNo = "";
  String mobileUI = "";
  int idx = 0;
  int allowAccessFrom = 0;
  bool locked = false;
  bool granted = false;
  bool origGranted = false;
  int rechargeQuota = 0;
  int rechargeRemain = 0;
  bool hybridOffline = false;
  bool disableSkymap = false;
  bool testTicket = false;
  bool enableOffline = false;
  bool callCenter = false;
  bool pulseChecker = false;
  bool ignoreNotification = false;
  bool requireApproveLogin = false;
  int bankID = 0;
  String bankBin = "";
  String bankAccountNo = "";
  String bankAccountName = "";

  User(this.userID, this.userName);

  factory User.fromJson(Map<String, dynamic> json) {
    User model = User(json[F_USER_ID] ?? 0, nvl(json[F_USER_NAME]));

    model.fullName = nvl(json[F_FULL_NAME]);
    model.userCode = nvl(json[F_USER_CODE]);
    model.mobileNo = nvl(json[F_MOBILE_NO]);
    model.mobileUI = nvl(json[F_MOBILE_UI]);
    model.idx = json[F_IDX] ?? 0;
    model.locked = json[F_LOCKED] ?? false;
    model.allowAccessFrom = json[F_ALLOW_ACCESS_FROM] ?? 0;
    model.granted = json[F_GRANTED] ?? false;
    model.origGranted = model.granted;
    model.bankID = json[F_BANK_ID] ?? 0;
    model.bankBin = nvl(json[F_BANK_BIN]);
    model.bankAccountNo = nvl(json[F_BANK_ACCOUNT_NO]);
    model.bankAccountName = nvl(json[F_BANK_ACCOUNT_NAME]);
    model.rechargeQuota = json[F_RECHARGE_QUOTA] ?? 0;
    model.rechargeRemain = json[F_RECHARGE_REMAIN] ?? 0;
    model.hybridOffline = json[F_HYBRID_OFFLINE] ?? false;
    model.ignoreNotification = json[F_IGNORE_NOTIFICATION] ?? false;
    model.testTicket = json[F_TEST_TICKET] ?? false;
    model.disableSkymap = json[F_DISABLE_SKYMAP] ?? false;
    model.callCenter = json[F_CALL_CENTER] ?? false;
    model.pulseChecker = json[F_PULSE_CHECKER] ?? false;
    model.enableOffline = json[F_ENABLE_OFFLINE] ?? false;
    model.requireApproveLogin = json[F_REQUIRE_APPROVE_LOGIN] ?? false;

    return model;
  }
}

class UsersResponse extends ActionResult {
  User? user;
  List<User> users = [];

  UsersResponse(super.errorCode, super.errorMessage);

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    UsersResponse response = UsersResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    var user = json[F_USER];
    if (user != null) {
      response.user = User.fromJson(user);
    }

    var users = json[F_USERS];
    if (users != null) {
      response.users = (users as List).map((e) => User.fromJson(e)).toList();
    }

    return response;
  }
}

class VoiceMessage {
  int userID = 0;
  int toUserID = 0;
  String fileName = "";
  String fullName = "";
  String id = "";
  String userName = "";
  int duration = 0;
  bool read = false;
  bool starMark = false;
  DateTime? createDate;

  VoiceMessage();

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    VoiceMessage model = VoiceMessage();

    model.userID = json[F_USER_ID] ?? 0;
    model.toUserID = json[F_TO_USER_ID] ?? 0;
    model.fileName = nvl(json[F_FILE_NAME]);
    model.fullName = nvl(json[F_FULL_NAME]);
    model.id = nvl(json[F_ID]);
    model.userName = nvl(json[F_USER_NAME]);
    model.duration = json[F_DURATION];
    model.read = json[F_READ] ?? false;
    model.starMark = json[F_STAR_MARK] ?? false;
    model.createDate = nvl(json[F_CREATE_DATE]).parseTz;

    return model;
  }
}

class VoiceMessagesResponse extends ActionResult {
  VoiceMessage message = VoiceMessage();
  List<VoiceMessage> messages = [];

  VoiceMessagesResponse(super.errorCode, super.errorMessage);

  factory VoiceMessagesResponse.fromJson(Map<String, dynamic> json) {
    VoiceMessagesResponse response = VoiceMessagesResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    var messages = json[F_MESSAGES];
    if (messages != null) {
      response.messages = (messages as List)
          .map((e) => VoiceMessage.fromJson(e))
          .toList();
    }

    var message = json[F_MESSAGE];
    if (message != null) {
      response.message = VoiceMessage.fromJson(message);
    }

    return response;
  }
}

enum TalkieRecordState { waiting, recording, upload, freeHand, delete }
