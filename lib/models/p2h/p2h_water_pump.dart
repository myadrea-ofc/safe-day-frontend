import 'dart:convert';

class P2HWaterPumpModel {
  final int id;

  final String nama;
  final String jabatan;
  final String department;
  final String perusahaan;
  final String tanggal;

  final String hmUnit;
  final String noLambungUnit;
  final String shiftKerja;

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

  final String alatKeselamatanAir1;
  final String alatKeselamatanAir2;
  final String alatKeselamatanAir3;
  final String alatKeselamatanAir4;

  final String unitAman;
  final List<String> files;

  P2HWaterPumpModel({
    required this.id,

    required this.nama,
    required this.jabatan,
    required this.department,
    required this.perusahaan,
    required this.tanggal,

    required this.hmUnit,
    required this.noLambungUnit,
    required this.shiftKerja,

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

    required this.alatKeselamatanAir1,
    required this.alatKeselamatanAir2,
    required this.alatKeselamatanAir3,
    required this.alatKeselamatanAir4,

    required this.unitAman,
    required this.files,
  });

  factory P2HWaterPumpModel.fromJson(Map<String, dynamic> json) {
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
    return P2HWaterPumpModel(
      id: json['id'] ?? 0,

      nama: json['nama'] ?? '',
      jabatan: json['jabatan'] ?? '',
      department: json['department'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      tanggal: json['tanggal'] ?? '',

      hmUnit: json['hm_unit'] ?? '',
      noLambungUnit: json['no_lambung_unit'] ?? '',
      shiftKerja: json['shift_kerja'] ?? '',

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

      alatKeselamatanAir1: json['alat_keselamatan_air1'] ?? '',
      alatKeselamatanAir2: json['alat_keselamatan_air2'] ?? '',
      alatKeselamatanAir3: json['alat_keselamatan_air3'] ?? '',
      alatKeselamatanAir4: json['alat_keselamatan_air4'] ?? '',

      unitAman: json['unit_aman'] ?? '',
      files: parsedFiles,
    );
  }
}
