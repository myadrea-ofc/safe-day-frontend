import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';
import '../../service/inspeksi/inspeksi_kantor_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/upload_box.dart';

class FormInspeksiKantor extends StatefulWidget {
  @override
  _FormInspeksiKantorPageState createState() => _FormInspeksiKantorPageState();
}

class _FormInspeksiKantorPageState extends State<FormInspeksiKantor> {
  TextEditingController nama = TextEditingController();
  TextEditingController nrp = TextEditingController();
  TextEditingController jumlah_inspektor = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController ket_hasil_temuan = TextEditingController();
  TextEditingController saran_masuk = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    nrp.dispose();
    jumlah_inspektor.dispose();
    tanggal.dispose();
    ket_hasil_temuan.dispose();
    saran_masuk.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedPerusahaan;

  String? departmentManual;
  String? perusahaanManual;

  String? status_inspeksi;

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

  XFile? foto1;
  XFile? foto2;
  XFile? foto3;
  XFile? foto4;

  Uint8List? foto1Bytes;
  Uint8List? foto2Bytes;
  Uint8List? foto3Bytes;
  Uint8List? foto4Bytes;

  bool _isSubmitting = false;

  static const int _maxAutoRetry = 3;
  static const Duration _submitTimeout = Duration(seconds: 15);
  static const Duration _retryDelay = Duration(seconds: 1);

  final ValueNotifier<String> _submitProgressText = ValueNotifier(
    "Mengirim data Inspeksi...",
  );

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
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (nrp.text.trim().isEmpty) missing.add(fNRP);
    if (tanggal.text.trim().isEmpty) missing.add(fTanggal);
    if (jumlah_inspektor.text.trim().isEmpty) {
      missing.add(fJumlahInspektor);
    }
    if (selectedDepartment == null) {
      missing.add(fDepartment);
    } else if (selectedDepartment!.isOther &&
        (departmentManual == null || departmentManual!.trim().isEmpty)) {
      missing.add(fDepartment);
    }

    if (selectedPerusahaan == null) {
      missing.add(fPerusahaan);
    } else if (selectedPerusahaan!.isOther &&
        (perusahaanManual == null || perusahaanManual!.trim().isEmpty)) {
      missing.add(fPerusahaan);
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

  Map<String, dynamic> _buildInspeksiKantorPayload() {
    return {
      'nama': nama.text,
      'nrp': nrp.text,
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'tanggal': tanggal.text,
      'jumlahInspektor': jumlah_inspektor.text,

      'opsi1': opsi1 ?? "",
      'opsi2': opsi2 ?? "",
      'opsi3': opsi3 ?? "",
      'opsi4': opsi4 ?? "",
      'opsi5': opsi5 ?? "",
      'opsi6': opsi6 ?? "",
      'opsi7': opsi7 ?? "",
      'opsi8': opsi8 ?? "",
      'opsi9': opsi9 ?? "",
      'opsi10': opsi10 ?? "",
      'opsi11': opsi11 ?? "",
      'opsi12': opsi12 ?? "",
      'opsi13': opsi13 ?? "",
      'opsi14': opsi14 ?? "",
      'opsi15': opsi15 ?? "",
      'opsi16': opsi16 ?? "",
      'opsi17': opsi17 ?? "",
      'opsi18': opsi18 ?? "",
      'opsi19': opsi19 ?? "",
      'opsi20': opsi20 ?? "",
      'opsi21': opsi21 ?? "",
      'opsi22': opsi22 ?? "",

      'ketHasil': ket_hasil_temuan.text,
      'saranMasuk': saran_masuk.text,
      'statusInspeksi': status_inspeksi ?? "",
    };
  }

  List<String> _buildInspeksiKantorFilePaths() {
    if (kIsWeb) return [];

    return [
      if (foto1 != null && foto1!.path.isNotEmpty) foto1!.path,
      if (foto2 != null && foto2!.path.isNotEmpty) foto2!.path,
      if (foto3 != null && foto3!.path.isNotEmpty) foto3!.path,
      if (foto4 != null && foto4!.path.isNotEmpty) foto4!.path,
    ];
  }

  Future<bool> _submitInspeksiKantorOnce(Map<String, dynamic> payload) async {
    return await InspeksiKantorService.submitInspeksiKantor(
      nama: (payload['nama'] ?? '').toString().trim(),
      nrp: (payload['nrp'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),
      jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

      opsi1: (payload['opsi1'] ?? '').toString().trim(),
      opsi2: (payload['opsi2'] ?? '').toString().trim(),
      opsi3: (payload['opsi3'] ?? '').toString().trim(),
      opsi4: (payload['opsi4'] ?? '').toString().trim(),
      opsi5: (payload['opsi5'] ?? '').toString().trim(),
      opsi6: (payload['opsi6'] ?? '').toString().trim(),
      opsi7: (payload['opsi7'] ?? '').toString().trim(),
      opsi8: (payload['opsi8'] ?? '').toString().trim(),
      opsi9: (payload['opsi9'] ?? '').toString().trim(),
      opsi10: (payload['opsi10'] ?? '').toString().trim(),
      opsi11: (payload['opsi11'] ?? '').toString().trim(),
      opsi12: (payload['opsi12'] ?? '').toString().trim(),
      opsi13: (payload['opsi13'] ?? '').toString().trim(),
      opsi14: (payload['opsi14'] ?? '').toString().trim(),
      opsi15: (payload['opsi15'] ?? '').toString().trim(),
      opsi16: (payload['opsi16'] ?? '').toString().trim(),
      opsi17: (payload['opsi17'] ?? '').toString().trim(),
      opsi18: (payload['opsi18'] ?? '').toString().trim(),
      opsi19: (payload['opsi19'] ?? '').toString().trim(),
      opsi20: (payload['opsi20'] ?? '').toString().trim(),
      opsi21: (payload['opsi21'] ?? '').toString().trim(),
      opsi22: (payload['opsi22'] ?? '').toString().trim(),

      ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
      saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
      statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

      foto1Path: kIsWeb ? null : foto1?.path,
      foto2Path: kIsWeb ? null : foto2?.path,
      foto3Path: kIsWeb ? null : foto3?.path,
      foto4Path: kIsWeb ? null : foto4?.path,

      foto1Bytes: kIsWeb ? foto1Bytes : null,
      foto2Bytes: kIsWeb ? foto2Bytes : null,
      foto3Bytes: kIsWeb ? foto3Bytes : null,
      foto4Bytes: kIsWeb ? foto4Bytes : null,

      foto1Name: foto1?.name,
      foto2Name: foto2?.name,
      foto3Name: foto3?.name,
      foto4Name: foto4?.name,
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT INSPEKSI KANTOR TIMEOUT");
        return false;
      },
    );
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
            "Form Inspeksi Kantor",
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
                      "Inspeksi Kantor",
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
                    readOnly: true,
                    onChanged: null,
                  ),

                  LabelText(fNRP, showError: _missingFields.contains(fNRP)),
                  InputField(
                    controller: nrp,
                    hint: "Masukkan NRP",
                    readOnly: true,
                    onChanged: null,
                  ),

                  SearchableMasterDropdown(
                    label: fDepartment,
                    hint: "Pilih Department",
                    endpoint: "master/department",
                    selectedValue: selectedDepartment,
                    showError: _missingFields.contains(fDepartment),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedDepartment = selected;
                        departmentManual = manualValue;
                      });
                      _clearMissing(fDepartment);
                    },
                  ),

                  SearchableMasterDropdown(
                    label: fPerusahaan,
                    hint: "Pilih Perusahaan",
                    endpoint: "master/perusahaan",
                    selectedValue: selectedPerusahaan,
                    showError: _missingFields.contains(fPerusahaan),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedPerusahaan = selected;
                        perusahaanManual = manualValue;
                      });
                      _clearMissing(fPerusahaan);
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
                    "Bangunan, Atap, Dinding, Pintu, Jendela, dsb dalam kondisi baik",
                    showError: _missingFields.contains("$fOpsiPrefix 1"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi1,
                    onSelected: (v) {
                      setState(() => opsi1 = v);
                      _clearMissing("$fOpsiPrefix 1");
                    },
                  ),

                  LabelText(
                    "Permukaan Tempat Jalan dan Lantai tanpa halangan",
                    showError: _missingFields.contains("$fOpsiPrefix 2"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi2,
                    onSelected: (v) {
                      setState(() => opsi2 = v);
                      _clearMissing("$fOpsiPrefix 2");
                    },
                  ),

                  LabelText(
                    "Terdapat pencahayaan yang cukup",
                    showError: _missingFields.contains("$fOpsiPrefix 3"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi3,
                    onSelected: (v) {
                      setState(() => opsi3 = v);
                      _clearMissing("$fOpsiPrefix 3");
                    },
                  ),

                  LabelText(
                    "Terdapat ventilasi / pendingin ruangan",
                    showError: _missingFields.contains("$fOpsiPrefix 4"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi4,
                    onSelected: (v) {
                      setState(() => opsi4 = v);
                      _clearMissing("$fOpsiPrefix 4");
                    },
                  ),

                  LabelText(
                    "Penyimpangan dan Penumpukan barang / dokumen tertata dengan rapih",
                    showError: _missingFields.contains("$fOpsiPrefix 5"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi5,
                    onSelected: (v) {
                      setState(() => opsi5 = v);
                      _clearMissing("$fOpsiPrefix 5");
                    },
                  ),

                  LabelText(
                    "Housekeeping dilakukan di daerah halaman dan belakang",
                    showError: _missingFields.contains("$fOpsiPrefix 6"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi6,
                    onSelected: (v) {
                      setState(() => opsi6 = v);
                      _clearMissing("$fOpsiPrefix 6");
                    },
                  ),

                  LabelText(
                    "Terdapat area Daerah Jalan / Tempat Parkir yang telah dilengkapi dengan sign",
                    showError: _missingFields.contains("$fOpsiPrefix 7"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi7,
                    onSelected: (v) {
                      setState(() => opsi7 = v);
                      _clearMissing("$fOpsiPrefix 7");
                    },
                  ),

                  LabelText(
                    "Terdapat tempat sampah - mencukupi / dikosongkan secara berkala",
                    showError: _missingFields.contains("$fOpsiPrefix 8"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi8,
                    onSelected: (v) {
                      setState(() => opsi8 = v);
                      _clearMissing("$fOpsiPrefix 8");
                    },
                  ),

                  LabelText(
                    "Terdapat instalasi listrik dan dilakukan pemeriksaan secara rutin",
                    showError: _missingFields.contains("$fOpsiPrefix 9"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi9,
                    onSelected: (v) {
                      setState(() => opsi9 = v);
                      _clearMissing("$fOpsiPrefix 9");
                    },
                  ),

                  LabelText(
                    "Tangga, jalan tangga, pegangan tangga & pengaman sisi",
                    showError: _missingFields.contains("$fOpsiPrefix 10"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi10,
                    onSelected: (v) {
                      setState(() => opsi10 = v);
                      _clearMissing("$fOpsiPrefix 10");
                    },
                  ),

                  LabelText(
                    "Platform dan jalan diatas ketinggian",
                    showError: _missingFields.contains("$fOpsiPrefix 11"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi11,
                    onSelected: (v) {
                      setState(() => opsi11 = v);
                      _clearMissing("$fOpsiPrefix 11");
                    },
                  ),

                  LabelText(
                    "Terdapat Peralatan Pertolongan Pertama (P3K)",
                    showError: _missingFields.contains("$fOpsiPrefix 12"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi12,
                    onSelected: (v) {
                      setState(() => opsi12 = v);
                      _clearMissing("$fOpsiPrefix 12");
                    },
                  ),

                  LabelText(
                    "Penyimpanan Silinder Gas tidak dalam kondisi rusak",
                    showError: _missingFields.contains("$fOpsiPrefix 13"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi13,
                    onSelected: (v) {
                      setState(() => opsi13 = v);
                      _clearMissing("$fOpsiPrefix 13");
                    },
                  ),

                  LabelText(
                    "Tidak terdapat penyimpanan cairan mudah terbakar ",
                    showError: _missingFields.contains("$fOpsiPrefix 14"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi14,
                    onSelected: (v) {
                      setState(() => opsi14 = v);
                      _clearMissing("$fOpsiPrefix 14");
                    },
                  ),

                  LabelText(
                    "Furnitur Kantor & Ergonomi dalam kondisi baik",
                    showError: _missingFields.contains("$fOpsiPrefix 15"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi15,
                    onSelected: (v) {
                      setState(() => opsi15 = v);
                      _clearMissing("$fOpsiPrefix 15");
                    },
                  ),

                  LabelText(
                    "Terdapat tempat penyimpanan & pengendalian bahan kimia berbahaya",
                    showError: _missingFields.contains("$fOpsiPrefix 16"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi16,
                    onSelected: (v) {
                      setState(() => opsi16 = v);
                      _clearMissing("$fOpsiPrefix 16");
                    },
                  ),

                  LabelText(
                    "Tidak terdapat penyimpanan kayu & bahan mudah terbakar lainnya",
                    showError: _missingFields.contains("$fOpsiPrefix 17"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi17,
                    onSelected: (v) {
                      setState(() => opsi17 = v);
                      _clearMissing("$fOpsiPrefix 17");
                    },
                  ),

                  LabelText(
                    "Rambu-rambu & kode warna telah dipasang",
                    showError: _missingFields.contains("$fOpsiPrefix 18"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi18,
                    onSelected: (v) {
                      setState(() => opsi18 = v);
                      _clearMissing("$fOpsiPrefix 18");
                    },
                  ),

                  LabelText(
                    "Alat Pelindung Diri digunakan pada saat diarea yang terdapat sign wajib APD",
                    showError: _missingFields.contains("$fOpsiPrefix 19"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi19,
                    onSelected: (v) {
                      setState(() => opsi19 = v);
                      _clearMissing("$fOpsiPrefix 19");
                    },
                  ),

                  LabelText(
                    "Perlindungan Kebakaran - APAR, Hidran & Selang tersedia dan di inspeksi",
                    showError: _missingFields.contains("$fOpsiPrefix 20"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi20,
                    onSelected: (v) {
                      setState(() => opsi20 = v);
                      _clearMissing("$fOpsiPrefix 20");
                    },
                  ),

                  LabelText(
                    "Tempat Berkumpul Darurat & Sistem Alarm Kebakaran tersedia",
                    showError: _missingFields.contains("$fOpsiPrefix 21"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi21,
                    onSelected: (v) {
                      setState(() => opsi21 = v);
                      _clearMissing("$fOpsiPrefix 21");
                    },
                  ),

                  LabelText(
                    "Papan pengumuman K3 & LH tersedia dan di update Safety Officer",
                    showError: _missingFields.contains("$fOpsiPrefix 22"),
                  ),
                  SizedBox(height: 2),
                  OpsiRow3(
                    selected: opsi22,
                    onSelected: (v) {
                      setState(() => opsi22 = v);
                      _clearMissing("$fOpsiPrefix 22");
                    },
                  ),

                  LabelText(fFoto1, showError: _missingFields.contains(fFoto1)),
                  UploadBox(
                    text: foto1 == null ? "Pilih Foto" : foto1!.name,
                    icon: Icons.photo,
                    onTap: () => pickFoto(1),
                  ),

                  LabelText(fFoto2, showError: _missingFields.contains(fFoto2)),
                  UploadBox(
                    text: foto2 == null ? "Pilih Foto" : foto2!.name,
                    icon: Icons.photo,
                    onTap: () => pickFoto(2),
                  ),

                  LabelText(fFoto3, showError: _missingFields.contains(fFoto3)),
                  UploadBox(
                    text: foto3 == null ? "Pilih Foto" : foto3!.name,
                    icon: Icons.photo,
                    onTap: () => pickFoto(3),
                  ),

                  LabelText(fFoto4, showError: _missingFields.contains(fFoto4)),
                  UploadBox(
                    text: foto4 == null ? "Pilih Foto" : foto4!.name,
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
                    onSelected: (v) {
                      setState(() => status_inspeksi = v);
                      _clearMissing(fStatusInspeksi);
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
                        onPressed: _isSubmitting ? null : submitInspeksiKantor,
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
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = await img.readAsBytes();
      }

      setState(() {
        if (index == 1) {
          foto1 = img;
          foto1Bytes = bytes;
          _clearMissing(fFoto1);
        }

        if (index == 2) {
          foto2 = img;
          foto2Bytes = bytes;
          _clearMissing(fFoto2);
        }

        if (index == 3) {
          foto3 = img;
          foto3Bytes = bytes;
          _clearMissing(fFoto3);
        }

        if (index == 4) {
          foto4 = img;
          foto4Bytes = bytes;
          _clearMissing(fFoto4);
        }
      });
    }
  }

  void submitInspeksiKantor() async {
    if (_isSubmitting) return;

    final missing = _getMissingFields();

    setState(() {
      _missingFields = missing;
    });

    if (missing.isNotEmpty) {
      await ValidationErrorDialog.show(
        context: context,
        missingFields: missing,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _submitProgressText.value = "Mengirim data Inspeksi...";

    SubmitLoadingDialog.show(
      context: context,
      messageNotifier: _submitProgressText,
    );

    final payload = _buildInspeksiKantorPayload();
    final filePaths = _buildInspeksiKantorFilePaths();

    bool ok = false;
    bool savedToPending = false;

    try {
      ok = await RetrySubmitHelper.run(
        maxRetry: _maxAutoRetry,
        retryDelay: _retryDelay,
        onProgress: (attempt, maxRetry) {
          if (!mounted) return;

          _submitProgressText.value = attempt == 1
              ? "Mengirim data Inspeksi..."
              : "Mengirim ulang... percobaan $attempt dari $maxRetry";
        },
        action: () => _submitInspeksiKantorOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveInspeksiKantor(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveInspeksiKantor(
        payload: payload,
        filePaths: filePaths,
      );
      savedToPending = true;
    }

    if (!mounted) return;

    SubmitLoadingDialog.close(context);

    setState(() {
      _isSubmitting = false;
    });

    _submitProgressText.value = "Mengirim data Inspeksi...";

    if (ok) {
      StatusDialog.show(
        context: context,
        type: StatusDialogType.success,
        title: "Berhasil Terkirim",
        message: "Data berhasil dikirim ke server.",
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      );
    } else if (savedToPending) {
      StatusDialog.show(
        context: context,
        type: StatusDialogType.warning,
        title: "Tersimpan di Pending",
        message:
            "Pengiriman gagal setelah beberapa kali percobaan. Data disimpan di Pending Submission.",
        onDone: () {
          Navigator.pop(context);
        },
      );
    } else {
      StatusDialog.show(
        context: context,
        type: StatusDialogType.error,
        title: "Gagal Terkirim",
        message: "Data gagal dikirim.",
        onDone: () {
          Navigator.pop(context);
        },
      );
    }
  }
}
