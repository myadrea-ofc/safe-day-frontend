import 'dart:convert';

class P2HWheelLoaderModel {
  final int id;

  final String nama;
  final String nrp;
  final String jabatan;
  final String department;
  final String perusahaan;
  final String tanggal;

  final String lokasiKerja;
  final String hmUnit;
  final String noLambungUnit;

  final String opsiItem1;
  final String opsiItem2;
  final String opsiItem3;
  final String opsiItem4;
  final String opsiItem5;
  final String opsiItem6;
  final String opsiItem7;
  final String opsiItem8;
  final String opsiItem9;
  final String opsiItem10;
  final String opsiItem11;
  final String opsiItem12;
  final String opsiItem13;
  final String opsiItem14;
  final String opsiItem15;
  final String opsiItem16;
  final String opsiItem17;
  final String opsiItem18;
  final String opsiItem19;
  final String opsiItem20;
  final String opsiItem21;
  final String opsiItem22;
  final String opsiItem23;
  final String opsiItem24;
  final String opsiItem25;
  final String opsiItem26;
  final String opsiItem27;
  final String opsiItem28;
  final String opsiItem29;
  final String opsiItem30;
  final String opsiItem31;

  final String opsiStandarKeselamatan1;
  final String opsiStandarKeselamatan2;
  final String opsiStandarKeselamatan3;

  final String jamTidur;

  final String statusKeadaan1;
  final String statusKeadaan2;
  final String statusKeadaan3;
  final String statusKeadaan4;
  final String statusKeadaan5;
  final String statusKeadaan6;

  final String statusSiap;
  final List<String> files;

  P2HWheelLoaderModel({
    required this.id,

    required this.nama,
    required this.nrp,
    required this.jabatan,
    required this.department,
    required this.perusahaan,
    required this.tanggal,

    required this.lokasiKerja,
    required this.hmUnit,
    required this.noLambungUnit,

    required this.opsiItem1,
    required this.opsiItem2,
    required this.opsiItem3,
    required this.opsiItem4,
    required this.opsiItem5,
    required this.opsiItem6,
    required this.opsiItem7,
    required this.opsiItem8,
    required this.opsiItem9,
    required this.opsiItem10,
    required this.opsiItem11,
    required this.opsiItem12,
    required this.opsiItem13,
    required this.opsiItem14,
    required this.opsiItem15,
    required this.opsiItem16,
    required this.opsiItem17,
    required this.opsiItem18,
    required this.opsiItem19,
    required this.opsiItem20,
    required this.opsiItem21,
    required this.opsiItem22,
    required this.opsiItem23,
    required this.opsiItem24,
    required this.opsiItem25,
    required this.opsiItem26,
    required this.opsiItem27,
    required this.opsiItem28,
    required this.opsiItem29,
    required this.opsiItem30,
    required this.opsiItem31,

    required this.opsiStandarKeselamatan1,
    required this.opsiStandarKeselamatan2,
    required this.opsiStandarKeselamatan3,

    required this.jamTidur,

    required this.statusKeadaan1,
    required this.statusKeadaan2,
    required this.statusKeadaan3,
    required this.statusKeadaan4,
    required this.statusKeadaan5,
    required this.statusKeadaan6,

    required this.statusSiap,
    required this.files,
  });

  factory P2HWheelLoaderModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];

    List<String> parsedFiles = [];

    if (rawFiles is List) {
      parsedFiles = List<String>.from(rawFiles);
    } else if (rawFiles is String && rawFiles.isNotEmpty) {
      try {
        parsedFiles = List<String>.from(jsonDecode(rawFiles));
      } catch (_) {
        parsedFiles = rawFiles.split(',');
      }
    }
    return P2HWheelLoaderModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nrp: json['nrp'] ?? '',
      jabatan: json['jabatan'] ?? '',
      department: json['department'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      tanggal: json['tanggal'] ?? '',

      lokasiKerja: json['lokasi_kerja'] ?? '',
      hmUnit: json['hm_unit'] ?? '',
      noLambungUnit: json['no_lambung_unit'] ?? '',

      opsiItem1: json['opsi_item1'] ?? '',
      opsiItem2: json['opsi_item2'] ?? '',
      opsiItem3: json['opsi_item3'] ?? '',
      opsiItem4: json['opsi_item4'] ?? '',
      opsiItem5: json['opsi_item5'] ?? '',
      opsiItem6: json['opsi_item6'] ?? '',
      opsiItem7: json['opsi_item7'] ?? '',
      opsiItem8: json['opsi_item8'] ?? '',
      opsiItem9: json['opsi_item9'] ?? '',
      opsiItem10: json['opsi_item10'] ?? '',
      opsiItem11: json['opsi_item11'] ?? '',
      opsiItem12: json['opsi_item12'] ?? '',
      opsiItem13: json['opsi_item13'] ?? '',
      opsiItem14: json['opsi_item14'] ?? '',
      opsiItem15: json['opsi_item15'] ?? '',
      opsiItem16: json['opsi_item16'] ?? '',
      opsiItem17: json['opsi_item17'] ?? '',
      opsiItem18: json['opsi_item18'] ?? '',
      opsiItem19: json['opsi_item19'] ?? '',
      opsiItem20: json['opsi_item20'] ?? '',
      opsiItem21: json['opsi_item21'] ?? '',
      opsiItem22: json['opsi_item22'] ?? '',
      opsiItem23: json['opsi_item23'] ?? '',
      opsiItem24: json['opsi_item24'] ?? '',
      opsiItem25: json['opsi_item25'] ?? '',
      opsiItem26: json['opsi_item26'] ?? '',
      opsiItem27: json['opsi_item27'] ?? '',
      opsiItem28: json['opsi_item28'] ?? '',
      opsiItem29: json['opsi_item29'] ?? '',
      opsiItem30: json['opsi_item30'] ?? '',
      opsiItem31: json['opsi_item31'] ?? '',

      opsiStandarKeselamatan1: json['opsi_standar_keselamatan1'] ?? '',
      opsiStandarKeselamatan2: json['opsi_standar_keselamatan2'] ?? '',
      opsiStandarKeselamatan3: json['opsi_standar_keselamatan3'] ?? '',

      jamTidur: json['jam_tidur'] ?? '',

      statusKeadaan1: json['status_keadaan1'] ?? '',
      statusKeadaan2: json['status_keadaan2'] ?? '',
      statusKeadaan3: json['status_keadaan3'] ?? '',
      statusKeadaan4: json['status_keadaan4'] ?? '',
      statusKeadaan5: json['status_keadaan5'] ?? '',
      statusKeadaan6: json['status_keadaan6'] ?? '',

      statusSiap: json['status_siap'] ?? '',
      files: parsedFiles,
    );
  }
}
