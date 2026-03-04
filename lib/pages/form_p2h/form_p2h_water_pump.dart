import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/service/p2h/p2h_water_pump_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/date_field.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_department.dart';
import 'package:safety_apps/widgets/image_comprssor.dart';
import 'package:safety_apps/widgets/input/input_field.dart';
import 'package:safety_apps/widgets/label_text.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3_ltna.dart';
import 'package:safety_apps/widgets/upload_box.dart';

class FormP2HWaterPump extends StatefulWidget {
  @override
  _FormP2HWaterPumpPageState createState() => _FormP2HWaterPumpPageState();
}

class _FormP2HWaterPumpPageState extends State<FormP2HWaterPump> {
  TextEditingController nama = TextEditingController();
  TextEditingController jabatan = TextEditingController();
  TextEditingController perusahaan = TextEditingController();
  TextEditingController hm_unit = TextEditingController();
  TextEditingController tanggal = TextEditingController();

  String? department;
  String? shift_kerja;
  String? noLambungUnit;
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

  bool _isSubmitting = false;

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
    if (jabatan.text.trim().isEmpty) missing.add(fJabatan);
    if (perusahaan.text.trim().isEmpty) missing.add(fPerusahaan);
    if (hm_unit.text.trim().isEmpty) missing.add(fHM);
    if (department == null) missing.add(fDepartment);
    if (noLambungUnit == null) missing.add(fNoLambungUnit);
    if (UnitAman == null) missing.add(fUnitAman);
    if (tanggal.text.isEmpty) missing.add(fTanggal);
    if (shift_kerja == null) missing.add(fShiftKerja);

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
      if (jabatan.text.trim().isNotEmpty) {
        _clearMissing(fJabatan);
      }
      if (perusahaan.text.trim().isNotEmpty) {
        _clearMissing(fPerusahaan);
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

                  LabelText(
                    fJabatan,
                    showError: _missingFields.contains(fJabatan),
                  ),
                  InputField(
                    controller: jabatan,
                    hint: "Masukkan jabatan",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fJabatan);
                      }
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
                  InputField(
                    controller: perusahaan,
                    hint: "Masukkan nama perusahaaan",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fPerusahaan);
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
                    options: ["WP MF385-MUL 1004", "WP CF32-MUL 1011"],
                    onChanged: (v) {
                      setState(() => noLambungUnit = v);
                      _clearMissing(fNoLambungUnit);
                    },
                  ),

                  LabelText(
                    fShiftKerja,
                    showError: _missingFields.contains(fNama),
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
                        : selectedDokumen
                              .map((f) => f.path.split("/").last)
                              .join(", "),
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
                                colors: [Color(0xffFF5F6D), Color(0xffFF7A45)],
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
      _clearMissing(fTanggal);
    });
  }

  void submitP2HWaterPump() async {
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
      ok = await P2HWaterPumpService.submitP2HWaterPump(
        nama: nama.text,
        jabatan: jabatan.text,
        department: department ?? "",
        perusahaan: perusahaan.text,
        tanggal: tanggal.text,

        hmUnit: hm_unit.text,
        noLambungUnit: noLambungUnit ?? "",
        shiftKerja: shift_kerja ?? "",

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

        alatKeselamatanAir1: alatKeselamatanAir1 ?? "",
        alatKeselamatanAir2: alatKeselamatanAir2 ?? "",
        alatKeselamatanAir3: alatKeselamatanAir3 ?? "",
        alatKeselamatanAir4: alatKeselamatanAir4 ?? "",

        unitAman: UnitAman ?? "",

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
