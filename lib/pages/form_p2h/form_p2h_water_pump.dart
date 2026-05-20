import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/p2h/p2h_water_pump_service.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
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

class FormP2HWaterPump extends StatefulWidget {
  @override
  _FormP2HWaterPumpPageState createState() => _FormP2HWaterPumpPageState();
}

class _FormP2HWaterPumpPageState extends State<FormP2HWaterPump> {
  TextEditingController nama = TextEditingController();
  TextEditingController hm_unit = TextEditingController();
  TextEditingController tanggal = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    hm_unit.dispose();
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

  String? shift_kerja;
  String? UnitAman;

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

  String? alatKeselamatanAir1;
  String? alatKeselamatanAir2;
  String? alatKeselamatanAir3;
  String? alatKeselamatanAir4;

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
  static const fJabatan = "Jabatan";
  static const fDepartment = "Department";
  static const fPerusahaan = "Perusahaan";
  static const fNoLambungUnit = "No Lambung Unit";
  static const fTanggal = "Tanggal";
  static const fHM = "Hour Meter Unit";
  static const fShiftKerja = "Shift Kerja";
  static const fUnitAman = "Apakah unit telah aman dioperasikan";
  static const fOpsiPrefix = "Item P2H";
  static const fDokumen = "Dokumen / Foto";
  static const fAlatKeselamatanPrefix = "Standar Keselamatan";

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
  };

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNama);
    if (hm_unit.text.trim().isEmpty) missing.add(fHM);
    if (UnitAman == null) missing.add(fUnitAman);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
    if (shift_kerja == null) missing.add(fShiftKerja);
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

    if (selectedDokumen.isEmpty) missing.add(fDokumen);

    final alatkeselamatanMap = {
      1: alatKeselamatanAir1,
      2: alatKeselamatanAir2,
      3: alatKeselamatanAir3,
      4: alatKeselamatanAir4,
    };

    alatkeselamatanMap.forEach((i, v) {
      if (v == null || v.isEmpty) {
        missing.add("$fAlatKeselamatanPrefix $i");
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
      'hmUnit': hm_unit.text,
      'shiftKerja': shift_kerja ?? "",

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

      'alatKeselamatanAir1': alatKeselamatanAir1 ?? "",
      'alatKeselamatanAir2': alatKeselamatanAir2 ?? "",
      'alatKeselamatanAir3': alatKeselamatanAir3 ?? "",
      'alatKeselamatanAir4': alatKeselamatanAir4 ?? "",

      'unitAman': UnitAman ?? "",

      'filePaths': filePaths,
    };
  }

  Future<bool> _submitOnce(Map<String, dynamic> payload) async {
    return await P2HWaterPumpService.submitP2HWaterPump(
      nama: (payload['nama'] ?? '').toString().trim(),
      jabatan: (payload['jabatan'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),

      hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
      shiftKerja: (payload['shiftKerja'] ?? '').toString().trim(),

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

      alatKeselamatanAir1: (payload['alatKeselamatanAir1'] ?? '')
          .toString()
          .trim(),
      alatKeselamatanAir2: (payload['alatKeselamatanAir2'] ?? '')
          .toString()
          .trim(),
      alatKeselamatanAir3: (payload['alatKeselamatanAir3'] ?? '')
          .toString()
          .trim(),
      alatKeselamatanAir4: (payload['alatKeselamatanAir4'] ?? '')
          .toString()
          .trim(),

      unitAman: (payload['unitAman'] ?? '').toString().trim(),
      filePaths: kIsWeb
          ? []
          : List<String>.from(payload['filePaths'] ?? const []),
      fileBytesList: kIsWeb ? selectedDokumenBytes : [],
      fileNames: kIsWeb ? selectedDokumenNames : [],
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT P2H WATER PUMP TIMEOUT");
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
            "Form P2H Water Pump",
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
                      "Form P2H Water Pump",
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

                  SearchableMasterDropdown(
                    label: fNoLambungUnit,
                    hint: "Pilih No Lambung Unit",
                    endpoint: "master/no-lambung-unit?unit_id=12",
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

                  LabelText("Item Pemerikasaan Water Pump"),

                  LabelText(
                    "Level Oli Mesin",
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
                    "Temperatur Oli",
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
                    "Pipa Pengisap Air (Inlet)",
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
                    "Valve On / Off",
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
                    "Filter Udara",
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
                    "Pipa Keluaran Air (Outlet)",
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
                    "APAR / Fire Extinguisher",
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
                    "Suhu Mesin",
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
                    "Mesin",
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
                    "Putaran Mesin",
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
                    "Flow Meter Mesin",
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
                    "Level Air Aki",
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
                    "Sistem Alarm",
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
                    "Level Air Radiator",
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
                    "Vee Belt",
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
                    "Level BBM",
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
                    "Pipa Pengisian BBM",
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
                    "Penutup Mesin",
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
                    "Alat Pengukur Penggunaan Air",
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
                    "Kondisi Mur / Baut",
                    showError: _missingFields.contains("$fOpsiPrefix 20"),
                  ),
                  OpsiRow3Ltna(
                    selected: opsiitem20,
                    onSelected: (v) {
                      setState(() => opsiitem20 = v);
                      _clearMissing("$fOpsiPrefix 20");
                    },
                  ),

                  LabelText("Alat Keselamatan diatas Air"),

                  LabelText(
                    "Life Jacket",
                    showError: _missingFields.contains(
                      "$fAlatKeselamatanPrefix 1",
                    ),
                  ),
                  OpsiRow3Ltna(
                    selected: alatKeselamatanAir1,
                    onSelected: (v) {
                      setState(() => alatKeselamatanAir1 = v);
                      _clearMissing("$fAlatKeselamatanPrefix 1");
                    },
                  ),

                  LabelText(
                    "Ring Boy",
                    showError: _missingFields.contains(
                      "$fAlatKeselamatanPrefix 2",
                    ),
                  ),
                  OpsiRow3Ltna(
                    selected: alatKeselamatanAir2,
                    onSelected: (v) {
                      setState(() => alatKeselamatanAir2 = v);
                      _clearMissing("$fAlatKeselamatanPrefix 2");
                    },
                  ),

                  LabelText(
                    "Perahu untuk Pekerja",
                    showError: _missingFields.contains(
                      "$fAlatKeselamatanPrefix 3",
                    ),
                  ),
                  OpsiRow3Ltna(
                    selected: alatKeselamatanAir3,
                    onSelected: (v) {
                      setState(() => alatKeselamatanAir3 = v);
                      _clearMissing("$fAlatKeselamatanPrefix 3");
                    },
                  ),

                  LabelText(
                    "Tali Pengikat / Jangkar",
                    showError: _missingFields.contains(
                      "$fAlatKeselamatanPrefix 4",
                    ),
                  ),
                  OpsiRow3Ltna(
                    selected: alatKeselamatanAir4,
                    onSelected: (v) {
                      setState(() => alatKeselamatanAir4 = v);
                      _clearMissing("$fAlatKeselamatanPrefix 4");
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText(
                    "Temuan Hasil Pemeriksaan P2H \n (Maks total size : 5 MB)",
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
                    fUnitAman,
                    showError: _missingFields.contains(fUnitAman),
                  ),
                  OpsiRow(
                    selected: UnitAman,
                    onSelected: (v) {
                      setState(() => UnitAman = v);
                      _clearMissing(fUnitAman);
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
                        onPressed: _isSubmitting ? null : submitP2HWaterPump,
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
                                "Kirim P2H Water Pump",
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

  void submitP2HWaterPump() async {
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
        await PendingFormHelper.saveP2HWaterPump(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveP2HWaterPump(
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
        message: "Data P2H Water Pump berhasil dikirim.",
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
        message: "Data P2H Water Pump gagal dikirim.",
        onDone: () => Navigator.pop(context),
      );
    }
  }
}
