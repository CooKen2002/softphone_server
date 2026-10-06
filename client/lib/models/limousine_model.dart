import 'package:talkie_v2/models/action_result.dart';
import 'package:talkie_v2/models/map_model.dart';
import 'package:talkie_v2/utils/constants.dart';
import 'package:talkie_v2/utils/date_utils.dart';
import 'package:talkie_v2/utils/string_utils.dart';

class TruckLine {
  int lineID = 0;
  String description = "";

  TruckLine();

  factory TruckLine.fromJson(Map<String, dynamic> json) {
    TruckLine model = TruckLine();
    model.lineID = json[F_LINE_ID];
    model.description = nvl(json[F_DESCRIPTION]);

    return model;
  }
}

class TruckLinesResponse extends ActionResult {
  List<TruckLine> truckLines = [];

  TruckLinesResponse(super.errorCode, super.errorMessage);

  factory TruckLinesResponse.fromJson(Map<String, dynamic> json) {
    TruckLinesResponse response = TruckLinesResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    var truckLines = json[F_TRUCK_LINES];
    if (truckLines != null) {
      response.truckLines = (truckLines as List)
          .map((e) => TruckLine.fromJson(e))
          .toList();
    }

    return response;
  }
}

class LimoTrip {
  int tripID = 0;
  int lineID = 0;
  int vehicleID = 0;
  String plateNo = "";
  String description = "";
  String creator = "";
  DateTime? createDate;
  String token = "";
  int customerID = 0;
  int maxTicketID = 0;
  String note = "";
  int capacity = 0;
  int numOfBooked = 0;
  int driverID = 0;
  String driverName = "";
  String checkUrl = "";
  List<PlaceMark> placeMarks = [];
  List<Matrix> matrixes = [];
  int interval = 0;
  int minTrips = 0;
  int maxTrips = 0;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? departureDate;
  int roundDuration = 0;
  int count = 0;

  LimoTrip();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_LINE_ID: lineID,
      F_INTERVAL: interval,
      F_MIN_TRIPS: minTrips,
      F_MAX_TRIPS: maxTrips,
      F_START_DATE: startDate!.formatDateTimeTz(),
      F_END_DATE: endDate!.formatDateTimeTz(),
      F_ROUND_DURATION: roundDuration,
      F_COUNT: count,
    };
    return map;
  }

  Map<String, dynamic> toPrepareLimoTrips() {
    Map<String, dynamic> map = {
      F_MIN_TRIPS: minTrips,
      F_MAX_TRIPS: maxTrips,
      F_DEPARTURE_DATE: departureDate?.formatDateTimeTz(),
      F_COUNT: count,
    };
    return map;
  }

  factory LimoTrip.fromPrepareLimoTrips(Map<String, dynamic> json) {
    LimoTrip model = LimoTrip();

    model.minTrips = json[F_MIN_TRIPS] ?? 0;
    model.maxTrips = json[F_MAX_TRIPS] ?? 0;
    model.count = json[F_COUNT] ?? 0;
    if (json[F_DEPARTURE_DATE] != null) {
      model.departureDate = nvl(json[F_DEPARTURE_DATE]).parseTz;
    }

    return model;
  }

  factory LimoTrip.fromJson(Map<String, dynamic> json) {
    LimoTrip model = LimoTrip();

    model.tripID = json[F_TRIP_ID] ?? 0;
    model.lineID = json[F_LINE_ID] ?? 0;
    model.vehicleID = json[F_VEHICLE_ID] ?? 0;
    model.plateNo = nvl(json[F_PLATE_NO]);
    model.description = nvl(json[F_DESCRIPTION]);
    model.creator = nvl(json[F_CREATOR]);

    if (json[F_DEPARTURE_DATE] != null) {
      model.departureDate = nvl(json[F_DEPARTURE_DATE]).parseTz;
    }

    if (json[F_CREATE_DATE] != null) {
      model.createDate = nvl(json[F_CREATE_DATE]).parseTz;
    }

    model.token = nvl(json[F_TOKEN]);
    model.customerID = json[F_CUSTOMER_ID] ?? 0;
    model.maxTicketID = json[F_MAX_TICKET_ID] ?? 0;
    model.note = nvl(json[F_NOTE]);
    model.capacity = json[F_CAPACITY] ?? 0;
    model.numOfBooked = json[F_NUM_OF_BOOKED] ?? 0;
    model.driverID = json[F_DRIVER_ID] ?? 0;
    model.driverName = nvl(json[F_DRIVER_NAME]);
    model.checkUrl = nvl(json[F_CHECK_URL]);
    if (json[F_PLACE_MARKS] != null) {
      model.placeMarks = (json[F_PLACE_MARKS] as List)
          .map((e) => PlaceMark.fromJson(e))
          .toList();
    }
    if (json[F_MATRIX] != null) {
      model.matrixes = (json[F_MATRIX] as List)
          .map((e) => Matrix.fromJson(e))
          .toList();
    }

    return model;
  }
}

class PrepareLimoTripsResponse extends ActionResult {
  List<LimoTrip> trips = [];
  String token = "";

  PrepareLimoTripsResponse(super.errorCode, super.errorMessage);

  factory PrepareLimoTripsResponse.fromJson(Map<String, dynamic> json) {
    PrepareLimoTripsResponse response = PrepareLimoTripsResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    if (json[F_TRIPS] != null) {
      response.trips = (json[F_TRIPS] as List)
          .map((e) => LimoTrip.fromPrepareLimoTrips(e))
          .toList();
    }
    response.token = nvl(json[F_TOKEN]);

    return response;
  }
}

class Matrix {
  String key = "";
  int count = 0;
  int mTicketCount = 0;
  int countFree = 0;
  int countPromotion = 0;
  int countPrepaid = 0;
  int countPromotionPrepaid = 0;
  int price = 0;
  int promotionPrice = 0;
  int mTicketPrice = 0;
  int shippingFee = 0;
  int fromPlaceID = 0;
  int toPlaceID = 0;
  String fromPlaceName = "";
  String toPlaceName = "";
  bool checked = false;
  bool invalid = false;
  bool free = false;
  bool promotion = false;
  int checkerID = 0;
  int lineID = 0;
  String lineName = "";

  Matrix();

  factory Matrix.fromJson(Map<String, dynamic> json) {
    Matrix response = Matrix();

    response.key = nvl(json[F_KEY]);
    response.count = json[F_COUNT] ?? 0;
    response.mTicketCount = json[F_MTICKET_COUNT] ?? 0;
    response.countFree = json[F_COUNT_FREE] ?? 0;
    response.countPromotion = json[F_COUNT_PROMOTION] ?? 0;
    response.countPromotionPrepaid = json[F_COUNT_PROMOTION_PREPAID] ?? 0;
    response.countPrepaid = json[F_COUNT_PREPAID] ?? 0;
    response.price = json[F_PRICE] ?? 0;
    response.promotionPrice = json[F_PROMOTION_PRICE] ?? 0;
    response.mTicketPrice = json[F_M_TICKET_PRICE] ?? 0;
    response.checked = json[F_CHECKED] ?? false;
    response.invalid = json[F_INVALID] ?? false;
    response.checkerID = json[F_CHECKER_ID] ?? 0;
    response.shippingFee = json[F_SHIPPING_FEE] ?? 0;
    response.lineID = json[F_LINE_ID] ?? 0;
    response.lineName = nvl(json[F_LINE_NAME]);
    response.fromPlaceName = nvl(json[F_FROM_PLACE_NAME]);
    response.toPlaceName = nvl(json[F_TO_PLACE_NAME]);

    return response;
  }
}

class LimoTripsResponse extends ActionResult {
  List<LimoTrip> trips = [];

  LimoTripsResponse(super.errorCode, super.errorMessage);

  factory LimoTripsResponse.fromJson(Map<String, dynamic> json) {
    LimoTripsResponse response = LimoTripsResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (response.errorMessage.isNotEmpty) {
      return response;
    }

    if (json[F_TRIPS] != null) {
      response.trips = (json[F_TRIPS] as List)
          .map((e) => LimoTrip.fromJson(e))
          .toList();
    }

    return response;
  }
}
