import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/models/limousine_model.dart';
import 'package:talkie_v2/models/vehicle_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/http_service.dart';

class LimousineService {
  Future<TruckLinesResponse> listTruckLines() async {
    String url = "$baseUrl/rest/shipping/listTruckLines";

    try {
      final response = await httpService.post(url, body: {});
      return TruckLinesResponse.fromJson(response);
    } on Exception catch (e) {
      return TruckLinesResponse("FAIL", e.toString());
    }
  }

  Future<VehiclesResponse> listVehicles() async {
    String url = "$baseUrl/rest/app/vehicle/listVehicles";

    try {
      final response = await httpService.post(url);
      return VehiclesResponse.fromJson(response);
    } catch (e) {
      return VehiclesResponse("FAIL", e.toString());
    }
  }

  Future<UsersResponse> listLimoUsers() async {
    String url = "$baseUrl/rest/limo/listLimoUsers";

    try {
      final response = await httpService.post(url);
      return UsersResponse.fromJson(response);
    } catch (e) {
      return UsersResponse("FAIL", e.toString());
    }
  }

  Future<PrepareLimoTripsResponse> prepareLimoTrips(LimoTrip trip) async {
    String url = "$baseUrl/rest/limo/prepareLimoTrips";
    try {
      final response = await httpService.post(url, body: trip.toJson());
      return PrepareLimoTripsResponse.fromJson(response);
    } on Exception catch (e) {
      return PrepareLimoTripsResponse("FAIL", e.toString());
    }
  }

  Future<LimoTripsResponse> generateLimoTrips(
    List<LimoTrip> trips,
    String token,
  ) async {
    String url = "$baseUrl/rest/limo/generateLimoTrips";
    try {
      Map<String, dynamic> map = {
        F_TRIPS: trips.map((e) => e.toPrepareLimoTrips()).toList(),
        F_TOKEN: token,
      };
      final response = await httpService.post(url, body: map);
      return LimoTripsResponse.fromJson(response);
    } on Exception catch (e) {
      return LimoTripsResponse("FAIL", e.toString());
    }
  }

  Future<LimoTripsResponse> searchTrips(
    int lineID,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    String url = "$baseUrl/rest/limo/searchTrips";

    try {
      Map<String, dynamic> map = {
        F_LINE_ID: lineID,
        F_FROM_DATE: fromDate.formatDateTimeTz(),
        F_TO_DATE: toDate.formatDateTimeTz(),
      };
      final response = await httpService.post(url, body: map);
      return LimoTripsResponse.fromJson(response);
    } on Exception catch (e) {
      return LimoTripsResponse("FAIL", e.toString());
    }
  }
}
