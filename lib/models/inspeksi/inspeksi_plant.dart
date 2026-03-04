class InspeksiPlantModel {
  final int id;
  final String nama;
  final String nrp;
  final String department;
  final String perusahaan;
  final String tanggal;
  final int jumlahInspektor;

  final String opsi1;
  final String opsi2;
  final String opsi3;
  final String opsi4;
  final String opsi5;
  final String opsi6;
  final String opsi7;
  final String opsi8;
  final String opsi9;
  final String opsi10;
  final String opsi11;
  final String opsi12;
  final String opsi13;
  final String opsi14;
  final String opsi15;
  final String opsi16;
  final String opsi17;
  final String opsi18;
  final String opsi19;
  final String opsi20;
  final String opsi21;
  final String opsi22;
  final String opsi23;
  final String opsi24;
  final String opsi25;
  final String opsi26;

  final String ketHasil;
  final String saranMasuk;
  final String statusInspeksi;

  final String foto1;
  final String foto2;
  final String foto3;
  final String foto4;

  InspeksiPlantModel({
    required this.id,
    required this.nama,
    required this.nrp,
    required this.department,
    required this.perusahaan,
    required this.tanggal,
    required this.jumlahInspektor,

    required this.opsi1,
    required this.opsi2,
    required this.opsi3,
    required this.opsi4,
    required this.opsi5,
    required this.opsi6,
    required this.opsi7,
    required this.opsi8,
    required this.opsi9,
    required this.opsi10,
    required this.opsi11,
    required this.opsi12,
    required this.opsi13,
    required this.opsi14,
    required this.opsi15,
    required this.opsi16,
    required this.opsi17,
    required this.opsi18,
    required this.opsi19,
    required this.opsi20,
    required this.opsi21,
    required this.opsi22,
    required this.opsi23,
    required this.opsi24,
    required this.opsi25,
    required this.opsi26,

    required this.ketHasil,
    required this.saranMasuk,
    required this.statusInspeksi,

    required this.foto1,
    required this.foto2,
    required this.foto3,
    required this.foto4,
  });

  factory InspeksiPlantModel.fromJson(Map<String, dynamic> json) {
    return InspeksiPlantModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nrp: json['nrp'] ?? '',
      department: json['department'] ?? '',
      perusahaan: json['perusahaan'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jumlahInspektor: json['jumlah_inspektor'] is int
          ? json['jumlah_inspektor']
          : int.tryParse(json['jumlah_inspektor'].toString()) ?? 0,

      opsi1: json['opsi1'] ?? '',
      opsi2: json['opsi2'] ?? '',
      opsi3: json['opsi3'] ?? '',
      opsi4: json['opsi4'] ?? '',
      opsi5: json['opsi5'] ?? '',
      opsi6: json['opsi6'] ?? '',
      opsi7: json['opsi7'] ?? '',
      opsi8: json['opsi8'] ?? '',
      opsi9: json['opsi9'] ?? '',
      opsi10: json['opsi10'] ?? '',
      opsi11: json['opsi11'] ?? '',
      opsi12: json['opsi12'] ?? '',
      opsi13: json['opsi13'] ?? '',
      opsi14: json['opsi14'] ?? '',
      opsi15: json['opsi15'] ?? '',
      opsi16: json['opsi16'] ?? '',
      opsi17: json['opsi17'] ?? '',
      opsi18: json['opsi18'] ?? '',
      opsi19: json['opsi19'] ?? '',
      opsi20: json['opsi20'] ?? '',
      opsi21: json['opsi21'] ?? '',
      opsi22: json['opsi22'] ?? '',
      opsi23: json['opsi23'] ?? '',
      opsi24: json['opsi24'] ?? '',
      opsi25: json['opsi25'] ?? '',
      opsi26: json['opsi26'] ?? '',

      ketHasil: json['ket_hasil'] ?? '',
      saranMasuk: json['saran_masuk'] ?? '',
      statusInspeksi: json['status_inspeksi'] ?? '',

      foto1: json['foto1'] ?? '',
      foto2: json['foto2'] ?? '',
      foto3: json['foto3'] ?? '',
      foto4: json['foto4'] ?? '',
    );
  }
}
