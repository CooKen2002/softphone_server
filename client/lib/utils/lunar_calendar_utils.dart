import 'dart:math';

/* Compute the (integral) Julian day number of day dd/mm/yyyy, i.e., the number 
 * of days between 1/1/4713 BC (Julian calendar) and dd/mm/yyyy. 
 * Formula from http://www.tondering.dk/claus/calendar.html
 */
int jdFromDate(int dd, int mm, int yy) {
  int a = ((14 - mm) / 12).toInt();
  int y = yy + 4800 - a;
  int m = mm + 12 * a - 3;
  int jd =
      dd +
      ((153 * m + 2) / 5).toInt() +
      365 * y +
      (y / 4).toInt() -
      (y / 100).toInt() +
      (y / 400).toInt() -
      32045;
  if (jd < 2299161) {
    jd = dd + ((153 * m + 2) / 5).toInt() + 365 * y + (y / 4).toInt() - 32083;
  }
  return jd;
}

/* Convert a Julian day number to day/month/year. Parameter jd is an integer */
List<int> jdToDate(int jd) {
  int b = 0;
  int c = 0;
  if (jd > 2299160) {
    // After 5/10/1582, Gregorian calendar
    int a = jd + 32044;
    b = ((4 * a + 3) / 146097).toInt();
    c = a - ((b * 146097) / 4).toInt();
  } else {
    c = jd + 32082;
  }
  int d = ((4 * c + 3) / 1461).toInt();
  int e = c - ((1461 * d) / 4).toInt();
  int m = ((5 * e + 2) / 153).toInt();
  int day = e - ((153 * m + 2) / 5).toInt() + 1;
  int month = m + 3 - 12 * (m / 10).toInt();
  int year = b * 100 + d - 4800 + (m / 10).toInt();
  return [day, month, year];
}

/* Compute the time of the k-th new moon after the new moon of 1/1/1900 13:52 UCT 
 * (measured as the number of days since 1/1/4713 BC noon UCT, e.g., 2451545.125 is 1/1/2000 15:00 UTC).
 * Returns a floating number, e.g., 2415079.9758617813 for k=2 or 2414961.935157746 for k=-2
 * Algorithm from: "Astronomical Algorithms" by Jean Meeus, 1998
 */
double newMoon(int k) {
  double t = k / 1236.85; // Time in Julian centuries from 1900 January 0.5
  double t2 = t * t;
  double t3 = t2 * t;
  double dr = pi / 180;
  double jd1 =
      2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
  jd1 =
      jd1 +
      0.00033 *
          sin((166.56 + 132.87 * t - 0.009173 * t2) * dr); // Mean new moon
  double m =
      359.2242 +
      29.10535608 * k -
      0.0000333 * t2 -
      0.00000347 * t3; // Sun's mean anomaly
  double mpr =
      306.0253 +
      385.81691806 * k +
      0.0107306 * t2 +
      0.00001236 * t3; // Moon's mean anomaly
  double f =
      21.2964 +
      390.67050646 * k -
      0.0016528 * t2 -
      0.00000239 * t3; // Moon's argument of latitude
  double c1 = (0.1734 - 0.000393 * t) * sin(m * dr) + 0.0021 * sin(2 * dr * m);
  c1 = c1 - 0.4068 * sin(mpr * dr) + 0.0161 * sin(dr * 2 * mpr);
  c1 = c1 - 0.0004 * sin(dr * 3 * mpr);
  c1 = c1 + 0.0104 * sin(dr * 2 * f) - 0.0051 * sin(dr * (m + mpr));
  c1 = c1 - 0.0074 * sin(dr * (m - mpr)) + 0.0004 * sin(dr * (2 * f + m));
  c1 = c1 - 0.0004 * sin(dr * (2 * f - m)) - 0.0006 * sin(dr * (2 * f + mpr));
  c1 = c1 + 0.0010 * sin(dr * (2 * f - mpr)) + 0.0005 * sin(dr * (2 * mpr + m));
  double deltat = 0;
  if (t < -11) {
    deltat =
        0.001 +
        0.000839 * t +
        0.0002261 * t2 -
        0.00000845 * t3 -
        0.000000081 * t * t3;
  } else {
    deltat = -0.000278 + 0.000265 * t + 0.000262 * t2;
  }

  double jdNew = jd1 + c1 - deltat;
  return jdNew;
}

/* Compute the longitude of the sun at any time. 
 * Parameter: floating number jdn, the number of days since 1/1/4713 BC noon
 * Algorithm from: "Astronomical Algorithms" by Jean Meeus, 1998
 */
double sunLongitude(double jdn) {
  double t =
      (jdn - 2451545.0) /
      36525; // Time in Julian centuries from 2000-01-01 12:00:00 GMT
  double t2 = t * t;
  double dr = pi / 180; // degree to radian
  double m =
      357.52910 +
      35999.05030 * t -
      0.0001559 * t2 -
      0.00000048 * t * t2; // mean anomaly, degree
  double l0 =
      280.46645 + 36000.76983 * t + 0.0003032 * t2; // mean longitude, degree
  double dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m);
  dl =
      dl +
      (0.019993 - 0.000101 * t) * sin(dr * 2 * m) +
      0.000290 * sin(dr * 3 * m);
  double l = l0 + dl; // true longitude, degree
  l = l * dr;
  l = l - pi * 2 * ((l / (pi * 2)).toInt()); // Normalize to (0, 2*PI)
  return l;
}

/* Compute sun position at midnight of the day with the given Julian day number. 
 * The time zone if the time difference between local time and UTC: 7.0 for UTC+7:00.
 * The  returns a number between 0 and 11. 
 * From the day after March equinox and the 1st major term after March equinox, 0 is returned. 
 * After that, return 1, 2, 3 ... 
 */
int getSunLongitude(int dayNumber, int timeZone) {
  return (sunLongitude(dayNumber - 0.5 - timeZone / 24) / pi * 6).toInt();
}

/* Compute the day of the k-th new moon in the given time zone.
 * The time zone if the time difference between local time and UTC: 7.0 for UTC+7:00
 */
int getNewMoonDay(int k, int timeZone) {
  return (newMoon(k) + 0.5 + timeZone / 24).toInt();
}

/* Find the day that starts the luner month 11 of the given year for the given time zone */
int getLunarMonth11(int yy, int timeZone) {
  //off = jdFromDate(31, 12, yy) - 2415021.076998695;
  int off = jdFromDate(31, 12, yy) - 2415021;
  int k = (off / 29.530588853).toInt();
  int nm = getNewMoonDay(k, timeZone);
  int sunLong = getSunLongitude(
    nm,
    timeZone,
  ); // sun longitude at local midnight
  if (sunLong >= 9) {
    nm = getNewMoonDay(k - 1, timeZone);
  }
  return nm;
}

/* Find the index of the leap month after the month starting on the day a11. */
int getLeapMonthOffset(int a11, int timeZone) {
  int k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).toInt();
  int last = 0;
  int i = 1; // We start with the month following lunar month 11
  int arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
  do {
    last = arc;
    i++;
    arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
  } while (arc != last && i < 14);
  return i - 1;
}

/* Comvert solar date dd/mm/yyyy to the corresponding lunar date */
List<int> convertSolar2Lunar(int dd, int mm, int yy, int timeZone) {
  int dayNumber = jdFromDate(dd, mm, yy);
  int k = ((dayNumber - 2415021.076998695) / 29.530588853).toInt();
  int monthStart = getNewMoonDay(k + 1, timeZone);
  if (monthStart > dayNumber) {
    monthStart = getNewMoonDay(k, timeZone);
  }
  //alert(dayNumber+" -> "+monthStart);
  int a11 = getLunarMonth11(yy, timeZone);
  int b11 = a11;
  int lunarYear = 0;
  if (a11 >= monthStart) {
    lunarYear = yy;
    a11 = getLunarMonth11(yy - 1, timeZone);
  } else {
    lunarYear = yy + 1;
    b11 = getLunarMonth11(yy + 1, timeZone);
  }
  int lunarDay = dayNumber - monthStart + 1;
  int diff = ((monthStart - a11) / 29).toInt();
  int lunarLeap = 0;
  int lunarMonth = diff + 11;
  if (b11 - a11 > 365) {
    var leapMonthDiff = getLeapMonthOffset(a11, timeZone);
    if (diff >= leapMonthDiff) {
      lunarMonth = diff + 10;
      if (diff == leapMonthDiff) {
        lunarLeap = 1;
      }
    }
  }
  if (lunarMonth > 12) {
    lunarMonth = lunarMonth - 12;
  }
  if (lunarMonth >= 11 && diff < 4) {
    lunarYear -= 1;
  }
  return [lunarDay, lunarMonth, lunarYear, lunarLeap];
}

List<int> convertSolar2LunarByDateTime(DateTime curentSolar, {timeZone = 7}) {
  int dd = curentSolar.day;
  int mm = curentSolar.month;
  int yy = curentSolar.year;

  int dayNumber = jdFromDate(dd, mm, yy);
  int k = ((dayNumber - 2415021.076998695) / 29.530588853).toInt();
  int monthStart = getNewMoonDay(k + 1, timeZone);
  if (monthStart > dayNumber) {
    monthStart = getNewMoonDay(k, timeZone);
  }
  //alert(dayNumber+" -> "+monthStart);
  int a11 = getLunarMonth11(yy, timeZone);
  int b11 = a11;
  int lunarYear = 0;
  if (a11 >= monthStart) {
    lunarYear = yy;
    a11 = getLunarMonth11(yy - 1, timeZone);
  } else {
    lunarYear = yy + 1;
    b11 = getLunarMonth11(yy + 1, timeZone);
  }
  int lunarDay = dayNumber - monthStart + 1;
  int diff = ((monthStart - a11) / 29).toInt();
  int lunarLeap = 0;
  int lunarMonth = diff + 11;
  if (b11 - a11 > 365) {
    int leapMonthDiff = getLeapMonthOffset(a11, timeZone);
    if (diff >= leapMonthDiff) {
      lunarMonth = diff + 10;
      if (diff == leapMonthDiff) {
        lunarLeap = 1;
      }
    }
  }
  if (lunarMonth > 12) {
    lunarMonth = lunarMonth - 12;
  }
  if (lunarMonth >= 11 && diff < 4) {
    lunarYear -= 1;
  }
  return [lunarDay, lunarMonth, lunarYear, lunarLeap];
}

/* Convert a lunar date to the corresponding solar date */
List<int> convertLunar2Solar(
  int lunarDay,
  int lunarMonth,
  int lunarYear,
  lunarLeap,
  int timeZone,
) {
  int a11 = 0;
  int b11 = 0;
  if (lunarMonth < 11) {
    a11 = getLunarMonth11(lunarYear - 1, timeZone);
    b11 = getLunarMonth11(lunarYear, timeZone);
  } else {
    a11 = getLunarMonth11(lunarYear, timeZone);
    b11 = getLunarMonth11(lunarYear + 1, timeZone);
  }
  int k = (0.5 + (a11 - 2415021.076998695) / 29.530588853).toInt();
  int off = lunarMonth - 11;
  if (off < 0) {
    off += 12;
  }
  if (b11 - a11 > 365) {
    int leapOff = getLeapMonthOffset(a11, timeZone);
    int leapMonth = leapOff - 2;
    if (leapMonth < 0) {
      leapMonth += 12;
    }
    if (lunarLeap != 0 && lunarMonth != leapMonth) {
      return [0, 0, 0];
    } else if (lunarLeap != 0 || off >= leapOff) {
      off += 1;
    }
  }
  int monthStart = getNewMoonDay(k + off, timeZone);
  return jdToDate(monthStart + lunarDay - 1);
}
