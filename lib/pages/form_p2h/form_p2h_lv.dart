import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/p2h/p2h_lv_service.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_other.dart';
import 'package:safety_apps/widgets/date_field.dart';
import 'package:safety_apps/widgets/image_comprssor.dart';
import 'package:safety_apps/widgets/input/input_field.dart';
import 'package:safety_apps/widgets/label_text.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna2.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/upload_box.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';

class FormP2HLV extends StatefulWidget {
  @override
  _FormP2HLVPageState createState() => _FormP2HLVPageState();
}

class _FormP2HLVPageState extends State<FormP2HLV> {
  TextEditingController nama = TextEditingController();
  TextEditingController lv_sekarang = TextEditingController();
  TextEditingController laporan_temuan = TextEditingController();
  TextEditingController tanggal = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    lv_sekarang.dispose();
    laporan_temuan.dispose();
    tanggal.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedPerusahaan;
  DropdownItemModel? selectedNoLambungUnit;
  DropdownItemModel? selectedJabatan;

  String? departmentManual;
  String? perusahaanManual;
  String? noLambungUnitManual;
  String? jabatanManual;
  String? brandUnit;

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

  String? opsistandardkeselamatan1;
  String? opsistandardkeselamatan2;
  String? opsistandardkeselamatan3;
  String? opsistandardkeselamatan4;
  String? opsistandardkeselamatan5;

  String? opsistandardmasuktambang1;
  String? opsistandardmasuktambang2;
  String? opsistandardmasuktambang3;
  String? opsistandardmasuktambang4;
  String? opsistandardmasuktambang5;
  String? opsistandardmasuktambang6;
  String? opsistandardmasuktambang7;
  String? shift_kerja;

  String? jam_tidur;
  String? status_keadaan1;
  String? status_keadaan2;
  String? status_keadaan3;
  String? status_keadaan4;
  String? status_keadaan5;
  String? status_keadaan6;

  String? status_siap;

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
  static const fLVSekarang = "HM LV anda saat ini";
  static const fBrandUnit = "Brand Unit";
  static const fJabatan = "Jabatan";
  static const fDepartment = "Department";
  static const fPerusahaan = "Perusahaan";
  static const fNoLambungUnit = "No Lambung Unit";
  static const fTanggal = "Tanggal P2H";
  static const fShiftKerja = "Shift Kerja";
  static const fOpsiPrefix = "Item P2H";
  static const fStatusSiap = "Status Kesiapan";
  static const fDokumen = "Dokumen / Foto";
  static const fJamTidur = "Berapa jam tidur Anda sebelum bekerja?";
  static const fLaporanTemuan = "Laporan Temuan";
  static const fKondisiPrefix = "Kondisi Operator";
  static const fStandarPrefix = "Standar Keselamatan";
  static const fMasukTambangPrefix = "Masuk Tambang";

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
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (lv_sekarang.text.trim().isEmpty) missing.add(fLVSekarang);
    if (laporan_temuan.text.trim().isEmpty) missing.add(fLaporanTemuan);
    if (brandUnit == null) missing.add(fBrandUnit);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
    if (shift_kerja == null) missing.add(fShiftKerja);
    if (jam_tidur == null) missing.add(fJamTidur);
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

    if (selectedJabatan == null) {
      missing.add(fJabatan);
    } else if (selectedJabatan!.isOther &&
        (jabatanManual == null || jabatanManual!.trim().isEmpty)) {
      missing.add(fJabatan);
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

    final standarMap = {
      1: opsistandardkeselamatan1,
      2: opsistandardkeselamatan2,
      3: opsistandardkeselamatan3,
      4: opsistandardkeselamatan4,
      5: opsistandardkeselamatan5,
    };

    final masuktambangMap = {
      1: opsistandardmasuktambang1,
      2: opsistandardmasuktambang2,
      3: opsistandardmasuktambang3,
      4: opsistandardmasuktambang4,
      5: opsistandardmasuktambang5,
      6: opsistandardmasuktambang6,
      7: opsistandardmasuktambang7,
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

    masuktambangMap.forEach((i, v) {
      if (v == null || v.isEmpty) {
        missing.add("$fMasukTambangPrefix $i");
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

    nama.addListener(() {
      if (nama.text.trim().isNotEmpty) {
        _clearMissing(fNama);
      }
      if (laporan_temuan.text.trim().isNotEmpty) {
        _clearMissing(fLaporanTemuan);
      }
      if (lv_sekarang.text.trim().isNotEmpty) {
        _clearMissing(fLVSekarang);
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
      'jabatan': selectedJabatan?.isOther == true
          ? (jabatanManual ?? "")
          : (selectedJabatan?.label ?? ""),
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'noLambungUnit': selectedNoLambungUnit?.isOther == true
          ? (noLambungUnitManual ?? "")
          : (selectedNoLambungUnit?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'tanggal': tanggal.text,
      'brandUnit': brandUnit ?? "",
      'lvSekarang': lv_sekarang.text,
      'shiftKerja': shift_kerja ?? "",

      'opsiitem1': opsiitem1 ?? "",
      'opsiitem2': opsiitem2 ?? "",
      'opsiitem3': opsiitem3 ?? "",
      'opsiitem4': opsiitem4 ?? "",
      'opsiitem5': opsiitem5 ?? "",
      'opsiitem6': opsiitem6 ?? "",
      'opsiitem7': opsiitem7 ?? "",
      'opsiitem8': opsiitem8 ?? "",
      'opsiitem9': opsiitem9 ?? "",
      'opsiitem10': opsiitem10 ?? "",
      'opsiitem11': opsiitem11 ?? "",
      'opsiitem12': opsiitem12 ?? "",
      'opsiitem13': opsiitem13 ?? "",
      'opsiitem14': opsiitem14 ?? "",
      'opsiitem15': opsiitem15 ?? "",
      'opsiitem16': opsiitem16 ?? "",
      'opsiitem17': opsiitem17 ?? "",
      'opsiitem18': opsiitem18 ?? "",
      'opsiitem19': opsiitem19 ?? "",

      'opsiStandardKeselamatan1': opsistandardkeselamatan1 ?? "",
      'opsiStandardKeselamatan2': opsistandardkeselamatan2 ?? "",
      'opsiStandardKeselamatan3': opsistandardkeselamatan3 ?? "",
      'opsiStandardKeselamatan4': opsistandardkeselamatan4 ?? "",
      'opsiStandardKeselamatan5': opsistandardkeselamatan5 ?? "",

      'opsiStandardMasukTambang1': opsistandardmasuktambang1 ?? "",
      'opsiStandardMasukTambang2': opsistandardmasuktambang2 ?? "",
      'opsiStandardMasukTambang3': opsistandardmasuktambang3 ?? "",
      'opsiStandardMasukTambang4': opsistandardmasuktambang4 ?? "",
      'opsiStandardMasukTambang5': opsistandardmasuktambang5 ?? "",
      'opsiStandardMasukTambang6': opsistandardmasuktambang6 ?? "",
      'opsiStandardMasukTambang7': opsistandardmasuktambang7 ?? "",

      'laporanTemuan': laporan_temuan.text,
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
    return await P2HLVService.submitP2HLV(
      nama: (payload['nama'] ?? '').toString().trim(),
      jabatan: (payload['jabatan'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),
      brandUnit: (payload['brandUnit'] ?? '').toString().trim(),
      lvSekarang: (payload['lvSekarang'] ?? '').toString().trim(),
      shiftKerja: (payload['shiftKerja'] ?? '').toString().trim(),

      opsiitem1: (payload['opsiitem1'] ?? '').toString().trim(),
      opsiitem2: (payload['opsiitem2'] ?? '').toString().trim(),
      opsiitem3: (payload['opsiitem3'] ?? '').toString().trim(),
      opsiitem4: (payload['opsiitem4'] ?? '').toString().trim(),
      opsiitem5: (payload['opsiitem5'] ?? '').toString().trim(),
      opsiitem6: (payload['opsiitem6'] ?? '').toString().trim(),
      opsiitem7: (payload['opsiitem7'] ?? '').toString().trim(),
      opsiitem8: (payload['opsiitem8'] ?? '').toString().trim(),
      opsiitem9: (payload['opsiitem9'] ?? '').toString().trim(),
      opsiitem10: (payload['opsiitem10'] ?? '').toString().trim(),
      opsiitem11: (payload['opsiitem11'] ?? '').toString().trim(),
      opsiitem12: (payload['opsiitem12'] ?? '').toString().trim(),
      opsiitem13: (payload['opsiitem13'] ?? '').toString().trim(),
      opsiitem14: (payload['opsiitem14'] ?? '').toString().trim(),
      opsiitem15: (payload['opsiitem15'] ?? '').toString().trim(),
      opsiitem16: (payload['opsiitem16'] ?? '').toString().trim(),
      opsiitem17: (payload['opsiitem17'] ?? '').toString().trim(),
      opsiitem18: (payload['opsiitem18'] ?? '').toString().trim(),
      opsiitem19: (payload['opsiitem19'] ?? '').toString().trim(),

      opsiStandardKeselamatan1: (payload['opsiStandardKeselamatan1'] ?? '')
          .toString()
          .trim(),
      opsiStandardKeselamatan2: (payload['opsiStandardKeselamatan2'] ?? '')
          .toString()
          .trim(),
      opsiStandardKeselamatan3: (payload['opsiStandardKeselamatan3'] ?? '')
          .toString()
          .trim(),
      opsiStandardKeselamatan4: (payload['opsiStandardKeselamatan4'] ?? '')
          .toString()
          .trim(),
      opsiStandardKeselamatan5: (payload['opsiStandardKeselamatan5'] ?? '')
          .toString()
          .trim(),

      opsiStandardMasukTambang1: (payload['opsiStandardMasukTambang1'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang2: (payload['opsiStandardMasukTambang2'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang3: (payload['opsiStandardMasukTambang3'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang4: (payload['opsiStandardMasukTambang4'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang5: (payload['opsiStandardMasukTambang5'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang6: (payload['opsiStandardMasukTambang6'] ?? '')
          .toString()
          .trim(),
      opsiStandardMasukTambang7: (payload['opsiStandardMasukTambang7'] ?? '')
          .toString()
          .trim(),

      laporanTemuan: (payload['laporanTemuan'] ?? '').toString().trim(),
      filePaths: kIsWeb
          ? []
          : List<String>.from(payload['filePaths'] ?? const []),
      fileBytesList: kIsWeb ? selectedDokumenBytes : [],
      fileNames: kIsWeb ? selectedDokumenNames : [],
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
        debugPrint("SUBMIT P2H LV TIMEOUT");
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
            "Form P2H LV",
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
                      "Form P2H LV",
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

                  SearchableMasterDropdown(
                    label: fJabatan,
                    hint: "Pilih Jabatan",
                    endpoint: "master/jabatan",
                    selectedValue: selectedJabatan,
                    showError: _missingFields.contains(fJabatan),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedJabatan = selected;
                        jabatanManual = manualValue;
                      });
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
                    fTanggal,
                    showError: _missingFields.contains(fTanggal),
                  ),
                  DateField(
                    controller: tanggal,
                    onTap: pilihTanggal,
                    icon: Icons.calendar_today,
                  ),

                  LabelText(
                    fBrandUnit,
                    showError: _missingFields.contains(fBrandUnit),
                  ),
                  CheckboxOther(
                    selected: brandUnit,
                    options: ["Mitsubishi", "Toyota", "Isuzu", "Nissan"],
                    onChanged: (v) {
                      setState(() => brandUnit = v);
                      _clearMissing(fBrandUnit);
                    },
                  ),

                  SearchableMasterDropdown(
                    label: fNoLambungUnit,
                    hint: "Pilih No Lambung Unit",
                    endpoint: "master/no-lambung-unit?unit_id=16",
                    showError: _missingFields.contains(fNoLambungUnit),
                    selectedValue: selectedNoLambungUnit,
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedNoLambungUnit = selected;
                        noLambungUnitManual = manualValue;
                      });
                      _clearMissing(fNoLambungUnit);
                    },
                  ),

                  LabelText(
                    fLVSekarang,
                    showError: _missingFields.contains(fLVSekarang),
                  ),
                  InputField(
                    controller: lv_sekarang,
                    hint: "Masukkan HM LV",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fLVSekarang);
                      }
                    },
                  ),

                  LabelText(
                    fShiftKerja,
                    showError: _missingFields.contains(fShiftKerja),
                  ),
                  CheckboxForm(
                    selected: shift_kerja,
                    options: ["Shift I", "Shift II"],
                    onChanged: (v) {
                      setState(() => shift_kerja = v);
                      _clearMissing(fShiftKerja);
                    },
                  ),

                  LabelText("Item Pemerikasaan"),

                  LabelText(
                    "Level Oil Engine",
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
                    "Level Air Radiator",
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
                    "Kondisi Aki",
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
                    "Air Wiper dan Kondisi Wiper",
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
                    "Kondisi Ban",
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
                    "Ban Serap",
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
                    "Skrup Ban",
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
                    "Rem Kaki",
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
                    "Rem Tangan",
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
                    "Lampu Kerja (Depan & Belakang)",
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
                    "Lampu Sein (Kiri & Kanan)",
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
                    "Lampu Hazard",
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
                    "Alarm Mundur",
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
                    "Klakson",
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
                    "Keadaan Body Mobil",
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
                    "Kaca Spion",
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
                    "Panel Engine",
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
                    "Kondisi AC",
                    showError: _missingFields.contains("$fOpsiPrefix 19"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem19,
                    onSelected: (v) {
                      setState(() => opsiitem19 = v);
                      _clearMissing("$fOpsiPrefix 19");
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
                    "Jack",
                    showError: _missingFields.contains("$fStandarPrefix 3"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan3,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan3 = v);
                      _clearMissing("$fStandarPrefix 3");
                    },
                  ),

                  LabelText(
                    "Kotak P3K",
                    showError: _missingFields.contains("$fStandarPrefix 4"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan4,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan4 = v);
                      _clearMissing("$fStandarPrefix 4");
                    },
                  ),

                  LabelText(
                    "Seat Belt / Sabuk Pengaman",
                    showError: _missingFields.contains("$fStandarPrefix 5"),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardkeselamatan5,
                    onSelected: (v) {
                      setState(() => opsistandardkeselamatan5 = v);
                      _clearMissing("$fStandarPrefix 5");
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText("Standard Masuk Ke Tambang"),

                  LabelText(
                    "Lampu Atap Kabin",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 1",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang1,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang1 = v);
                      _clearMissing("$fMasukTambangPrefix 1");
                    },
                  ),

                  LabelText(
                    "Lampu Rotari",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 2",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang2,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang2 = v);
                      _clearMissing("$fMasukTambangPrefix 2");
                    },
                  ),

                  LabelText(
                    "Scotlight Reflector",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 3",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang3,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang3 = v);
                      _clearMissing("$fMasukTambangPrefix 3");
                    },
                  ),

                  LabelText(
                    "No Lambung Unit",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 4",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang4,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang4 = v);
                      _clearMissing("$fMasukTambangPrefix 4");
                    },
                  ),

                  LabelText(
                    "Radio Komunikasi",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 5",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang5,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang5 = v);
                      _clearMissing("$fMasukTambangPrefix 5");
                    },
                  ),

                  LabelText(
                    "Buggy Whip 4 Mtr",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 6",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang6,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang6 = v);
                      _clearMissing("$fMasukTambangPrefix 6");
                    },
                  ),

                  LabelText(
                    "4WD",
                    showError: _missingFields.contains(
                      "$fMasukTambangPrefix 7",
                    ),
                  ),
                  OpsiRow3Ltna2(
                    selected: opsistandardmasuktambang7,
                    onSelected: (v) {
                      setState(() => opsistandardmasuktambang7 = v);
                      _clearMissing("$fMasukTambangPrefix 7");
                    },
                  ),

                  LabelText(
                    "Laporan Temuan Hasil P2H",
                    showError: _missingFields.contains(fLaporanTemuan),
                  ),
                  InputField(
                    controller: laporan_temuan,
                    hint: "Masukkan Laporan",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fLaporanTemuan);
                      }
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText(
                    "Sketsa Kejadian \n (Maks total size : 5 MB)",
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
                    "Apakah Anda sudah siap untuk bekerja & telah menggunakan APD serta memiliki KIMPER sesuai unit yang Anda operasikan",
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
                        onPressed: _isSubmitting ? null : submitP2HLV,
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
                                "Kirim P2H LV",
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

  void submitP2HLV() async {
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
        await PendingFormHelper.saveP2HLV(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveP2HLV(payload: payload, filePaths: filePaths);
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
        message: "Data P2H LV berhasil dikirim.",
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
        message: "Data P2H LV gagal dikirim.",
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
