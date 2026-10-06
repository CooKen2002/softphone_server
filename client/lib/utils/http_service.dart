import 'dart:convert';
import 'package:http/http.dart' as http;

final HttpService httpService = HttpService();

class HttpService {
  final JsonDecoder _decoder = const JsonDecoder();
  final JsonEncoder _encoder = const JsonEncoder();

  Map<String, String> headers = {"content-type": "application/json"};
  Map<String, String> cookies = {};

  void _updateCookie(http.Response response) {
    String? allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');

      for (var setCookie in setCookies) {
        var cookies = setCookie.split(';');

        for (var cookie in cookies) {
          _setCookie(cookie);
        }
      }

      headers['cookie'] = _generateCookieHeader();
    }
  }

  void _setCookie(String? rawCookie) {
    if (rawCookie != null) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];

        // ignore keys that aren't cookies
        if (key == 'path' || key == 'expires') return;

        cookies[key] = value;
      }
    }
  }

  String _generateCookieHeader() {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.isNotEmpty) cookie += ";";
      cookie += "$key=${cookies[key]!}";
    }

    return cookie;
  }

  Future<dynamic> get(String url) async {
    try {
      http.Response response = await http.get(Uri.parse(url), headers: headers);
      // .onError((error, stackTrace) => throw Exception(error));

      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e) {
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
    }
  }

  Future<dynamic> post(String url, {body, encoding}) async {
    String msg = body == null ? "{}" : _encoder.convert(body);
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        body: msg,
        headers: headers,
        encoding: encoding,
      );
      // .onError((error, stackTrace) => throw Exception(error));

      final String res = utf8.decode(response.bodyBytes);

      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e) {
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
      // return Future.error("Lỗi kết nối mạng!");
    }
  }

  // Future<dynamic> put(String url, {body, encoding}) async {
  //   http.Response response = await http
  //       .put(Uri.parse(url),
  //           body: _encoder.convert(body), headers: headers, encoding: encoding)
  //       .onError((error, stackTrace) => throw Exception(error));

  //   final String res = response.body;
  //   final int statusCode = response.statusCode;

  //   _updateCookie(response);

  //   if (statusCode == 200 || statusCode == 400) {
  //     try {
  //       if (res.isNotEmpty) {
  //         return _decoder.convert(res);
  //       } else {
  //         return _decoder.convert("{}");
  //       }
  //     } catch (e, stack) {
  //       print("stack: ${stack}");
  //       throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
  //     }
  //   } else {
  //     throw Exception("Error while fetching data");
  //   }
  // }
}
