import 'dart:convert';

class P2HLVModel {
  final int id;

  final String nama;
  final String jabatan;
  final String department;
  final String perusahaan;
  final String tanggal;
  final String brandUnit;
  final String noLambungUnit;
  final String lvSekarang;
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

  final String opsiStandardKeselamatan1;
  final String opsiStandardKeselamatan2;
  final String opsiStandardKeselamatan3;
  final String opsiStandardKeselamatan4;
  final String opsiStandardKeselamatan5;

  final String opsiStandardMasukTambang1;
  final String opsiStandardMasukTambang2;
  final String opsiStandardMasukTambang3;
  final String opsiStandardMasukTambang4;
  final String opsiStandardMasukTambang5;
  final String opsiStandardMasukTambang6;
  final String opsiStandardMasukTambang7;

  final String laporanTemuan;
  final String jamTidur;

  final String statusKeadaan1;
  final String statusKeadaan2;
  final String statusKeadaan3;
  final String statusKeadaan4;
  final String statusKeadaan5;
  final String statusKeadaan6;

  final String statusSiap;
  final List<String> files;

  P2HLVModel({
    required this.id,

    required this.nama,
    required this.jabatan,
    required this.department,
    required this.perusahaan,
    required this.tanggal,
    required this.brandUnit,
    required this.noLambungUnit,
    required this.lvSekarang,
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

    required this.opsiStandardKeselamatan1,
    required this.opsiStandardKeselamatan2,
    required this.opsiStandardKeselamatan3,
    required this.opsiStandardKeselamatan4,
    required this.opsiStandardKeselamatan5,

    required this.opsiStandardMasukTambang1,
    required this.opsiStandardMasukTambang2,
    required this.opsiStandardMasukTambang3,
    required this.opsiStandardMasukTambang4,
    required this.opsiStandardMasukTambang5,
    required this.opsiStandardMasukTambang6,
    required this.opsiStandardMasukTambang7,

    required this.laporanTemuan,
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

  factory P2HLVModel.fromJson(Map<String, dynamic> json) {
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
    return P2HLVModel(
      id: json['id'] ?? 0,

      nama: json['nama'] ?? '',
      jabatan: json['jabatan'] ?? '',
      department: json['department'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      tanggal: json['tanggal'] ?? '',
      brandUnit: json['brand_unit'] ?? '',
      noLambungUnit: json['no_lambung_unit'] ?? '',
      lvSekarang: json['lv_sekarang'] ?? '',
      shiftKerja: json['shift_kerja'] ?? '',

      opsiItem1: json['opsiitem1'] ?? '',
      opsiItem2: json['opsiitem2'] ?? '',
      opsiItem3: json['opsiitem3'] ?? '',
      opsiItem4: json['opsiitem4'] ?? '',
      opsiItem5: json['opsiitem5'] ?? '',
      opsiItem6: json['opsiitem6'] ?? '',
      opsiItem7: json['opsiitem7'] ?? '',
      opsiItem8: json['opsiitem8'] ?? '',
      opsiItem9: json['opsiitem9'] ?? '',
      opsiItem10: json['opsiitem10'] ?? '',
      opsiItem11: json['opsiitem11'] ?? '',
      opsiItem12: json['opsiitem12'] ?? '',
      opsiItem13: json['opsiitem13'] ?? '',
      opsiItem14: json['opsiitem14'] ?? '',
      opsiItem15: json['opsiitem15'] ?? '',
      opsiItem16: json['opsiitem16'] ?? '',
      opsiItem17: json['opsiitem17'] ?? '',
      opsiItem18: json['opsiitem18'] ?? '',
      opsiItem19: json['opsiitem19'] ?? '',

      opsiStandardKeselamatan1: json['opsistandardkeselamatan1'] ?? '',
      opsiStandardKeselamatan2: json['opsistandardkeselamatan2'] ?? '',
      opsiStandardKeselamatan3: json['opsistandardkeselamatan3'] ?? '',
      opsiStandardKeselamatan4: json['opsistandardkeselamatan4'] ?? '',
      opsiStandardKeselamatan5: json['opsistandardkeselamatan5'] ?? '',

      opsiStandardMasukTambang1: json['opsistandardmasuktambang1'] ?? '',
      opsiStandardMasukTambang2: json['opsistandardmasuktambang2'] ?? '',
      opsiStandardMasukTambang3: json['opsistandardmasuktambang3'] ?? '',
      opsiStandardMasukTambang4: json['opsistandardmasuktambang4'] ?? '',
      opsiStandardMasukTambang5: json['opsistandardmasuktambang5'] ?? '',
      opsiStandardMasukTambang6: json['opsistandardmasuktambang6'] ?? '',
      opsiStandardMasukTambang7: json['opsistandardmasuktambang7'] ?? '',

      laporanTemuan: json['laporan_temuan'] ?? '',
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
