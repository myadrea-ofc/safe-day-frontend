import 'dart:convert';

class LPIModel {
  final int id;
  final String nama;
  final String perusahaan;
  final String department;
  final String tanggal;
  final String waktu;
  final String namaKorban;
  final String jabatanKorban;
  final String namaSpv;
  final String departmentSpv;
  final String jenisAset;
  final String namaSaksi;
  final String jabatanSaksi;
  final String departmentSaksi;
  final String klasifikasi;
  final String kronologi;
  final String filePath;
  final List<String> fotoPaths;
  final String statusLokasi;

  LPIModel({
    required this.id,
    required this.nama,
    required this.perusahaan,
    required this.department,
    required this.tanggal,
    required this.waktu,
    required this.namaKorban,
    required this.jabatanKorban,
    required this.namaSpv,
    required this.departmentSpv,
    required this.jenisAset,
    required this.namaSaksi,
    required this.jabatanSaksi,
    required this.departmentSaksi,
    required this.klasifikasi,
    required this.kronologi,
    required this.filePath,
    required this.fotoPaths,
    required this.statusLokasi,
  });

  factory LPIModel.fromJson(Map<String, dynamic> json) {
    final rawFoto = json['foto_paths'];

    List<String> parsedFoto = [];

    if (rawFoto is List) {
      parsedFoto = List<String>.from(rawFoto);
    } else if (rawFoto is String && rawFoto.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFoto);
        parsedFoto = List<String>.from(decoded);
      } catch (_) {
        parsedFoto = rawFoto.split(',');
      }
    }

    return LPIModel(
      id: json['id'],
      nama: json['nama'],
      perusahaan: json['perusahaan'],
      department: json['department'],
      tanggal: json['tanggal'],
      waktu: json['waktu'],
      namaKorban: json['nama_korban'],
      jabatanKorban: json['jabatan_korban'],
      namaSpv: json['nama_spv'],
      departmentSpv: json['department_spv'],
      jenisAset: json['jenis_aset_perusahaan'],
      namaSaksi: json['nama_saksi'],
      jabatanSaksi: json['jabatan_saksi'],
      departmentSaksi: json['department_saksi'],
      klasifikasi: json['klasifikasi_insiden'],
      kronologi: json['kronologi'],
      filePath: json['file_path'] ?? "",
      fotoPaths: parsedFoto,
      statusLokasi: json['status_lokasi'],
    );
  }
}
