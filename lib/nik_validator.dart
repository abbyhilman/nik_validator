library nik_validator;

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

/// NIKValidator class to convert Identity Card Informations into useful data
class NIKValidator {
  /// Create instance class object
  static NIKValidator instance = NIKValidator();

  /// Variabel statis untuk menyimpan nama
  static String? _storedName;

  /// Setter untuk mengatur nama sebelum parse dipanggil
  void setName(String? name) {
    _storedName = name;
  }

  /// Get current year and get the last 2 digit numbers
  int _getCurrentYear() =>
      int.parse(DateTime.now().year.toString().substring(2, 4));

  /// Get year in NIK
  int _getNIKYear(String nik) => int.parse(nik.substring(10, 12));

  /// Get date in NIK
  int _getNIKDate(String nik) => int.parse(nik.substring(6, 8));

  String _getNIKDateFull(String nik, bool isWoman) {
    int date = int.parse(nik.substring(6, 8));
    if (isWoman) {
      date -= 40;
    }
    return date > 9 ? date.toString() : "0$date";
  }

  /// Get subdistrict split postalcode
  List<String> _getSubdistrictPostalCode(
          String nik, Map<String, dynamic> location) =>
      location['kecamatan'][nik.substring(0, 6)]
          .toString()
          .toUpperCase()
          .split(" -- ");

  /// Get province in NIK
  String? _getProvince(String nik, Map<String, dynamic> location) =>
      location['provinsi'][nik.substring(0, 2)];

  /// Get province id in NIK
  String? _getProvinceId(String nik, Map<String, dynamic> location) =>
      nik.substring(0, 2);

  /// Get city in NIK
  String? _getCity(String nik, Map<String, dynamic> location) =>
      location['kabupaten'][nik.substring(0, 2)][nik.substring(2, 4)];

  /// Get city id in NIK
  String? _getCityId(String nik, Map<String, dynamic> location) =>
      nik.substring(2, 4);

  /// Get subdistrict in NIK
  String? _getSubdistrict(String nik, Map<String, dynamic> location) =>
      location['kecamatan'][nik.substring(0, 2) + nik.substring(2, 4)]
          [nik.substring(4, 6)];

  /// Get subdistrict id in NIK
  String? _getSubdistrictId(String nik, Map<String, dynamic> location) =>
      nik.substring(4, 6);

  /// Get NIK Gender
  String _getGender(int date) => date > 40 ? "PEREMPUAN" : "LAKI-LAKI";

  /// Get born month
  int _getBornMonth(String nik) => int.parse(nik.substring(8, 10));

  String _getBornMonthFull(String nik) => nik.substring(8, 10);

  /// Get born year
  String _getBornYear(int nikYear, int currentYear) => nikYear < currentYear
      ? "20${nikYear > 9 ? nikYear : '0' + nikYear.toString()}"
      : "19${nikYear > 9 ? nikYear : '0' + nikYear.toString()}";

  /// Get unique code in NIK
  String _getUniqueCode(String nik) => nik.substring(12, 16);

  /// Get age from nik
  AgeDuration _getAge(DateTime bornDate, DateTime now) => Age.instance
      .dateDifference(fromDate: bornDate, toDate: now, includeToDate: false);

  /// Get next birthday
  AgeDuration _getNextBirthday(DateTime bornDate, DateTime now) =>
      Age.instance.dateDifference(fromDate: now, toDate: bornDate);

  /// Get Name dari variabel statis
  String? _getName() => _storedName ?? "NAMA TIDAK TERSEDIA";

  /// Get Zodiac from bornDate and bornMonth
  String _getZodiac(int date, int month, bool isWoman) {
    if (isWoman) date -= 40;

    if ((month == 1 && date >= 20) || (month == 2 && date < 19))
      return "Aquarius";
    if ((month == 2 && date >= 19) || (month == 3 && date < 21))
      return "Pisces";
    if ((month == 3 && date >= 21) || (month == 4 && date < 20)) return "Aries";
    if ((month == 4 && date >= 20) || (month == 5 && date < 21))
      return "Taurus";
    if ((month == 5 && date >= 21) || (month == 6 && date < 22))
      return "Gemini";
    if ((month == 6 && date >= 21) || (month == 7 && date < 23))
      return "Cancer";
    if ((month == 7 && date >= 23) || (month == 8 && date < 23)) return "Leo";
    if ((month == 8 && date >= 23) || (month == 9 && date < 23)) return "Virgo";
    if ((month == 9 && date >= 23) || (month == 10 && date < 24))
      return "Libra";
    if ((month == 10 && date >= 24) || (month == 11 && date < 23))
      return "Scorpio";
    if ((month == 11 && date >= 23) || (month == 12 && date < 22))
      return "Sagitarius";
    if ((month == 12 && date >= 22) || (month == 1 && date < 20))
      return "Capricorn";

    return "Zodiak tidak ditemukan";
  }

  /// Parsing Identity Card information from Indonesia
  /// by using unique number [nik]
  Future<NIKModel> parse({required String nik}) async {
    Map<String, dynamic>? location = await _getLocationAsset();

    log("nik valid ${_validate(nik, location)}");

    if (_validate(nik, location)) {
      int currentYear = _getCurrentYear();
      int nikYear = _getNIKYear(nik);
      int nikDate = _getNIKDate(nik);
      String gender = _getGender(nikDate);

      String nikDateFull = _getNIKDateFull(nik, gender == "PEREMPUAN");

      List<String> subdistrictPostalCode =
          _getSubdistrictPostalCode(nik, location!);

      String? province = _getProvince(nik, location);
      String? provinceId = _getProvinceId(nik, location);

      String? city = _getCity(nik, location);
      String? cityId = _getCityId(nik, location);

      String? subdistrict = _getSubdistrict(nik, location);
      String? subdistrictId = _getSubdistrictId(nik, location);

      String postalCode = "subdistrictPostalCode[1]";

      int bornMonth = _getBornMonth(nik);
      String bornMonthFull = _getBornMonthFull(nik);
      String bornYear = _getBornYear(nikYear, currentYear);

      String uniqueCode = _getUniqueCode(nik);
      String zodiac = _getZodiac(nikDate, bornMonth, gender == "PEREMPUAN");
      AgeDuration age = _getAge(
          DateTime.parse("$bornYear-$bornMonthFull-$nikDateFull"),
          DateTime.now());
      AgeDuration nextBirthday = _getNextBirthday(
          DateTime.parse("$bornYear-$bornMonthFull-$nikDateFull"),
          DateTime.now());

      String? extractedName = _getName(); // Ambil nama dari variabel statis

      log("success");
      return NIKModel(
          nik: nik,
          uniqueCode: uniqueCode,
          gender: gender,
          bornDate: "$nikDateFull-$bornMonthFull-$bornYear",
          age: "${age.years} tahun, ${age.months} bulan, ${age.days} hari",
          ageYear: age.years,
          ageMonth: age.months,
          ageDay: age.days,
          nextBirthday:
              "${nextBirthday.months} bulan ${nextBirthday.days} hari lagi",
          zodiac: zodiac,
          province: province,
          provinceId: provinceId,
          city: city,
          cityId: cityId,
          subdistrict: subdistrict,
          subdistrictId: subdistrictId,
          postalCode: postalCode,
          valid: true,
          name: extractedName);
    }
    return NIKModel.empty();
  }

  /// Validate NIK and make sure the number is correct
  bool _validate(String nik, Map<String, dynamic>? location) {
    log(location!['provinsi'][nik.substring(0, 2)]);
    log(location['kabupaten'][nik.substring(0, 2)][nik.substring(2, 4)]
        .toString());
    log(location['kecamatan'][nik.substring(0, 2) + nik.substring(2, 4)]
            [nik.substring(4, 6)]
        .toString());

    return nik.length == 16 &&
        location['provinsi'][nik.substring(0, 2)] != null &&
        location['kabupaten'][nik.substring(0, 2)][nik.substring(2, 4)] !=
            null &&
        location['kecamatan'][nik.substring(0, 2) + nik.substring(2, 4)]
                [nik.substring(4, 6)] !=
            null;
  }

  /// Load location asset like province, city and subdistrict
  /// from local json data
  Future<Map<String, dynamic>?> _getLocationAsset() async =>
      jsonDecode(await rootBundle
          .loadString("packages/nik_validator/assets/wilayah.json"));
}

/// Class for calculating age and next birthday
class Age {
  static Age instance = Age();

  List<int> _daysInMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  bool _isLeapYear(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

  int _daysInMonth(int year, int month) =>
      (month == DateTime.february && _isLeapYear(year))
          ? 29
          : _daysInMonths[month - 1];

  AgeDuration dateDifference(
      {required DateTime fromDate,
      required DateTime toDate,
      bool includeToDate = false}) {
    DateTime endDate = (includeToDate) ? toDate.add(Duration(days: 1)) : toDate;

    int years = endDate.year - fromDate.year;
    int months = 0;
    int days = 0;

    if (fromDate.month > endDate.month) {
      years--;
      months = (DateTime.monthsPerYear + endDate.month - fromDate.month);
      if (fromDate.day > endDate.day) {
        months--;
        days = _daysInMonth(fromDate.year + years,
                ((fromDate.month + months - 1) % DateTime.monthsPerYear) + 1) +
            endDate.day -
            fromDate.day;
      } else {
        days = endDate.day - fromDate.day;
      }
    } else if (endDate.month == fromDate.month) {
      if (fromDate.day > endDate.day) {
        years--;
        months = DateTime.monthsPerYear - 1;
        days = _daysInMonth(fromDate.year + years,
                ((fromDate.month + months - 1) % DateTime.monthsPerYear) + 1) +
            endDate.day -
            fromDate.day;
      } else {
        days = endDate.day - fromDate.day;
      }
    } else {
      months = (endDate.month - fromDate.month);
      if (fromDate.day > endDate.day) {
        months--;
        days = _daysInMonth(fromDate.year + years, (fromDate.month + months)) +
            endDate.day -
            fromDate.day;
      } else {
        days = endDate.day - fromDate.day;
      }
    }

    return AgeDuration(days: days, months: months, years: years);
  }
}

/// Storing age duration from the age class
class AgeDuration {
  int days;
  int months;
  int years;

  AgeDuration({this.days = 0, this.months = 0, this.years = 0});
}

/// NIKModel to store converting result
class NIKModel {
  String? nik;
  String? gender;
  String? bornDate;
  String? province;
  String? provinceId;
  String? city;
  String? cityId;
  String? subdistrict;
  String? subdistrictId;
  String? uniqueCode;
  String? postalCode;
  String? age;
  int? ageYear;
  int? ageMonth;
  int? ageDay;
  String? nextBirthday;
  String? zodiac;
  bool? valid;
  String? name; // Field untuk nama

  NIKModel({
    this.nik,
    this.gender,
    this.bornDate,
    this.province,
    this.provinceId,
    this.city,
    this.cityId,
    this.subdistrict,
    this.subdistrictId,
    this.uniqueCode,
    this.postalCode,
    this.age,
    this.zodiac,
    this.valid,
    this.ageYear,
    this.ageMonth,
    this.ageDay,
    this.nextBirthday,
    this.name,
  });

  factory NIKModel.empty() => NIKModel(
      nik: "NOT FOUND",
      uniqueCode: " ",
      gender: " ",
      bornDate: " ",
      age: " ",
      ageYear: 0,
      ageMonth: 0,
      ageDay: 0,
      nextBirthday: " ",
      zodiac: " ",
      province: " ",
      city: " ",
      subdistrict: " ",
      postalCode: " ",
      valid: false,
      name: "NAMA TIDAK TERSEDIA");
}
