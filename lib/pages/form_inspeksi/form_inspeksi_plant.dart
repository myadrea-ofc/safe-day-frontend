import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_plant_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_yesnona.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/upload_box.dart';
import '../../widgets/dropdown/dropdown_department.dart';
import '../../widgets/dropdown/dropdown_perusahaan.dart';

class FormInspeksiPlant extends StatefulWidget {
  @override
  _FormInspeksiPlantPageState createState() => _FormInspeksiPlantPageState();
}

class _FormInspeksiPlantPageState extends State<FormInspeksiPlant> {
  TextEditingController nama = TextEditingController();
  TextEditingController nrp = TextEditingController();
  TextEditingController jumlah_inspektor = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController ket_hasil_temuan = TextEditingController();
  TextEditingController saran_masuk = TextEditingController();

  String? department;
  String? status_inspeksi;
  String? perusahaan;

  String? opsi1;
  String? opsi2;
  String? opsi3;
  String? opsi4;
  String? opsi5;
  String? opsi6;
  String? opsi7;
  String? opsi8;
  String? opsi9;
  String? opsi10;
  String? opsi11;
  String? opsi12;
  String? opsi13;
  String? opsi14;
  String? opsi15;
  String? opsi16;
  String? opsi17;
  String? opsi18;
  String? opsi19;
  String? opsi20;
  String? opsi21;
  String? opsi22;
  String? opsi23;
  String? opsi24;
  String? opsi25;
  String? opsi26;

  File? foto1;
  File? foto2;
  File? foto3;
  File? foto4;

  bool _isSubmitting = false;

  static const fNama = "Nama Pengisi";
  static const fNRP = "NRP";
  static const fDepartment = "Department";
  static const fPerusahaan = "Perusahaan";
  static const fTanggal = "Tanggal Inspeksi";
  static const fJumlahInspektor = "Jumlah Inspektor";
  static const fOpsiPrefix = "Inspeksi Item";
  static const fKetHasil = "Keterangan Hasil Temuan";
  static const fSaranMasuk = "Saran Perbaikan";
  static const fStatusInspeksi = "Status Inspeksi";
  static const fFoto1 = "Foto Temuan 1";
  static const fFoto2 = "Foto Temuan 2";
  static const fFoto3 = "Foto Temuan 3";
  static const fFoto4 = "Foto Temuan 4";

  Map<int, String?> get _opsiMap => {
    1: opsi1,
    2: opsi2,
    3: opsi3,
    4: opsi4,
    5: opsi5,
    6: opsi6,
    7: opsi7,
    8: opsi8,
    9: opsi9,
    10: opsi10,
    11: opsi11,
    12: opsi12,
    13: opsi13,
    14: opsi14,
    15: opsi15,
    16: opsi16,
    17: opsi17,
    18: opsi18,
    19: opsi19,
    20: opsi20,
    21: opsi21,
    22: opsi22,
    23: opsi23,
    24: opsi24,
    25: opsi25,
    26: opsi26,
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (nrp.text.trim().isEmpty) missing.add(fNRP);
    if (department == null || department!.isEmpty) missing.add(fDepartment);
    if (perusahaan == null || perusahaan!.isEmpty) missing.add(fPerusahaan);
    if (tanggal.text.trim().isEmpty) missing.add(fTanggal);
    if (jumlah_inspektor.text.trim().isEmpty) {
      missing.add(fJumlahInspektor);
    }

    _opsiMap.forEach((index, value) {
      if (value == null || value.isEmpty) {
        missing.add("$fOpsiPrefix $index");
      }
    });

    if (ket_hasil_temuan.text.trim().isEmpty) {
      missing.add(fKetHasil);
    }

    if (saran_masuk.text.trim().isEmpty) {
      missing.add(fSaranMasuk);
    }

    if (status_inspeksi == null || status_inspeksi!.isEmpty) {
      missing.add(fStatusInspeksi);
    }

    if (foto1 == null) missing.add(fFoto1);
    if (foto2 == null) missing.add(fFoto2);
    if (foto3 == null) missing.add(fFoto3);
    if (foto4 == null) missing.add(fFoto4);

    return missing;
  }

  List<String> _missingFields = [];

  void _clearMissing(String field) {
    setState(() {
      _missingFields.remove(field);
    });
  }

  @override
  void initState() {
    super.initState();

    nama.text = AuthSession.name ?? "";
    nrp.text = AuthSession.employeeId ?? "";

    nama.addListener(() {
      if (nama.text.trim().isNotEmpty) {
        _clearMissing(fNama);
      }
    });

    nrp.addListener(() {
      if (nrp.text.trim().isNotEmpty) {
        _clearMissing(fNRP);
      }
    });

    jumlah_inspektor.addListener(() {
      if (jumlah_inspektor.text.trim().isNotEmpty) {
        _clearMissing(fJumlahInspektor);
      }
    });

    ket_hasil_temuan.addListener(() {
      if (ket_hasil_temuan.text.trim().isNotEmpty) {
        _clearMissing(fKetHasil);
      }
    });

    saran_masuk.addListener(() {
      if (saran_masuk.text.trim().isNotEmpty) {
        _clearMissing(fSaranMasuk);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff4f6f9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(65),
        child: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
          title: Text(
            "Form Inspeksi Area Plant",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.greenAccent, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.apartment_rounded, color: Colors.white, size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Inspeksi Area Plant",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                    color: Colors.black12,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabelText(fNama, showError: _missingFields.contains(fNama)),
                  InputField(
                    controller: nama,
                    hint: "Masukkan nama",
                    onChanged: null,
                    readOnly: true,
                  ),

                  LabelText(fNRP, showError: _missingFields.contains(fNRP)),
                  InputField(
                    controller: nrp,
                    hint: "Masukkan NRP",
                    onChanged: null,
                    readOnly: true,
                  ),

                  LabelText(
                    fDepartment,
                    showError: _missingFields.contains(fDepartment),
                  ),
                  DropdownDepartment(
                    value: department,
                    onChanged: (v) {
                      setState(() => department = v);
                      if (v != null) _clearMissing(fDepartment);
                    },
                  ),

                  LabelText(
                    fPerusahaan,
                    showError: _missingFields.contains(fPerusahaan),
                  ),
                  DropdownPerusahaan(
                    value: perusahaan,
                    onChanged: (v) {
                      setState(() => perusahaan = v);
                      if (v != null) _clearMissing(fPerusahaan);
                    },
                  ),

                  SizedBox(height: 15),

                  LabelText(
                    fTanggal,
                    showError: _missingFields.contains(fTanggal),
                  ),
                  DateField(
                    controller: tanggal,
                    onTap: pilihTanggal,
                    icon: Icons.calendar_today,
                  ),

                  LabelText(
                    fJumlahInspektor,
                    showError: _missingFields.contains(fJumlahInspektor),
                  ),
                  InputField(
                    controller: jumlah_inspektor,
                    hint: "Jumlah Inspektor",
                    inputType: InputType.integer,
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fJumlahInspektor);
                      }
                    },
                  ),

                  LabelText(
                    "Praktek penumpukan & penyimpangan tertata dengan baik",
                    showError: _missingFields.contains("$fOpsiPrefix 1"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi1,
                    onChanged: (v) {
                      setState(() => opsi1 = v);
                      _clearMissing("$fOpsiPrefix 1");
                    },
                  ),

                  LabelText(
                    "Furnitur Kantor & Ergonomi dalam kondisi baik",
                    showError: _missingFields.contains("$fOpsiPrefix 2"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi2,
                    onChanged: (v) {
                      setState(() => opsi2 = v);
                      _clearMissing("$fOpsiPrefix 2");
                    },
                  ),

                  LabelText(
                    "Struktur : Atap, dinding, pintu, jendela, lantai, dll dalam kondisi baik",
                    showError: _missingFields.contains("$fOpsiPrefix 3"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi3,
                    onChanged: (v) {
                      setState(() => opsi3 = v);
                      _clearMissing("$fOpsiPrefix 3");
                    },
                  ),

                  LabelText(
                    "Daerah berjalan / daerah bekerja tersedia demarkasi",
                    showError: _missingFields.contains("$fOpsiPrefix 4"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi4,
                    onChanged: (v) {
                      setState(() => opsi4 = v);
                      _clearMissing("$fOpsiPrefix 4");
                    },
                  ),

                  LabelText(
                    "Toilet & kamar ganti bersih dan dilakukan perawatan",
                    showError: _missingFields.contains("$fOpsiPrefix 5"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi5,
                    onChanged: (v) {
                      setState(() => opsi5 = v);
                      _clearMissing("$fOpsiPrefix 5");
                    },
                  ),

                  LabelText(
                    "Penerangan / ventilasi / Sistem Ekstraksi memadai dan cukup",
                    showError: _missingFields.contains("$fOpsiPrefix 6"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi6,
                    onChanged: (v) {
                      setState(() => opsi6 = v);
                      _clearMissing("$fOpsiPrefix 6");
                    },
                  ),

                  LabelText(
                    "Housekeeping dilakukan dengan baik & kebersihan umum dilakukan secara rutin",
                    showError: _missingFields.contains("$fOpsiPrefix 7"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi7,
                    onChanged: (v) {
                      setState(() => opsi7 = v);
                      _clearMissing("$fOpsiPrefix 7");
                    },
                  ),

                  LabelText(
                    "Rambu-rambu tanda & kode warna tersedia dan dipasang diarea kerja",
                    showError: _missingFields.contains("$fOpsiPrefix 8"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi8,
                    onChanged: (v) {
                      setState(() => opsi8 = v);
                      _clearMissing("$fOpsiPrefix 8");
                    },
                  ),

                  LabelText(
                    "Jalan dan parkir mencukupi / kondisi baik dan rapi (Parkir Mundur)",
                    showError: _missingFields.contains("$fOpsiPrefix 9"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi9,
                    onChanged: (v) {
                      setState(() => opsi9 = v);
                      _clearMissing("$fOpsiPrefix 9");
                    },
                  ),

                  LabelText(
                    "Pengamanan mesin dan penutup dilaksanakan",
                    showError: _missingFields.contains("$fOpsiPrefix 10"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi10,
                    onChanged: (v) {
                      setState(() => opsi10 = v);
                      _clearMissing("$fOpsiPrefix 10");
                    },
                  ),
                  LabelText(
                    "Alat-alat lock out / Danger Tag tersedia dan karyawan melakukan LOTO setiap servis",
                    showError: _missingFields.contains("$fOpsiPrefix 11"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi11,
                    onChanged: (v) {
                      setState(() => opsi11 = v);
                      _clearMissing("$fOpsiPrefix 11");
                    },
                  ),

                  LabelText(
                    "Pengaturan peralatan listrik termasuk Grounding sistem tersedia",
                    showError: _missingFields.contains("$fOpsiPrefix 12"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi12,
                    onChanged: (v) {
                      setState(() => opsi12 = v);
                      _clearMissing("$fOpsiPrefix 12");
                    },
                  ),

                  LabelText(
                    "Pipa, Keran dan katup (Tidak ada kebocoran)",
                    showError: _missingFields.contains("$fOpsiPrefix 13"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi13,
                    onChanged: (v) {
                      setState(() => opsi13 = v);
                      _clearMissing("$fOpsiPrefix 13");
                    },
                  ),

                  LabelText(
                    "Stairs / Platforms / Elevated Walkways / Handrails tersedia dan dilakukan pemeriksaan",
                    showError: _missingFields.contains("$fOpsiPrefix 14"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi14,
                    onChanged: (v) {
                      setState(() => opsi14 = v);
                      _clearMissing("$fOpsiPrefix 14");
                    },
                  ),

                  LabelText(
                    "Overhead Cranes / Slings / Alat Angkat tersedia dan telah tersedia",
                    showError: _missingFields.contains("$fOpsiPrefix 15"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi15,
                    onChanged: (v) {
                      setState(() => opsi15 = v);
                      _clearMissing("$fOpsiPrefix 15");
                    },
                  ),

                  LabelText(
                    "Penyimpanan silinder gas terkompresi / peralatan obor",
                    showError: _missingFields.contains("$fOpsiPrefix 16"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi16,
                    onChanged: (v) {
                      setState(() => opsi16 = v);
                      _clearMissing("$fOpsiPrefix 16");
                    },
                  ),

                  LabelText(
                    "Penyimpanan dan Pengendalian bahan kimia berbahaya & beracun",
                    showError: _missingFields.contains("$fOpsiPrefix 17"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi17,
                    onChanged: (v) {
                      setState(() => opsi17 = v);
                      _clearMissing("$fOpsiPrefix 17");
                    },
                  ),

                  LabelText(
                    "Perkakas tangan dan peralatan telah tersedia",
                    showError: _missingFields.contains("$fOpsiPrefix 18"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi18,
                    onChanged: (v) {
                      setState(() => opsi18 = v);
                      _clearMissing("$fOpsiPrefix 18");
                    },
                  ),

                  LabelText(
                    "Inspeksi P2H & kondisi kendaraan dilaksanakan",
                    showError: _missingFields.contains("$fOpsiPrefix 19"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi19,
                    onChanged: (v) {
                      setState(() => opsi19 = v);
                      _clearMissing("$fOpsiPrefix 19");
                    },
                  ),
                  LabelText(
                    "Alat Pelindung Diri digunakan ditempat kerja",
                    showError: _missingFields.contains("$fOpsiPrefix 20"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi20,
                    onChanged: (v) {
                      setState(() => opsi20 = v);
                      _clearMissing("$fOpsiPrefix 20");
                    },
                  ),

                  LabelText(
                    "Tabir Las dipakai",
                    showError: _missingFields.contains("$fOpsiPrefix 21"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi21,
                    onChanged: (v) {
                      setState(() => opsi21 = v);
                      _clearMissing("$fOpsiPrefix 21");
                    },
                  ),

                  LabelText(fFoto1, showError: _missingFields.contains(fFoto1)),
                  UploadBox(
                    text: foto1 == null
                        ? "Pilih Foto"
                        : foto1!.path.split("/").last,
                    icon: Icons.photo,
                    onTap: () => pickFoto(1),
                  ),

                  LabelText(fFoto2, showError: _missingFields.contains(fFoto2)),
                  UploadBox(
                    text: foto2 == null
                        ? "Pilih Foto"
                        : foto2!.path.split("/").last,
                    icon: Icons.photo,
                    onTap: () => pickFoto(2),
                  ),

                  LabelText(fFoto3, showError: _missingFields.contains(fFoto3)),
                  UploadBox(
                    text: foto3 == null
                        ? "Pilih Foto"
                        : foto3!.path.split("/").last,
                    icon: Icons.photo,
                    onTap: () => pickFoto(3),
                  ),

                  LabelText(fFoto4, showError: _missingFields.contains(fFoto4)),
                  UploadBox(
                    text: foto4 == null
                        ? "Pilih Foto"
                        : foto4!.path.split("/").last,
                    icon: Icons.photo,
                    onTap: () => pickFoto(4),
                  ),

                  LabelText(
                    fKetHasil,
                    showError: _missingFields.contains(fKetHasil),
                  ),
                  InputField(
                    controller: ket_hasil_temuan,
                    hint: "Masukkan Keterangan",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fKetHasil);
                      }
                    },
                  ),

                  LabelText(
                    fSaranMasuk,
                    showError: _missingFields.contains(fSaranMasuk),
                  ),
                  InputField(
                    controller: saran_masuk,
                    hint: "Masukkan Saran",

                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fSaranMasuk);
                      }
                    },
                  ),

                  LabelText(
                    fStatusInspeksi,
                    showError: _missingFields.contains(fStatusInspeksi),
                  ),
                  OpsiRow(
                    selected: status_inspeksi,
                    onSelected: (String value) {
                      setState(() => status_inspeksi = value);
                      _clearMissing(fStatusInspeksi);
                    },
                  ),

                  LabelText(
                    "Tempat sampah mencukupi / dikosongkan secara berkala",
                    showError: _missingFields.contains("$fOpsiPrefix 22"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi22,
                    onChanged: (v) {
                      setState(() => opsi22 = v);
                      _clearMissing("$fOpsiPrefix 22");
                    },
                  ),

                  LabelText(
                    "Sistem peringatan pergerakan (klakson / alarm) digunakan",
                    showError: _missingFields.contains("$fOpsiPrefix 23"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi23,
                    onChanged: (v) {
                      setState(() => opsi23 = v);
                      _clearMissing("$fOpsiPrefix 23");
                    },
                  ),

                  LabelText(
                    "Perlindungan dan pencegahan kebakaran tersedia (APAR, Hydrant)",
                    showError: _missingFields.contains("$fOpsiPrefix 24"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi24,
                    onChanged: (v) {
                      setState(() => opsi24 = v);
                      _clearMissing("$fOpsiPrefix 24");
                    },
                  ),

                  LabelText(
                    "Tempat berkumpul darurat dan alarm tersedia dan berfungsi",
                    showError: _missingFields.contains("$fOpsiPrefix 25"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi25,
                    onChanged: (v) {
                      setState(() => opsi25 = v);
                      _clearMissing("$fOpsiPrefix 25");
                    },
                  ),

                  LabelText(
                    "Peralatan pertolongan pertama tersedia dan tercukupi",
                    showError: _missingFields.contains("$fOpsiPrefix 26"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi26,
                    onChanged: (v) {
                      setState(() => opsi26 = v);
                      _clearMissing("$fOpsiPrefix 26");
                    },
                  ),

                  SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isSubmitting
                            ? null
                            : LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.purpleAccent,
                                ],
                              ),
                        color: _isSubmitting ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : submitInspeksiPlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Mengirim...",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : Text(
                                "Kirim Inspeksi",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pilihTanggal() async {
    DateTime? pick = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (pick != null) {
      setState(() {
        tanggal.text = DateFormat("yyyy-MM-dd").format(pick);
        _clearMissing(fTanggal);
      });
    }
  }

  void pickFoto(int index) async {
    final picker = ImagePicker();
    XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        if (index == 1) {
          foto1 = File(img.path);
          _clearMissing(fFoto1);
        }
        if (index == 2) {
          foto2 = File(img.path);
          _clearMissing(fFoto2);
        }
        if (index == 3) {
          foto3 = File(img.path);
          _clearMissing(fFoto3);
        }
        if (index == 4) {
          foto4 = File(img.path);
          _clearMissing(fFoto4);
        }
      });
    }
  }

  void submitInspeksiPlant() async {
    if (_isSubmitting) return;

    final missing = _getMissingFields();

    setState(() {
      _missingFields = missing;
    });

    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Gradient
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffFF5F6D), Color(0xffFF7A45)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Data Belum Lengkap",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Field berikut masih kosong:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: missing
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF6A55),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Mengerti",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Mengirim data Inspeksi..."),
              ],
            ),
          ),
        );
      },
    );

    bool ok = false;

    try {
      ok = await InspeksiPlantService.submitInspeksiPlant(
        nama: nama.text,
        nrp: nrp.text,
        department: department ?? "",
        perusahaan: perusahaan ?? "",
        tanggal: tanggal.text,
        jumlahInspektor: jumlah_inspektor.text,

        opsi1: opsi1 ?? "",
        opsi2: opsi2 ?? "",
        opsi3: opsi3 ?? "",
        opsi4: opsi4 ?? "",
        opsi5: opsi5 ?? "",
        opsi6: opsi6 ?? "",
        opsi7: opsi7 ?? "",
        opsi8: opsi8 ?? "",
        opsi9: opsi9 ?? "",
        opsi10: opsi10 ?? "",
        opsi11: opsi11 ?? "",
        opsi12: opsi12 ?? "",
        opsi13: opsi13 ?? "",
        opsi14: opsi14 ?? "",
        opsi15: opsi15 ?? "",
        opsi16: opsi16 ?? "",
        opsi17: opsi17 ?? "",
        opsi18: opsi18 ?? "",
        opsi19: opsi19 ?? "",
        opsi20: opsi20 ?? "",
        opsi21: opsi21 ?? "",
        opsi22: opsi22 ?? "",
        opsi23: opsi23 ?? "",
        opsi24: opsi24 ?? "",
        opsi25: opsi25 ?? "",
        opsi26: opsi26 ?? "",

        ketHasil: ket_hasil_temuan.text,
        saranMasuk: saran_masuk.text,
        statusInspeksi: status_inspeksi ?? "",

        foto1Path: foto1?.path,
        foto2Path: foto2?.path,
        foto3Path: foto3?.path,
        foto4Path: foto4?.path,
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    showStatusDialog(
      context: context,
      success: ok,
      onDone: () {
        Navigator.pop(context);

        if (ok) {
          Navigator.pop(context);
        }
      },
    );
  }
}

void showStatusDialog({
  required BuildContext context,
  required bool success,
  required VoidCallback onDone,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(vertical: 28),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 80,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            success ? "Berhasil Terkirim" : "Gagal Terkirim",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? "Data Inspeksi berhasil dikirim"
                : "Data Inspeksi Belum Lengkap",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? Colors.green : Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onDone,
              child: Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}
