import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/http_service.dart';

class MapService {
  Future<MapObjectsResponse> listMapObjects() async {
    String url = "$baseUrl/rest/app/v2/listMapObjects";
    try {
      Map<String, dynamic> params = {
        F_X: 21.052540945930936,
        F_Y: 105.78033683330521,
        F_FIREBASE_TOKEN: loginResponse.tokenID,
      };
      final response = await httpService.post(url, body: params);
      return MapObjectsResponse.fromJson(response);
    } on Exception catch (e) {
      return MapObjectsResponse("FAIL", e.toString());
    }
  }
}
