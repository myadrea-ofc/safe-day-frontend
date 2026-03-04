class P5MModel {
  final int id;
  final String nama;
  final String perusahaan;
  final String department;
  final String namaPembicara;
  final String topik;
  final String jabatan;
  final String kondisiKesehatan;
  final String jamTidur;
  final String siapKerja;
  final String statusHariKerja;
  final String umpanBalik;
  final String fotoPath;
  final DateTime? createdAt;

  P5MModel({
    required this.id,
    required this.nama,
    required this.perusahaan,
    required this.department,
    required this.namaPembicara,
    required this.topik,
    required this.jabatan,
    required this.kondisiKesehatan,
    required this.jamTidur,
    required this.siapKerja,
    required this.statusHariKerja,
    required this.umpanBalik,
    required this.fotoPath,
    this.createdAt,
  });

  factory P5MModel.fromJson(Map<String, dynamic> json) {
    return P5MModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      department: json['department'] ?? '',
      namaPembicara: json['nama_pembicara'] ?? '',
      topik: json['topik'] ?? '',
      jabatan: json['jabatan'] ?? '',
      kondisiKesehatan: json['kondisi_kesehatan'] ?? '',
      jamTidur: json['jam_tidur'] ?? '',
      siapKerja: json['siap_kerja'] ?? '',
      statusHariKerja: json['status_hari_kerja'] ?? '',
      umpanBalik: json['umpan_balik'] ?? '',
      fotoPath: json['foto_path'] ?? '',
      createdAt:
          json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
