import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkie_v2/utils/constants.dart';

extension StartOfDay on DateTime {
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0, 0);
}

extension FirstDayOfMonth on DateTime {
  DateTime get firstDayOfMonth => DateTime(year, month, 1, 0, 0, 0, 0);
}

extension EndOfDay on DateTime {
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 0);
}

extension FormatTime on DateTime {
  String get formatTime => DateFormat(TIME_FORMAT).format(this);
}

extension FormatDateTime on DateTime {
  String get formatDateTime => DateFormat(DATE_TIME_FORMAT).format(this);
}

extension FormatTimeDate on DateTime {
  String get formatTimeDate => DateFormat(TIME_DATE_FORMAT).format(this);
}

extension FormatShortDateTime on DateTime {
  String get formatShortDateTime => DateFormat("dd/MM HH:mm:ss").format(this);
}

extension FormatHHmm on DateTime {
  String get formatHHmm => DateFormat("HH:mm").format(this);
}

extension FormatHH00 on DateTime {
  String get formatHH00 => "${DateFormat("HH").format(this)}:00";
}

extension FormatDate on DateTime {
  String get formatDate => DateFormat(DATE_FORMAT).format(this);
}

extension FormatMonth on DateTime {
  String get formatMonth => DateFormat("MM/yyyy").format(this);
}

extension FormatToMinute on DateTime {
  String get formatToMinute => DateFormat("dd/MM/yyyy HH:mm").format(this);
}

extension FormatToMinuteTime on DateTime {
  String get formatToMinuteTime => DateFormat("HH:mm dd/MM").format(this);
}

extension FormatDateTimeCompact on DateTime {
  String get formatDateTimeCompact =>
      DateFormat("yyyyMMdd_HHmmss").format(this);
}

extension FormatDateTimeTz on DateTime {
  //String get formatDateTimeTz => DateFormat(DATE_TIME_TZ_FORMAT).format(this);
  String formatDateTimeTz() {
    var dateTime = this;
    //var val = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateTime);
    var val = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateTime);
    var offset = dateTime.timeZoneOffset;
    var hours = offset.inHours > 0
        ? offset.inHours
        : 1; // For fixing divide by 0

    if (!offset.isNegative) {
      val =
          "$val+${offset.inHours.toString().padLeft(2, '0')}${(offset.inMinutes % (hours * 60)).toString().padLeft(2, '0')}";
    } else {
      val =
          "$val-${(-offset.inHours).toString().padLeft(2, '0')}${(offset.inMinutes % (hours * 60)).toString().padLeft(2, '0')}";
    }

    return val;
  }
}

extension FormatTimeTimeOfDay on TimeOfDay {
  String toTextTime() {
    String addLeadingZeroIfNeeded(int value) {
      if (value < 10) return '0$value';
      return value.toString();
    }

    final String hourLabel = addLeadingZeroIfNeeded(hour);
    final String minuteLabel = addLeadingZeroIfNeeded(minute);

    return '$hourLabel:$minuteLabel';
  }
}

extension TextTime on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String textTime() {
    DateTime now = DateTime.now();

    int diff = ((now.millisecondsSinceEpoch - millisecondsSinceEpoch) / 1000)
        .round();

    if (diff > (24 * 60 * 60)) {
      return formatDate;
    }

    if (diff > (1 * 60 * 60)) {
      int hour = (diff / (60 * 60)).floor();
      return "$hour giờ";
    }

    if (diff > 60) {
      int minutes = (diff / 60).floor();
      return "$minutes phút";
    }

    return "$diff giây";
  }
}

extension TextTimeOnInt on int {
  String textTime() {
    int value = this;
    if (value < 60) {
      return "${value}s";
    } else {
      int duration = (value / 60).floor(); //to minute
      int day = (duration / (24 * 60)).floor(); //to day
      duration = duration - (day * 24 * 60); //remain minutes
      int hour = (duration / 60).floor(); //remain hour
      duration = duration - (hour * 60);
      int minute = duration;

      //print("time: ${day}n${hour}h${minute}p  - value: $value");

      if (day > 0) {
        return "${day}n${hour}h";
      } else if (hour > 0) {
        return "${hour}h${minute}p";
      } else {
        return "${minute}p";
      }
    }
  }

  String textTimeHHmmss() {
    var f = NumberFormat("00", "en_US");
    int value = this;
    if (value < 60) {
      return "00:00:${f.format(value)}";
    } else {
      int duration = value;
      int hour = (duration / (60 * 60)).floor(); //remain hour
      duration = duration - (hour * 60 * 60);
      int minute = (duration / 60).floor();
      duration = duration - (minute * 60);
      int second = duration;

      return "${f.format(hour)}:${f.format(minute)}:${f.format(second)}";
    }
  }

  String textTimeHHmm() {
    var f = NumberFormat("00", "en_US");
    int value = this;
    if (value < 60) {
      return "00:00";
    } else {
      int duration = value;
      int hour = (duration / (60 * 60)).floor(); //remain hour
      duration = duration - (hour * 60 * 60);
      int minute = (duration / 60).floor();
      // duration = duration - (minute * 60);

      return "${f.format(hour)}:${f.format(minute)}";
    }
  }

  String textTimemmss() {
    var f = NumberFormat("00", "en_US");
    int value = this;
    if (value < 60) {
      return "00:${f.format(value)}";
    } else {
      int duration = value;
      int minute = (duration / 60).floor();
      duration = duration - (minute * 60);
      int second = duration;

      return "${f.format(minute)}:${f.format(second)}";
    }
  }
}
