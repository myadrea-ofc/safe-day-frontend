import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/service/p2h/p2h_wheelloader.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_other.dart';
import 'package:safety_apps/widgets/date_field.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_department.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_perusahaan.dart';
import 'package:safety_apps/widgets/image_comprssor.dart';
import 'package:safety_apps/widgets/input/input_field.dart';
import 'package:safety_apps/widgets/label_text.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna2.dart';
import 'package:safety_apps/widgets/upload_box.dart';

class FormP2HWheelLoader extends StatefulWidget {
  @override
  _FormP2HWheelLoaderPageState createState() => _FormP2HWheelLoaderPageState();
}

class _FormP2HWheelLoaderPageState extends State<FormP2HWheelLoader> {
  TextEditingController nama = TextEditingController();
  TextEditingController nrp = TextEditingController();
  TextEditingController waktu = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController hm_unit = TextEditingController();
  TextEditingController lokasi_kerja = TextEditingController();

  String? department;
  String? jabatan;
  String? perusahaan;
  String? noLambungUnit;
  String? jam_tidur;

  String? opsiitem1;
  String? opsiitem2;
  String? opsiitem3;
  String? opsiitem4;
  String? opsiitem5;
  String? opsiitem6;
  String? opsiitem7;
  String? opsiitem8;
  String? opsiitem9;
  String? opsiitem10;
  String? opsiitem11;
  String? opsiitem12;
  String? opsiitem13;
  String? opsiitem14;
  String? opsiitem15;
  String? opsiitem16;
  String? opsiitem17;
  String? opsiitem18;
  String? opsiitem19;
  String? opsiitem20;
  String? opsiitem21;
  String? opsiitem22;
  String? opsiitem23;
  String? opsiitem24;
  String? opsiitem25;
  String? opsiitem26;
  String? opsiitem27;
  String? opsiitem28;
  String? opsiitem29;
  String? opsiitem30;
  String? opsiitem31;

  String? opsistandardkeselamatan1;
  String? opsistandardkeselamatan2;
  String? opsistandardkeselamatan3;

  String? status_keadaan1;
  String? status_keadaan2;
  String? status_keadaan3;
  String? status_keadaan4;
  String? status_keadaan5;
  String? status_keadaan6;

  String? status_siap;

  List<XFile> selectedDokumen = [];

  bool _isSubmitting = false;

  static const fNama = "Nama";
  static const fNRP = "NRP";
  static const fJabatan = "Jabatan";
  static const fDepartment = "Department";
  static const fPerusahaan = "Perusahaan";
  static const fNoLambungUnit = "No Lambung Unit";
  static const fTanggal = "Tanggal";
  static const fWaktu = "Waktu P2H";
  static const fHM = "Hour Meter Unit";
  static const fLokasiKerja = "Lokasi Kerja";
  static const fOpsiPrefix = "Item P2H";
  static const fStatusSiap = "Status Kesiapan";
  static const fDokumen = "Dokumen / Foto";
  static const fJamTidur = "Berapa jam tidur Anda sebelum bekerja?";
  static const fKondisiPrefix = "Kondisi Operator";
  static const fStandarPrefix = "Standar Keselamatan";

  Map<int, String?> get _opsiMap => {
    1: opsiitem1,
    2: opsiitem2,
    3: opsiitem3,
    4: opsiitem4,
    5: opsiitem5,
    6: opsiitem6,
    7: opsiitem7,
    8: opsiitem8,
    9: opsiitem9,
    10: opsiitem10,
    11: opsiitem11,
    12: opsiitem12,
    13: opsiitem13,
    14: opsiitem14,
    15: opsiitem15,
    16: opsiitem16,
    17: opsiitem17,
    18: opsiitem18,
    19: opsiitem19,
    20: opsiitem20,
    21: opsiitem21,
    22: opsiitem22,
    23: opsiitem23,
    24: opsiitem24,
    25: opsiitem25,
    26: opsiitem26,
    27: opsiitem27,
    28: opsiitem28,
    29: opsiitem29,
    30: opsiitem30,
    31: opsiitem31,
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (nrp.text.trim().isEmpty) missing.add(fNRP);
    if (hm_unit.text.trim().isEmpty) missing.add(fHM);
    if (lokasi_kerja.text.trim().isEmpty) missing.add(fLokasiKerja);
    if (jabatan == null) missing.add(fJabatan);
    if (department == null) missing.add(fDepartment);
    if (perusahaan == null) missing.add(fPerusahaan);
    if (noLambungUnit == null) missing.add(fNoLambungUnit);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
    if (waktu.text.isEmpty) missing.add(fWaktu);
    if (jam_tidur == null) missing.add(fJamTidur);

    _opsiMap.forEach((i, v) {
      if (v == null || v.isEmpty) {
        missing.add("$fOpsiPrefix $i");
      }
    });

    if (status_siap == null) missing.add(fStatusSiap);
    if (selectedDokumen.isEmpty) missing.add(fDokumen);

    final kondisiMap = {
      1: status_keadaan1,
      2: status_keadaan2,
      3: status_keadaan3,
      4: status_keadaan4,
      5: status_keadaan5,
      6: status_keadaan6,
    };

    final standarMap = {
      1: opsistandardkeselamatan1,
      2: opsistandardkeselamatan2,
      3: opsistandardkeselamatan3,
    };

    standarMap.forEach((i, v) {
      if (v == null || v.isEmpty) {
        missing.add("$fStandarPrefix $i");
      }
    });

    kondisiMap.forEach((i, v) {
      if (v == null || v.isEmpty) {
        missing.add("$fKondisiPrefix $i");
      }
    });

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
      if (nrp.text.trim().isNotEmpty) {
        _clearMissing(fNRP);
      }
      if (lokasi_kerja.text.trim().isNotEmpty) {
        _clearMissing(fLokasiKerja);
      }
      if (hm_unit.text.trim().isNotEmpty) {
        _clearMissing(fHM);
      }
    });
  }

  bool isImageFile(String path) {
    final ext = path.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic'].any(ext.endsWith);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffFF5F6D), Color(0xffFF7A45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
          ),
          title: const Text(
            "Form P2H Wheel Loader",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFF7A45), Color(0xffFF5F6D)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                    color: Colors.black12.withOpacity(0.08),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      "Form P2H Wheel Loader",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                    color: Colors.black12.withOpacity(0.07),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabelText(fNama, showError: _missingFields.contains(fNama)),
                  InputField(
                    controller: nama,
                    hint: "Masukkan nama peserta",
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
                    fJabatan,
                    showError: _missingFields.contains(fJabatan),
                  ),
                  CheckboxOther(
                    selected: jabatan,
                    options: ["Operator", "Pengawas", "Trainer"],
                    onChanged: (v) {
                      setState(() => jabatan = v);
                      _clearMissing(fJabatan);
                    },
                  ),

                  LabelText(
                    fDepartment,
                    showError: _missingFields.contains(fDepartment),
                  ),
                  DropdownDepartment(
                    value: department,
                    onChanged: (v) {
                      setState(() => department = v);
                      _clearMissing(fDepartment);
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
                      _clearMissing(fPerusahaan);
                    },
                  ),

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
                    fLokasiKerja,
                    showError: _missingFields.contains(fLokasiKerja),
                  ),
                  InputField(
                    controller: lokasi_kerja,
                    hint: "Masukkan lokasi kerja",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fLokasiKerja);
                      }
                    },
                  ),

                  LabelText(fHM, showError: _missingFields.contains(fHM)),
                  InputField(
                    controller: hm_unit,
                    hint: "Masukkan HM unit",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fHM);
                      }
                    },
                  ),

                  LabelText(
                    fNoLambungUnit,
                    showError: _missingFields.contains(fNoLambungUnit),
                  ),
                  CheckboxForm(
                    selected: noLambungUnit,
                    options: [
                      "JCB-JCB 058",
                      "JCB-JCB 059",
                      "XC958-XCM 2012",
                      "XC958-XCM 2013",
                      "XC958-XCM 2014",
                    ],
                    onChanged: (v) {
                      setState(() => noLambungUnit = v);
                      _clearMissing(fNoLambungUnit);
                    },
                  ),

                  LabelText("Item Pemerikasaan Wheel Loader"),

                  LabelText(
                    "Level Air Radiator",
                    showError: _missingFields.contains("$fOpsiPrefix 1"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem1,
                    onSelected: (v) {
                      setState(() => opsiitem1 = v);
                      _clearMissing("$fOpsiPrefix 1");
                    },
                  ),

                  LabelText(
                    "Bocor Radiator atau Pipa Air",
                    showError: _missingFields.contains("$fOpsiPrefix 2"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem2,
                    onSelected: (v) {
                      setState(() => opsiitem2 = v);
                      _clearMissing("$fOpsiPrefix 2");
                    },
                  ),

                  LabelText(
                    "Level Minyak Rem",
                    showError: _missingFields.contains("$fOpsiPrefix 3"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem3,
                    onSelected: (v) {
                      setState(() => opsiitem3 = v);
                      _clearMissing("$fOpsiPrefix 3");
                    },
                  ),

                  LabelText(
                    "Level Air Aki",
                    showError: _missingFields.contains("$fOpsiPrefix 4"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem4,
                    onSelected: (v) {
                      setState(() => opsiitem4 = v);
                      _clearMissing("$fOpsiPrefix 4");
                    },
                  ),

                  LabelText(
                    "Oli Mesin",
                    showError: _missingFields.contains("$fOpsiPrefix 5"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem5,
                    onSelected: (v) {
                      setState(() => opsiitem5 = v);
                      _clearMissing("$fOpsiPrefix 5");
                    },
                  ),

                  LabelText(
                    "Bahan Bakar",
                    showError: _missingFields.contains("$fOpsiPrefix 6"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem6,
                    onSelected: (v) {
                      setState(() => opsiitem6 = v);
                      _clearMissing("$fOpsiPrefix 6");
                    },
                  ),

                  LabelText(
                    "Kondisi Wiper",
                    showError: _missingFields.contains("$fOpsiPrefix 7"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem7,
                    onSelected: (v) {
                      setState(() => opsiitem7 = v);
                      _clearMissing("$fOpsiPrefix 7");
                    },
                  ),

                  LabelText(
                    "Kondisi Ban (Kondisi Fisik, Kelurusan, Tekanan & Sekrup)",
                    showError: _missingFields.contains("$fOpsiPrefix 8"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem8,
                    onSelected: (v) {
                      setState(() => opsiitem8 = v);
                      _clearMissing("$fOpsiPrefix 8");
                    },
                  ),

                  LabelText(
                    "Kondisi Rem (Kaki, Parkir & Emergency)",
                    showError: _missingFields.contains("$fOpsiPrefix 9"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem9,
                    onSelected: (v) {
                      setState(() => opsiitem9 = v);
                      _clearMissing("$fOpsiPrefix 9");
                    },
                  ),

                  LabelText(
                    "Kondisi Lampu Rotary, Stop, Depan, Belakang",
                    showError: _missingFields.contains("$fOpsiPrefix 10"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem10,
                    onSelected: (v) {
                      setState(() => opsiitem10 = v);
                      _clearMissing("$fOpsiPrefix 10");
                    },
                  ),

                  LabelText(
                    "Kondisi Lampu Body, Sen Kanan, Sen Kiri dan Bahaya",
                    showError: _missingFields.contains("$fOpsiPrefix 11"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem11,
                    onSelected: (v) {
                      setState(() => opsiitem11 = v);
                      _clearMissing("$fOpsiPrefix 11");
                    },
                  ),

                  LabelText(
                    "Kondisi Kaca Depan, Belakang, Jendela & Spion",
                    showError: _missingFields.contains("$fOpsiPrefix 12"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem12,
                    onSelected: (v) {
                      setState(() => opsiitem12 = v);
                      _clearMissing("$fOpsiPrefix 12");
                    },
                  ),

                  LabelText(
                    "Cermin Pandang Belakang & Sisi",
                    showError: _missingFields.contains("$fOpsiPrefix 13"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem13,
                    onSelected: (v) {
                      setState(() => opsiitem13 = v);
                      _clearMissing("$fOpsiPrefix 13");
                    },
                  ),

                  LabelText(
                    "Keadaan Body, kabin dan kursi Operator",
                    showError: _missingFields.contains("$fOpsiPrefix 14"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem14,
                    onSelected: (v) {
                      setState(() => opsiitem14 = v);
                      _clearMissing("$fOpsiPrefix 14");
                    },
                  ),

                  LabelText(
                    "Suhu Mesin",
                    showError: _missingFields.contains("$fOpsiPrefix 15"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem15,
                    onSelected: (v) {
                      setState(() => opsiitem15 = v);
                      _clearMissing("$fOpsiPrefix 15");
                    },
                  ),

                  LabelText(
                    "Klakson",
                    showError: _missingFields.contains("$fOpsiPrefix 16"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem16,
                    onSelected: (v) {
                      setState(() => opsiitem16 = v);
                      _clearMissing("$fOpsiPrefix 16");
                    },
                  ),

                  LabelText(
                    "Uji Rem Fisik",
                    showError: _missingFields.contains("$fOpsiPrefix 17"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem17,
                    onSelected: (v) {
                      setState(() => opsiitem17 = v);
                      _clearMissing("$fOpsiPrefix 17");
                    },
                  ),

                  LabelText(
                    "Pedal Rem Servis dan Modulasi Transmisi",
                    showError: _missingFields.contains("$fOpsiPrefix 18"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem18,
                    onSelected: (v) {
                      setState(() => opsiitem18 = v);
                      _clearMissing("$fOpsiPrefix 18");
                    },
                  ),

                  LabelText(
                    "Reaksi Kemudi",
                    showError: _missingFields.contains("$fOpsiPrefix 19"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem19,
                    onSelected: (v) {
                      setState(() => opsiitem19 = v);
                      _clearMissing("$fOpsiPrefix 19");
                    },
                  ),

                  LabelText(
                    "Tuas Kemudi",
                    showError: _missingFields.contains("$fOpsiPrefix 20"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem20,
                    onSelected: (v) {
                      setState(() => opsiitem20 = v);
                      _clearMissing("$fOpsiPrefix 20");
                    },
                  ),

                  LabelText(
                    "Sistem Hidrolik",
                    showError: _missingFields.contains("$fOpsiPrefix 21"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem21,
                    onSelected: (v) {
                      setState(() => opsiitem21 = v);
                      _clearMissing("$fOpsiPrefix 21");
                    },
                  ),

                  LabelText(
                    "Silinder Hidrolik",
                    showError: _missingFields.contains("$fOpsiPrefix 22"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem22,
                    onSelected: (v) {
                      setState(() => opsiitem22 = v);
                      _clearMissing("$fOpsiPrefix 22");
                    },
                  ),

                  LabelText(
                    "Mesin,",
                    showError: _missingFields.contains("$fOpsiPrefix 23"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem23,
                    onSelected: (v) {
                      setState(() => opsiitem23 = v);
                      _clearMissing("$fOpsiPrefix 23");
                    },
                  ),

                  LabelText(
                    "Kondisi Shovel",
                    showError: _missingFields.contains("$fOpsiPrefix 24"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem24,
                    onSelected: (v) {
                      setState(() => opsiitem24 = v);
                      _clearMissing("$fOpsiPrefix 24");
                    },
                  ),

                  LabelText(
                    "Sistem Elektrik",
                    showError: _missingFields.contains("$fOpsiPrefix 25"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem25,
                    onSelected: (v) {
                      setState(() => opsiitem25 = v);
                      _clearMissing("$fOpsiPrefix 25");
                    },
                  ),

                  LabelText(
                    "Instrumen Panel",
                    showError: _missingFields.contains("$fOpsiPrefix 26"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem26,
                    onSelected: (v) {
                      setState(() => opsiitem26 = v);
                      _clearMissing("$fOpsiPrefix 26");
                    },
                  ),

                  LabelText(
                    "Alat Pemadam Api",
                    showError: _missingFields.contains("$fOpsiPrefix 27"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem27,
                    onSelected: (v) {
                      setState(() => opsiitem27 = v);
                      _clearMissing("$fOpsiPrefix 27");
                    },
                  ),

                  LabelText(
                    "Kotak PK3",
                    showError: _missingFields.contains("$fOpsiPrefix 28"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem28,
                    onSelected: (v) {
                      setState(() => opsiitem28 = v);
                      _clearMissing("$fOpsiPrefix 28");
                    },
                  ),

                  LabelText(
                    "Sabuk Keselamatan",
                    showError: _missingFields.contains("$fOpsiPrefix 29"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem29,
                    onSelected: (v) {
                      setState(() => opsiitem29 = v);
                      _clearMissing("$fOpsiPrefix 29");
                    },
                  ),

                  LabelText(
                    "Radio Komunikasi",
                    showError: _missingFields.contains("$fOpsiPrefix 30"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem30,
                    onSelected: (v) {
                      setState(() => opsiitem30 = v);
                      _clearMissing("$fOpsiPrefix 30");
                    },
                  ),

                  LabelText(
                    "SIMPER",
                    showError: _missingFields.contains("$fOpsiPrefix 31"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem31,
                    onSelected: (v) {
                      setState(() => opsiitem31 = v);
                      _clearMissing("$fOpsiPrefix 31");
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText("Standard Keselamatan - Alat Keselamatan"),

                  LabelText(
                    "Safety Cone / Segitiga",
                    showError: _missingFields.contains("$fStandarPrefix 1"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan1,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan1 = v);
                      _clearMissing("$fStandarPrefix 1");
                    },
                  ),

                  LabelText(
                    "APAR (alat pemadam api ringan)",
                    showError: _missingFields.contains("$fStandarPrefix 2"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan2,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan2 = v);
                      _clearMissing("$fStandarPrefix 2");
                    },
                  ),

                  LabelText(
                    "Kotak P3K",
                    showError: _missingFields.contains("$fStandarPrefix 3"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan3,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan2 = v);
                      _clearMissing("$fStandarPrefix 2");
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText(
                    "Temuan Hasil Pemekrisaan P2H \n (Maks total size : 5 MB)",
                    showError: _missingFields.contains(fDokumen),
                  ),
                  UploadBox(
                    text: selectedDokumen.isEmpty
                        ? "Pilih Dokumen (Maks 5 File)"
                        : selectedDokumen
                              .map((f) => f.path.split("/").last)
                              .join(", "),
                    icon: Icons.attach_file_rounded,
                    onTap: pickFile,
                  ),

                  LabelText(
                    fJamTidur,
                    showError: _missingFields.contains(fJamTidur),
                  ),
                  CheckboxForm(
                    selected: jam_tidur,
                    options: ["1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7", "8"],
                    onChanged: (v) {
                      setState(() => jam_tidur = v);
                      _clearMissing(fJamTidur);
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText("Isi sesuai dengan kondisi Anda saat ini"),

                  LabelText(
                    "Apakah Anda sedang mengkonsumsi obat yang menyebabkan mengantuk",
                    showError: _missingFields.contains("$fKondisiPrefix 1"),
                  ),
                  OpsiRow(
                    selected: status_keadaan1,
                    onSelected: (v) {
                      setState(() => status_keadaan1 = v);
                      _clearMissing("$fKondisiPrefix 1");
                    },
                  ),

                  LabelText(
                    "Apakah jam tidur anda cukup hari ini minimal 6 jam",
                    showError: _missingFields.contains("$fKondisiPrefix 2"),
                  ),
                  OpsiRow(
                    selected: status_keadaan2,
                    onSelected: (v) {
                      setState(() => status_keadaan2 = v);
                      _clearMissing("$fKondisiPrefix 2");
                    },
                  ),

                  LabelText(
                    "Apakah Anda tidak ada permasalahan dengan keluarga yang mengganggu konsentrasi Anda",
                    showError: _missingFields.contains("$fKondisiPrefix 3"),
                  ),
                  OpsiRow(
                    selected: status_keadaan3,
                    onSelected: (v) {
                      setState(() => status_keadaan3 = v);
                      _clearMissing("$fKondisiPrefix 3");
                    },
                  ),

                  LabelText(
                    "Apakah Anda memiliki masalah dengan atasan Anda",
                    showError: _missingFields.contains("$fKondisiPrefix 4"),
                  ),
                  OpsiRow(
                    selected: status_keadaan4,
                    onSelected: (v) {
                      setState(() => status_keadaan4 = v);
                      _clearMissing("$fKondisiPrefix 4");
                    },
                  ),

                  LabelText(
                    "Apakah Anda merasa kurang konsentrasi hari ini",
                    showError: _missingFields.contains("$fKondisiPrefix 5"),
                  ),
                  OpsiRow(
                    selected: status_keadaan5,
                    onSelected: (v) {
                      setState(() => status_keadaan5 = v);
                      _clearMissing("$fKondisiPrefix 5");
                    },
                  ),

                  LabelText(
                    "Apakah Anda merasa pandangan mata Anda letih",
                    showError: _missingFields.contains("$fKondisiPrefix 6"),
                  ),
                  OpsiRow(
                    selected: status_keadaan6,
                    onSelected: (v) {
                      setState(() => status_keadaan6 = v);
                      _clearMissing("$fKondisiPrefix 6");
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText(
                    "Apakah Anda sudah siap untuk bekerja baik secara mental dan fisik",
                    showError: _missingFields.contains(fStatusSiap),
                  ),
                  OpsiRow(
                    selected: status_siap,
                    onSelected: (v) {
                      setState(() => status_siap = v);
                      _clearMissing(fStatusSiap);
                    },
                  ),

                  SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isSubmitting
                            ? null
                            : LinearGradient(
                                colors: [Color(0xffFF5F6D), Color(0xffFF7A45)],
                              ),
                        color: _isSubmitting ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : submitP2HWheelLoader,
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
                                "Kirim P2H Wheel Loader",
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

  void pilihWaktu() async {
    TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      setState(() {
        waktu.text =
            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
        _clearMissing(fWaktu);
      });
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'png',
        'jpg',
        'jpeg',
        'heic',
      ],
    );

    if (result == null) return;

    if (result.files.length > 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Maksimal 5 file")));
      return;
    }

    const hardLimit = 10 * 1024 * 1024;
    final invalid = result.files.where((f) => f.size > hardLimit).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ada file > 10 MB, silakan pilih file lebih kecil"),
        ),
      );
      return;
    }
    setState(() {
      selectedDokumen = result.paths.map((p) => XFile(p!)).toList();
      _clearMissing(fDokumen);
    });
  }

  void submitP2HWheelLoader() async {
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

    late BuildContext loadingCtx;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingCtx = ctx;
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
                Text("Mengirim data P2H..."),
              ],
            ),
          ),
        );
      },
    );

    setState(() => _isSubmitting = true);
    const maxFileSize = 5 * 1024 * 1024;
    List<File> processedFiles = [];

    try {
      for (final picked in selectedDokumen) {
        final file = File(picked.path);

        if (isImageFile(file.path)) {
          final compressed = await ImageCompressor.compressIfNeeded(file);

          if (compressed.lengthSync() > maxFileSize) {
            throw Exception("Gagal mengompres ${picked.name}");
          }
          processedFiles.add(compressed);
        } else {
          if (file.lengthSync() > maxFileSize) {
            throw Exception("File ${picked.name} melebihi 5 MB");
          }
          processedFiles.add(file);
        }
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(loadingCtx);
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Upload Gagal"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    bool ok = false;
    try {
      ok = await P2HWheelLoaderService.submitP2HWheelLoader(
        nama: nama.text,
        nrp: nrp.text,
        jabatan: jabatan ?? "",
        department: department ?? "",
        perusahaan: perusahaan ?? "",
        tanggal: tanggal.text,

        lokasiKerja: lokasi_kerja.text,
        hmUnit: hm_unit.text,
        noLambungUnit: noLambungUnit ?? "",

        opsiItem1: opsiitem1 ?? "",
        opsiItem2: opsiitem2 ?? "",
        opsiItem3: opsiitem3 ?? "",
        opsiItem4: opsiitem4 ?? "",
        opsiItem5: opsiitem5 ?? "",
        opsiItem6: opsiitem6 ?? "",
        opsiItem7: opsiitem7 ?? "",
        opsiItem8: opsiitem8 ?? "",
        opsiItem9: opsiitem9 ?? "",
        opsiItem10: opsiitem10 ?? "",
        opsiItem11: opsiitem11 ?? "",
        opsiItem12: opsiitem12 ?? "",
        opsiItem13: opsiitem13 ?? "",
        opsiItem14: opsiitem14 ?? "",
        opsiItem15: opsiitem15 ?? "",
        opsiItem16: opsiitem16 ?? "",
        opsiItem17: opsiitem17 ?? "",
        opsiItem18: opsiitem18 ?? "",
        opsiItem19: opsiitem19 ?? "",
        opsiItem20: opsiitem20 ?? "",
        opsiItem21: opsiitem21 ?? "",
        opsiItem22: opsiitem22 ?? "",
        opsiItem23: opsiitem23 ?? "",
        opsiItem24: opsiitem24 ?? "",
        opsiItem25: opsiitem25 ?? "",
        opsiItem26: opsiitem26 ?? "",
        opsiItem27: opsiitem27 ?? "",
        opsiItem28: opsiitem28 ?? "",
        opsiItem29: opsiitem29 ?? "",
        opsiItem30: opsiitem30 ?? "",
        opsiItem31: opsiitem31 ?? "",

        opsiStandarKeselamatan1: opsistandardkeselamatan1 ?? "",
        opsiStandarKeselamatan2: opsistandardkeselamatan2 ?? "",
        opsiStandarKeselamatan3: opsistandardkeselamatan3 ?? "",

        jamTidur: jam_tidur ?? "",

        statusKeadaan1: status_keadaan1 ?? "",
        statusKeadaan2: status_keadaan2 ?? "",
        statusKeadaan3: status_keadaan3 ?? "",
        statusKeadaan4: status_keadaan4 ?? "",
        statusKeadaan5: status_keadaan5 ?? "",
        statusKeadaan6: status_keadaan6 ?? "",

        statusSiap: status_siap ?? "",
        filePaths: processedFiles.map((f) => f.path).toList(),
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    Navigator.pop(loadingCtx);
    setState(() => _isSubmitting = false);

    showStatusDialog(
      context: context,
      success: ok,
      onDone: () {
        Navigator.pop(context);
        if (ok) Navigator.pop(context);
      },
    );
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
              success ? "Data P2H berhasil dikirim" : "Data P2H Belum Lengkap",
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
}
