import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/p2h/p2h_dozer_service.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_other.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/date_field.dart';
import 'package:safety_apps/widgets/image_comprssor.dart';
import 'package:safety_apps/widgets/input/input_field.dart';
import 'package:safety_apps/widgets/label_text.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/upload_box.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';

class FormP2HDozer extends StatefulWidget {
  @override
  _FormP2HDozerPageState createState() => _FormP2HDozerPageState();
}

class _FormP2HDozerPageState extends State<FormP2HDozer> {
  TextEditingController nama = TextEditingController();
  TextEditingController nrp = TextEditingController();
  TextEditingController waktu = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController hm_unit = TextEditingController();
  TextEditingController lokasi_kerja = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    nrp.dispose();
    waktu.dispose();
    tanggal.dispose();
    hm_unit.dispose();
    lokasi_kerja.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedPerusahaan;
  DropdownItemModel? selectedJabatan;
  DropdownItemModel? selectedNoLambungUnit;

  String? departmentManual;
  String? perusahaanManual;
  String? noLambungUnitManual;
  String? jabatan;
  String? brand_unit;

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
  String? opsiitem32;
  String? opsiitem33;

  String? status_keadaan1;
  String? status_keadaan2;
  String? status_keadaan3;
  String? status_keadaan4;
  String? status_keadaan5;
  String? status_keadaan6;

  String? status_siap;
  String? kimper_berlaku;
  String? jam_tidur;

  List<XFile> selectedDokumen = [];

  List<Uint8List> selectedDokumenBytes = [];
  List<String> selectedDokumenNames = [];

  bool _isSubmitting = false;

  static const int _maxAutoRetry = 3;
  static const Duration _submitTimeout = Duration(seconds: 15);
  static const Duration _retryDelay = Duration(seconds: 1);

  final ValueNotifier<String> _submitProgressText = ValueNotifier(
    "Mengirim data P2H...",
  );

  static const fNama = "Nama";
  static const fNRP = "NRP";
  static const fJabatan = "Jabatan";
  static const fDepartment = "Department";
  static const fPerusahaan = "Perusahaan";
  static const fNoLambungUnit = "No Lambung Unit";
  static const fTanggal = "Tanggal";
  static const fWaktu = "Waktu P2H";
  static const fHM = "Hour Meter";
  static const fLokasiKerja = "Lokasi Kerja";
  static const fBrandUnit = "Brand Unit";
  static const fKimperBerlaku =
      "Apakah Anda memiliki Kimper yang masih berlaku";
  static const fOpsiPrefix = "Item P2H";
  static const fStatusSiap = "Status Kesiapan";
  static const fDokumen = "Dokumen / Foto";
  static const fJamTidur = "Berapa jam tidur Anda sebelum bekerja?";
  static const fKondisiPrefix = "Kondisi Operator";

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
    32: opsiitem32,
    33: opsiitem33,
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (nrp.text.trim().isEmpty) missing.add(fNRP);
    if (hm_unit.text.trim().isEmpty) missing.add(fHM);
    if (lokasi_kerja.text.trim().isEmpty) missing.add(fLokasiKerja);
    if (jabatan == null) missing.add(fJabatan);
    if (brand_unit == null) missing.add(fBrandUnit);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
    if (waktu.text.isEmpty) missing.add(fWaktu);
    if (jam_tidur == null) missing.add(fJamTidur);
    if (kimper_berlaku == null) missing.add(fKimperBerlaku);
    if (selectedDepartment == null) {
      missing.add(fDepartment);
    } else if (selectedDepartment!.isOther &&
        (departmentManual == null || departmentManual!.trim().isEmpty)) {
      missing.add(fDepartment);
    }

    if (selectedNoLambungUnit == null) {
      missing.add(fNoLambungUnit);
    } else if (selectedNoLambungUnit!.isOther &&
        (noLambungUnitManual == null || noLambungUnitManual!.trim().isEmpty)) {
      missing.add(fNoLambungUnit);
    }

    if (selectedPerusahaan == null) {
      missing.add(fPerusahaan);
    } else if (selectedPerusahaan!.isOther &&
        (perusahaanManual == null || perusahaanManual!.trim().isEmpty)) {
      missing.add(fPerusahaan);
    }

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

  Future<List<File>> _processFilesForSubmit() async {
    if (kIsWeb) return [];

    const maxFileSize = 5 * 1024 * 1024;
    List<File> processedFiles = [];

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

    return processedFiles;
  }

  Map<String, dynamic> _buildPayload({required List<String> filePaths}) {
    return {
      'nama': nama.text,
      'nrp': nrp.text,
      'jabatan': jabatan ?? "",
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'noLambungUnit': selectedNoLambungUnit?.isOther == true
          ? (noLambungUnitManual ?? "")
          : (selectedNoLambungUnit?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'lokasiKerja': lokasi_kerja.text,
      'hmUnit': hm_unit.text,
      'waktu': waktu.text,
      'brandUnit': brand_unit ?? "",
      'tanggal': tanggal.text,

      'opsiItem1': opsiitem1 ?? "",
      'opsiItem2': opsiitem2 ?? "",
      'opsiItem3': opsiitem3 ?? "",
      'opsiItem4': opsiitem4 ?? "",
      'opsiItem5': opsiitem5 ?? "",
      'opsiItem6': opsiitem6 ?? "",
      'opsiItem7': opsiitem7 ?? "",
      'opsiItem8': opsiitem8 ?? "",
      'opsiItem9': opsiitem9 ?? "",
      'opsiItem10': opsiitem10 ?? "",
      'opsiItem11': opsiitem11 ?? "",
      'opsiItem12': opsiitem12 ?? "",
      'opsiItem13': opsiitem13 ?? "",
      'opsiItem14': opsiitem14 ?? "",
      'opsiItem15': opsiitem15 ?? "",
      'opsiItem16': opsiitem16 ?? "",
      'opsiItem17': opsiitem17 ?? "",
      'opsiItem18': opsiitem18 ?? "",
      'opsiItem19': opsiitem19 ?? "",
      'opsiItem20': opsiitem20 ?? "",
      'opsiItem21': opsiitem21 ?? "",
      'opsiItem22': opsiitem22 ?? "",
      'opsiItem23': opsiitem23 ?? "",
      'opsiItem24': opsiitem24 ?? "",
      'opsiItem25': opsiitem25 ?? "",
      'opsiItem26': opsiitem26 ?? "",
      'opsiItem27': opsiitem27 ?? "",
      'opsiItem28': opsiitem28 ?? "",
      'opsiItem29': opsiitem29 ?? "",
      'opsiItem30': opsiitem30 ?? "",
      'opsiItem31': opsiitem31 ?? "",
      'opsiItem32': opsiitem32 ?? "",
      'opsiItem33': opsiitem33 ?? "",

      'kimperBerlaku': kimper_berlaku ?? "",
      'jamTidur': jam_tidur ?? "",

      'statusKeadaan1': status_keadaan1 ?? "",
      'statusKeadaan2': status_keadaan2 ?? "",
      'statusKeadaan3': status_keadaan3 ?? "",
      'statusKeadaan4': status_keadaan4 ?? "",
      'statusKeadaan5': status_keadaan5 ?? "",
      'statusKeadaan6': status_keadaan6 ?? "",

      'statusSiap': status_siap ?? "",

      'filePaths': filePaths,
    };
  }

  Future<bool> _submitOnce(Map<String, dynamic> payload) async {
    return await P2HDozerService.submitP2HDozer(
      nama: (payload['nama'] ?? '').toString().trim(),
      nrp: (payload['nrp'] ?? '').toString().trim(),
      jabatan: (payload['jabatan'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
      hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
      waktu: (payload['waktu'] ?? '').toString().trim(),
      brandUnit: (payload['brandUnit'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),

      opsiItem1: (payload['opsiItem1'] ?? '').toString().trim(),
      opsiItem2: (payload['opsiItem2'] ?? '').toString().trim(),
      opsiItem3: (payload['opsiItem3'] ?? '').toString().trim(),
      opsiItem4: (payload['opsiItem4'] ?? '').toString().trim(),
      opsiItem5: (payload['opsiItem5'] ?? '').toString().trim(),
      opsiItem6: (payload['opsiItem6'] ?? '').toString().trim(),
      opsiItem7: (payload['opsiItem7'] ?? '').toString().trim(),
      opsiItem8: (payload['opsiItem8'] ?? '').toString().trim(),
      opsiItem9: (payload['opsiItem9'] ?? '').toString().trim(),
      opsiItem10: (payload['opsiItem10'] ?? '').toString().trim(),
      opsiItem11: (payload['opsiItem11'] ?? '').toString().trim(),
      opsiItem12: (payload['opsiItem12'] ?? '').toString().trim(),
      opsiItem13: (payload['opsiItem13'] ?? '').toString().trim(),
      opsiItem14: (payload['opsiItem14'] ?? '').toString().trim(),
      opsiItem15: (payload['opsiItem15'] ?? '').toString().trim(),
      opsiItem16: (payload['opsiItem16'] ?? '').toString().trim(),
      opsiItem17: (payload['opsiItem17'] ?? '').toString().trim(),
      opsiItem18: (payload['opsiItem18'] ?? '').toString().trim(),
      opsiItem19: (payload['opsiItem19'] ?? '').toString().trim(),
      opsiItem20: (payload['opsiItem20'] ?? '').toString().trim(),
      opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
      opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
      opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
      opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
      opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
      opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
      opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
      opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
      opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
      opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
      opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
      opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
      opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),

      filePaths: kIsWeb
          ? []
          : List<String>.from(payload['filePaths'] ?? const []),
      fileBytesList: kIsWeb ? selectedDokumenBytes : [],
      fileNames: kIsWeb ? selectedDokumenNames : [],

      kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
      jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

      statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
      statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
      statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
      statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
      statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
      statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

      statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT P2H DOZER TIMEOUT");
        return false;
      },
    );
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
                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
          ),
          title: const Text(
            "Form P2H Dozer",
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
                  colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
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
                      "Form P2H Dozer",
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
                    options: ["Operator Dozer", "Pengawas", "Trainer"],
                    onChanged: (v) {
                      setState(() => jabatan = v);
                      _clearMissing(fJabatan);
                    },
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

                  SearchableMasterDropdown(
                    label: fNoLambungUnit,
                    hint: "Pilih No Lambung Unit",
                    endpoint: "master/no-lambung-unit?unit_id=6",
                    selectedValue: selectedNoLambungUnit,
                    showError: _missingFields.contains(fNoLambungUnit),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedNoLambungUnit = selected;
                        noLambungUnitManual = manualValue;
                      });
                      _clearMissing(fNoLambungUnit);
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
                    fTanggal,
                    showError: _missingFields.contains(fTanggal),
                  ),
                  DateField(
                    controller: tanggal,
                    onTap: pilihTanggal,
                    icon: Icons.calendar_today,
                  ),

                  LabelText(fWaktu, showError: _missingFields.contains(fWaktu)),
                  DateField(
                    controller: waktu,
                    onTap: pilihWaktu,
                    icon: Icons.access_time,
                  ),

                  LabelText(
                    fBrandUnit,
                    showError: _missingFields.contains(fBrandUnit),
                  ),
                  CheckboxOther(
                    selected: brand_unit,
                    options: [
                      "XCMG",
                      "LIUGONG",
                      "SANY",
                      "CATERPILAR",
                      "KOMATSU",
                      "VOLVO",
                      "TONLY",
                      "SANTUI",
                      "LIEBHERR",
                    ],
                    onChanged: (v) {
                      setState(() => brand_unit = v);
                      _clearMissing(fBrandUnit);
                    },
                  ),

                  LabelText("Item Pemerikasaan P2H Unit Dozer"),

                  LabelText(
                    "Level Air Radiator & Kebocoran",
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
                    "Level Air Aki",
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
                    "Oli Mesin",
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
                    "Bahan Bakar",
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
                    "Kondisi Wiper",
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
                    "Kondisi Lampu Rotary, Stop, Depan, Belakang)",
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
                    "Kondisi Lampu Body",
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
                    "Alarm Mundur",
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
                    "Kondisi Kaca Depan, Belakang, Jendela dan Spion",
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
                    "Cermin Pandang Belakang & Sisi",
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
                    "Keadaan Body, Kabin, dan Kursi Operator",
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
                    "Suhu Mesin",
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
                    "Klakson",
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
                    "Uji Rem Fisik",
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
                    "Sistem Hidrolik",
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
                    "Silinder Hidrolik / Hydraulic Cylinder (Truck / Excavator)",
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
                    "Mesin",
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
                    "Crawler Tracks",
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
                    "Crawler Track Link Bolts",
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
                    "Sistem Elektrik",
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
                    "Blade (Dozer / Grader)",
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
                    "Bajak & Gigi / Ripper & Teeth",
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
                    "Pengatur Arah / Directional Control",
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
                    "Tuas Kemudi / Control Levers",
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
                    "Tuas Penggeser Blade, Penggeser Blade, Pemutar Circle, Pengangkat Blade, Ripper, Memiringkan Roda Depan, Centershift",
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
                    "Instrumen Panel",
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
                    "Alat Pemadam Api",
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
                    "Kotak P3K",
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
                    "Tongkat 4 m & Bendera",
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
                    "Sabuk Keselamatan",
                    showError: _missingFields.contains("$fOpsiPrefix 31"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem31,
                    onSelected: (v) {
                      setState(() => opsiitem31 = v);
                      _clearMissing("$fOpsiPrefix 31");
                    },
                  ),

                  LabelText(
                    "Radio Komunikasi",
                    showError: _missingFields.contains("$fOpsiPrefix 32"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem32,
                    onSelected: (v) {
                      setState(() => opsiitem32 = v);
                      _clearMissing("$fOpsiPrefix 32");
                    },
                  ),

                  LabelText(
                    "SIMPER",
                    showError: _missingFields.contains("$fOpsiPrefix 33"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem33,
                    onSelected: (v) {
                      setState(() => opsiitem33 = v);
                      _clearMissing("$fOpsiPrefix 33");
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
                        : selectedDokumen.map((f) => f.name).join(", "),
                    icon: Icons.attach_file_rounded,
                    onTap: pickFile,
                  ),

                  LabelText(
                    "Apakah Anda memiliki Kimper yang masih berlaku",
                    showError: _missingFields.contains(fKimperBerlaku),
                  ),
                  CheckboxForm(
                    selected: kimper_berlaku,
                    options: ["Ya", "Tidak"],
                    onChanged: (v) {
                      setState(() => kimper_berlaku = v);
                      _clearMissing(fKimperBerlaku);
                    },
                  ),

                  LabelText(
                    "Berapa jam tidur Anda sebelum bekerja",
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
                                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                              ),
                        color: _isSubmitting ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : submitP2HDozer,
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
                                "Kirim P2H Dozer",
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
      withData: kIsWeb,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'csv',
        'txt',
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

    if (kIsWeb) {
      final filesWithoutBytes = result.files
          .where((f) => f.bytes == null)
          .toList();

      if (filesWithoutBytes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File gagal dibaca di Web, silakan pilih ulang"),
          ),
        );
        return;
      }

      setState(() {
        selectedDokumen = result.files
            .map((f) => XFile.fromData(f.bytes!, name: f.name))
            .toList();

        selectedDokumenBytes = result.files.map((f) => f.bytes!).toList();
        selectedDokumenNames = result.files.map((f) => f.name).toList();

        _clearMissing(fDokumen);
      });
    } else {
      setState(() {
        selectedDokumen = result.paths
            .where((p) => p != null)
            .map((p) => XFile(p!))
            .toList();

        selectedDokumenBytes = [];
        selectedDokumenNames = result.files.map((f) => f.name).toList();

        _clearMissing(fDokumen);
      });
    }
  }

  void submitP2HDozer() async {
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

    setState(() => _isSubmitting = true);

    _submitProgressText.value = "Memproses file...";

    SubmitLoadingDialog.show(
      context: context,
      messageNotifier: _submitProgressText,
    );

    List<File> processedFiles = [];

    try {
      processedFiles = await _processFilesForSubmit();
    } catch (e) {
      if (!mounted) return;

      SubmitLoadingDialog.close(context);

      setState(() => _isSubmitting = false);

      StatusDialog.show(
        context: context,
        type: StatusDialogType.error,
        title: "Upload Gagal",
        message: e.toString(),
        onDone: () => Navigator.pop(context),
      );
      return;
    }
    final filePaths = kIsWeb
        ? <String>[]
        : processedFiles.map((e) => e.path).toList();

    final payload = _buildPayload(filePaths: filePaths);

    bool ok = false;
    bool savedToPending = false;

    try {
      ok = await RetrySubmitHelper.run(
        maxRetry: _maxAutoRetry,
        retryDelay: _retryDelay,
        onProgress: (attempt, maxRetry) {
          if (!mounted) return;

          _submitProgressText.value = attempt == 1
              ? "Mengirim data P2H..."
              : "Mengirim ulang... percobaan $attempt dari $maxRetry";
        },
        action: () => _submitOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveP2HDozer(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveP2HDozer(
        payload: payload,
        filePaths: filePaths,
      );
      savedToPending = true;
    }

    if (!mounted) return;

    SubmitLoadingDialog.close(context);

    setState(() => _isSubmitting = false);

    _submitProgressText.value = "Mengirim data P2H...";

    if (ok) {
      StatusDialog.show(
        context: context,
        type: StatusDialogType.success,
        title: "Berhasil",
        message: "Data P2H Dozer berhasil dikirim.",
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
        onDone: () => Navigator.pop(context),
      );
    } else {
      StatusDialog.show(
        context: context,
        type: StatusDialogType.error,
        title: "Gagal",
        message: "Data P2H Dozer gagal dikirim.",
        onDone: () => Navigator.pop(context),
      );
    }
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
}
