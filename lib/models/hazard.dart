class HazardModel {
  final int id;
  final String nama;
  final String idKaryawan;
  final String perusahaan;
  final String department;
  final String jabatan;
  final String lokasiTemuan;
  final String tanggal;
  final String waktu;
  final String jenisTemuan;
  final String infoPerbaikan;
  final String narasiTemuan;
  final String statusSesuai;
  final String? foto1_path;
  final String? foto2_path;
  final String? foto3_path;

  HazardModel({
    required this.id,
    required this.nama,
    required this.idKaryawan,
    required this.perusahaan,
    required this.jabatan,
    required this.department,
    required this.lokasiTemuan,
    required this.tanggal,
    required this.waktu,
    required this.jenisTemuan,
    required this.narasiTemuan,
    required this.infoPerbaikan,
    required this.statusSesuai,
    required this.foto1_path,
    required this.foto2_path,
    required this.foto3_path,
  });

  factory HazardModel.fromJson(Map<String, dynamic> json) {
    return HazardModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      idKaryawan: json['id_karyawan'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      jabatan: json['jabatan'] ?? '',
      department: json['department'] ?? '',
      lokasiTemuan: json['lokasi_temuan'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktu: json['waktu'] ?? '',
      jenisTemuan: json['jenis_temuan'] ?? '',
      narasiTemuan: json['narasi_temuan'] ?? '',
      infoPerbaikan: json['info_perbaikan'] ?? '',
      statusSesuai: json['status_sesuai'] ?? 'Open',
      foto1_path: json['foto1_path'],
      foto2_path: json['foto2_path'],
      foto3_path: json['foto3_path'],
    );
  }
}
