import 'dart:convert';
import 'dart:typed_data';

import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/models/login_model.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/http_service.dart';

class AdminService {
  Future<LoginResponse> login(LoginRequest requestModel) async {
    String url = "$baseUrl/rest/win/v2/login";
    try {
      final response = await httpService.post(url, body: requestModel.toJson());
      return LoginResponse.fromJson(response);
    } on Exception catch (e) {
      return LoginResponse("FAIL", e.toString());
    }
  }

  Future<VoiceMessagesResponse> listVoiceMessages() async {
    String url = "$baseUrl/rest/app/listVoiceMessages";

    try {
      final response = await httpService.post(url);
      return VoiceMessagesResponse.fromJson(response);
    } on Exception catch (e) {
      return VoiceMessagesResponse("FAIL", e.toString());
    }
  }

  Future<ActionResult> starMarkVoiceMessage(String id, bool starMark) async {
    String url = "$baseUrl/rest/app/starMarkVoiceMessage";

    try {
      Map<String, dynamic> map = {F_ID: id, F_STAR_MARK: starMark};
      final response = await httpService.post(url, body: map);
      return ActionResult.fromJson(response);
    } on Exception catch (e) {
      return ActionResult("FAIL", e.toString());
    }
  }

  Future<UsersResponse> listTalkieUsers() async {
    String url = "$baseUrl/rest/app/listTalkieUsers";

    try {
      final response = await httpService.post(url);
      return UsersResponse.fromJson(response);
    } on Exception catch (e) {
      return UsersResponse("FAIL", e.toString());
    }
  }

  Future<VoiceMessagesResponse> sendVoiceMessage(
    int toUserID,
    String fileName,
    Uint8List data,
    int duration,
  ) async {
    String url = "$baseUrl/rest/app/sendVoiceMessage";

    try {
      Map<String, dynamic> map = {
        F_TO_USER_ID: toUserID,
        F_FILE_NAME: fileName,
        F_DURATION: duration,
        F_FILE_DATA: base64.encoder.convert(data),
      };
      final response = await httpService.post(url, body: map);
      return VoiceMessagesResponse.fromJson(response);
    } on Exception catch (e) {
      return VoiceMessagesResponse("FAIL", e.toString());
    }
  }
}
