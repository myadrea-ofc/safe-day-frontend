import 'dart:convert';

class P2HTowerlampModel {
  final int id;

  final String nama;
  final String nrp;
  final String jabatan;
  final String department;
  final String perusahaan;
  final String lokasiKerja;
  final String hmUnit;
  final String tanggal;

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

  final String statusSiap;
  final List<String> files;

  P2HTowerlampModel({
    required this.id,

    required this.nama,
    required this.nrp,
    required this.jabatan,
    required this.department,
    required this.perusahaan,
    required this.lokasiKerja,
    required this.hmUnit,
    required this.tanggal,

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

    required this.statusSiap,
    required this.files,
  });

  factory P2HTowerlampModel.fromJson(Map<String, dynamic> json) {
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
    return P2HTowerlampModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nrp: json['nrp'] ?? '',
      jabatan: json['jabatan'] ?? '',
      department: json['department'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      lokasiKerja: json['lokasi_kerja'] ?? '',
      hmUnit: json['hm_unit'] ?? '',
      tanggal: json['tanggal'] ?? '',

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

      statusSiap: json['status_siap'] ?? '',
      files: parsedFiles,
    );
  }
}
