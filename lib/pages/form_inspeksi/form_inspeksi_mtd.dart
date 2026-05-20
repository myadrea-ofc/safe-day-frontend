import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_mtd.service.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_yesnona.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/upload_box.dart';

class FormInspeksiMTD extends StatefulWidget {
  @override
  _FormInspeksiMTDPageState createState() => _FormInspeksiMTDPageState();
}

class _FormInspeksiMTDPageState extends State<FormInspeksiMTD> {
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
  String? opsi23;

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
    23: opsi23,
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (nrp.text.trim().isEmpty) missing.add(fNRP);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
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

  Map<String, dynamic> _buildInspeksiMTDPayload() {
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
      'opsi23': opsi23 ?? "",

      'ketHasil': ket_hasil_temuan.text,
      'saranMasuk': saran_masuk.text,
      'statusInspeksi': status_inspeksi ?? "",
    };
  }

  List<String> _buildInspeksiMTDFilePaths() {
    if (kIsWeb) return [];

    return [
      if (foto1 != null && foto1!.path.isNotEmpty) foto1!.path,
      if (foto2 != null && foto2!.path.isNotEmpty) foto2!.path,
      if (foto3 != null && foto3!.path.isNotEmpty) foto3!.path,
      if (foto4 != null && foto4!.path.isNotEmpty) foto4!.path,
    ];
  }

  Future<bool> _submitInspeksiMTDOnce(Map<String, dynamic> payload) async {
    return await InspeksiMTDService.submitInspeksiMTD(
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
      opsi23: (payload['opsi23'] ?? '').toString().trim(),

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
        debugPrint("SUBMIT INSPEKSI MTD TIMEOUT");
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
            "Form Inspeksi MTD",
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
                      "Inspeksi Mess, Toilet dan Dapur",
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
                    "Saluran Drainase Bersih / Tidak Tersumbat & Didisinfeksi",
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
                    "Lantai bersih dan didisinfeksi",
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
                    "Tidak ada lantai atau sambungan yang pecah",
                    showError: _missingFields.contains("$fOpsiPrefix 3"),
                  ),
                  SizedBox(height: 2),
                  DropdownYesnona(
                    value: opsi3,
                    onChanged: (v) {
                      setState(() {
                        opsi3 = v;
                        _clearMissing("$fOpsiPrefix 3");
                      });
                    },
                  ),

                  LabelText(
                    "Dinding dan atap dalam kondisi bersih",
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
                    "Penerangan memadai",
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
                    "Ventilasi / Ekstraksi memadai",
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
                    "Kebersihan & Housekeeping yang baik",
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
                    "Cermin bersih & tidak pecah",
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
                    "Sabun mencukupi & disediakan disinfektan",
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
                    "Toilet bersih & didisinfeksi",
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
                    "Lembar Pemantauan Daerah Basah Up-to-Date",
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
                    "Tempat tidur / kamar bersih / rapih",
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
                    "Fans / Bagian bergerak lain diamankan",
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
                    "Lemari pendingin / kompor / tempat air minum / peralatan lain bersih & kondisi baik ",
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
                    "Kotak listrik / saklar penggerak / sambungan kabel",
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
                    "Pentanahan disediakan",
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
                    "Instalasi gas terkompresi aman",
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
                    "Tempat penyiapan makanan yang mencukupi disediakan",
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
                    "Area penyiapan makanan bersih / didisifeksi & bebas serangga",
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
                    "Daerah penyimpanan makanan (Bersih / Bebas serangga)",
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
                    "Alat pelindung diri untuk Staf Dapur & pembersih",
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

                  LabelText(
                    "Bak cuci (wastafe) bersih",
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
                    "Pencegahan dan perlindungan kebakaran, seperti alat pemadam api",
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
                        onPressed: _isSubmitting ? null : submitInspeksiMTD,
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
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
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

  void submitInspeksiMTD() async {
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

    final payload = _buildInspeksiMTDPayload();
    final filePaths = _buildInspeksiMTDFilePaths();

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
        action: () => _submitInspeksiMTDOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveInspeksiMTD(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveInspeksiMTD(
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
