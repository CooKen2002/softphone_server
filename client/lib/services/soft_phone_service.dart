import '../models/soft_phone_model.dart';
import '../utils/constants.dart';
import '../utils/global.dart';
import '../utils/http_service.dart';

class SoftPhoneService {
  Future<CallLogsResponse> listCallLogs(String fromDate, String toDate) async {
    String url = "$baseUrl/rest/app/listCallLogs";

    try {
      // Map<String, dynamic> map = {F_FROM_DATE: fromDate, F_TO_DATE: toDate};
      // final response = await httpService.post(url, body: map);
      final response = await httpService.post(url);
      return CallLogsResponse.fromJson(response);
    } on Exception catch (e) {
      return CallLogsResponse("FAIL", e.toString());
    }
  }

  Future<CallLogsResponse> storeCallLog(CallLog requestModel) async {
    String url = "$baseUrl/rest/app/storeCallLog";
    try {
      final response = await httpService.post(
        url,
        body: requestModel.toStoreCallLogJson(),
      );
      return CallLogsResponse.fromJson(response);
    } on Exception catch (e) {
      return CallLogsResponse("FAIL", e.toString());
    }
  }

  Future<CallLogsResponse> getCallContact(String phoneNo) async {
    String url = "$baseUrl/rest/app/getCallContact";

    try {
      Map<String, dynamic> map = {F_PHONE_NO: phoneNo};
      final response = await httpService.post(url, body: map);

      return CallLogsResponse.fromJson(response);
    } on Exception catch (e) {
      return CallLogsResponse("FAIL", e.toString());
    }
  }

  Future<CallContactsResponse> saveCallContact(
    String phoneNo,
    String token,
    String name,
  ) async {
    String url = "$baseUrl/rest/app/saveCallContact";

    try {
      Map<String, dynamic> map = {
        F_PHONE_NO: phoneNo,
        F_TOKEN: token,
        F_FULL_NAME: name,
      };
      final response = await httpService.post(url, body: map);

      return CallContactsResponse.fromJson(response);
    } on Exception catch (e) {
      return CallContactsResponse("FAIL", e.toString());
    }
  }
}
