library nik_validator;

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

/// Kelas NIKValidator untuk mengkonversi informasi KTP menjadi data yang berguna
class NIKValidator {
  /// Membuat instance singleton dari NIKValidator
  static NIKValidator instance = NIKValidator();

  /// Variabel statis untuk menyimpan data tambahan dari OCR atau input lain
  static String? _storedName; // Menyimpan nama
  static String? _storedReligion; // Menyimpan agama
  static String? _storedOccupation; // Menyimpan pekerjaan

  /// Setter untuk mengatur data sebelum parsing dilakukan
  void setName(String? name) => _storedName = name; // Set nama
  void setReligion(String? religion) => _storedReligion = religion; // Set agama
  void setOccupation(String? occupation) =>
      _storedOccupation = occupation; // Set pekerjaan

  /// Mendapatkan dua digit terakhir dari tahun sekarang
  int _getCurrentYear() =>
      int.parse(DateTime.now().year.toString().substring(2, 4));

  /// Mendapatkan tahun dari NIK (digit 11-12)
  int _getNIKYear(String nik) => int.parse(nik.substring(10, 12));

  /// Mendapatkan tanggal dari NIK (digit 7-8)
  int _getNIKDate(String nik) => int.parse(nik.substring(6, 8));

  /// Mendapatkan tanggal lengkap dengan penyesuaian untuk perempuan
  String _getNIKDateFull(String nik, bool isWoman) {
    int date = int.parse(nik.substring(6, 8));
    if (isWoman) {
      date -= 40; // Perempuan memiliki offset +40 pada tanggal
    }
    return date > 9 ? date.toString() : "0$date"; // Tambah 0 jika < 10
  }

  /// Mendapatkan data kecamatan dan kode pos dari NIK
  List<String> _getSubdistrictPostalCode(
      String nik, Map<String, dynamic> location) {
    String data =
        location['kecamatan'][nik.substring(0, 6)].toString().toUpperCase();
    List<String> splitData = data.split(" -- ");
    // Jika ada kode pos setelah "--", kembalikan [nama, kode pos], jika tidak [nama, "NOT AVAILABLE"]
    return splitData.length > 1 ? splitData : [splitData[0], "NOT AVAILABLE"];
  }

  /// Mendapatkan nama provinsi dari NIK
  String? _getProvince(String nik, Map<String, dynamic> location) =>
      location['provinsi'][nik.substring(0, 2)];

  /// Mendapatkan ID provinsi dari NIK (digit 1-2)
  String? _getProvinceId(String nik, Map<String, dynamic> location) =>
      nik.substring(0, 2);

  /// Mendapatkan nama kota/kabupaten dari NIK
  String? _getCity(String nik, Map<String, dynamic> location) =>
      location['kabupaten'][nik.substring(0, 2)][nik.substring(2, 4)];

  /// Mendapatkan ID kota/kabupaten dari NIK (digit 3-4)
  String? _getCityId(String nik, Map<String, dynamic> location) =>
      nik.substring(2, 4);

  /// Mendapatkan nama kecamatan dari NIK
  String? _getSubdistrict(String nik, Map<String, dynamic> location) =>
      location['kecamatan'][nik.substring(0, 2) + nik.substring(2, 4)]
          [nik.substring(4, 6)];

  /// Mendapatkan ID kecamatan dari NIK (digit 5-6)
  String? _getSubdistrictId(String nik, Map<String, dynamic> location) =>
      nik.substring(4, 6);

  /// Menentukan jenis kelamin berdasarkan tanggal (perempuan > 40)
  String _getGender(int date) => date > 40 ? "PEREMPUAN" : "LAKI-LAKI";

  /// Mendapatkan bulan kelahiran dari NIK (digit 9-10)
  int _getBornMonth(String nik) => int.parse(nik.substring(8, 10));

  /// Mendapatkan bulan kelahiran dalam format dua digit
  String _getBornMonthFull(String nik) => nik.substring(8, 10);

  /// Menentukan tahun kelahiran penuh berdasarkan perbandingan dengan tahun sekarang
  String _getBornYear(int nikYear, int currentYear) => nikYear < currentYear
      ? "20${nikYear > 9 ? nikYear : '0' + nikYear.toString()}"
      : "19${nikYear > 9 ? nikYear : '0' + nikYear.toString()}";

  /// Mendapatkan kode unik dari NIK (digit 13-16)
  String _getUniqueCode(String nik) => nik.substring(12, 16);

  /// Menghitung umur berdasarkan tanggal lahir
  AgeDuration _getAge(DateTime bornDate, DateTime now) => Age.instance
      .dateDifference(fromDate: bornDate, toDate: now, includeToDate: false);

  /// Menghitung waktu menuju ulang tahun berikutnya
  AgeDuration _getNextBirthday(DateTime bornDate, DateTime now) =>
      Age.instance.dateDifference(fromDate: now, toDate: bornDate);

  /// Mendapatkan nama dari variabel statis, fallback ke "TIDAK TERSEDIA"
  String? _getName() => _storedName ?? "NAMA TIDAK TERSEDIA";

  /// Mendapatkan agama dari variabel statis, fallback ke "TIDAK TERSEDIA"
  String? _getReligion() => _storedReligion ?? "AGAMA TIDAK TERSEDIA";

  /// Mendapatkan pekerjaan dari variabel statis, fallback ke "TIDAK TERSEDIA"
  String? _getOccupation() => _storedOccupation ?? "PEKERJAAN TIDAK TERSEDIA";

  /// Menentukan zodiak berdasarkan tanggal dan bulan kelahiran
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

  /// Fungsi utama untuk parsing informasi dari NIK
  Future<NIKModel> parse({required String nik}) async {
    Map<String, dynamic>? location = await _getLocationAsset();

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
      String postalCode = subdistrictPostalCode[1]; // Kode pos

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

      String? extractedName = _getName();
      String? religion = _getReligion();
      String? occupation = _getOccupation();

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
          name: extractedName,
          religion: religion,
          occupation: occupation);
    }
    return NIKModel.empty();
  }

  /// Validasi NIK untuk memastikan nomor valid
  bool _validate(String nik, Map<String, dynamic>? location) {
    if (nik.length != 16 || location == null) return false;
    return location['provinsi'][nik.substring(0, 2)] != null &&
        location['kabupaten'][nik.substring(0, 2)][nik.substring(2, 4)] !=
            null &&
        location['kecamatan'][nik.substring(0, 2) + nik.substring(2, 4)]
                [nik.substring(4, 6)] !=
            null;
  }

  /// Memuat data lokasi dari file JSON lokal
  Future<Map<String, dynamic>?> _getLocationAsset() async =>
      jsonDecode(await rootBundle
          .loadString("packages/nik_validator/assets/wilayah.json"));
}

/// Kelas untuk menghitung umur dan ulang tahun berikutnya
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

/// Kelas untuk menyimpan durasi umur
class AgeDuration {
  int days;
  int months;
  int years;

  AgeDuration({this.days = 0, this.months = 0, this.years = 0});
}

/// Model untuk menyimpan hasil parsing NIK
class NIKModel {
  String? nik; // Nomor NIK
  String? gender; // Jenis kelamin
  String? bornDate; // Tanggal lahir
  String? province; // Provinsi
  String? provinceId; // ID Provinsi
  String? city; // Kota/Kabupaten
  String? cityId; // ID Kota/Kabupaten
  String? subdistrict; // Kecamatan
  String? subdistrictId; // ID Kecamatan
  String? uniqueCode; // Kode unik
  String? postalCode; // Kode pos
  String? age; // Umur dalam format string
  int? ageYear; // Umur dalam tahun
  int? ageMonth; // Umur dalam bulan
  int? ageDay; // Umur dalam hari
  String? nextBirthday; // Waktu menuju ulang tahun berikutnya
  String? zodiac; // Zodiak
  bool? valid; // Status validitas NIK
  String? name; // Nama
  String? religion; // Agama
  String? occupation; // Pekerjaan

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
    this.religion,
    this.occupation,
  });

  /// Factory untuk membuat NIKModel kosong saat NIK tidak valid
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
      name: "NAMA TIDAK TERSEDIA",
      religion: "AGAMA TIDAK TERSEDIA",
      occupation: "PEKERJAAN TIDAK TERSEDIA");
}
