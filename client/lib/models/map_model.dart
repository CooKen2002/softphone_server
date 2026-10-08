import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/string_utils.dart';

class PlaceMark {
  int placeID = 0;
  double x = 0;
  double y = 0;
  String description = "";
  bool monitoringMark = false;
  String englishName = "";
  String note = "";
  String textToSpeech = "";
  int iconID = 0;
  int radius = 0;
  DateTime? createDate;
  DateTime? updateDate;
  int textColor = 0;
  int voiceSize = 0;

  PlaceMark();

  factory PlaceMark.fromJson(Map<String, dynamic> json) {
    PlaceMark model = PlaceMark();
    model.placeID = json[F_PLACE_ID] ?? 0;
    model.x = json[F_X] ?? 0;
    model.y = json[F_Y] ?? 0;
    model.description = nvl(json[F_DESCRIPTION]);
    model.monitoringMark = json[F_MONITORING_MARK] ?? false;
    model.englishName = nvl(json[F_ENGLISH_NAME]);
    model.note = nvl(json[F_NOTE]);
    model.textToSpeech = nvl(json[F_TEXT_TO_SPEECH]);
    model.iconID = json[F_ICON_ID] ?? 0;
    model.radius = json[F_RADIUS] ?? 0;
    model.createDate = nvl(json[F_CREATE_DATE]).parseTz;
    model.updateDate = nvl(json[F_UPDATE_DATE]).parseTz;
    model.textColor = json[F_TEXT_COLOR] ?? 0;
    model.voiceSize = json[F_VOICE_SIZE] ?? 0;
    return model;
  }
}

class MapObjectsResponse extends ActionResult {
  List<PlaceMark> places = [];
  List<Vehicle> vehicles = [];

  MapObjectsResponse(super.errorCode, super.errorMessage);

  factory MapObjectsResponse.fromJson(Map<String, dynamic> json) {
    MapObjectsResponse response = MapObjectsResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    var placeMarks = json[F_PLACE_MARKS];
    if (placeMarks != null) {
      response.places = (placeMarks as List)
          .map((e) => PlaceMark.fromJson(e))
          .toList();
    }

    var vehicles = json[F_VEHICLES];
    if (vehicles != null) {
      response.vehicles = (vehicles as List)
          .map((e) => Vehicle.fromJson(e))
          .toList();
    }

    return response;
  }
}
