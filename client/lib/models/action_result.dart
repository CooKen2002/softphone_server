import '../utils/constants.dart';
import '../utils/string_utils.dart';

class ActionResult {
  String errorCode;
  String errorMessage;

  ActionResult(this.errorCode, this.errorMessage);

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    ActionResult response = ActionResult(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    return response;
  }
}
