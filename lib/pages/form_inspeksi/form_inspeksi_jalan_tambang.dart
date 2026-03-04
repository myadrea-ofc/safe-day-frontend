import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/session/auth_session.dart';

import 'package:safety_apps/widgets/dropdown/dropdown_yesnona.dart';
import 'package:safety_apps/widgets/opsi/opsi_row.dart';
import 'package:safety_apps/widgets/opsi/opsi_row3.dart';
import '../../service/inspeksi/inspeksi_jalan_tambang_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/upload_box.dart';
import '../../widgets/dropdown/dropdown_department.dart';
import '../../widgets/dropdown/dropdown_perusahaan.dart';

class FormInspeksiJalanTambang extends StatefulWidget {
  @override
  _FormInspeksiJalanTambangPageState createState() =>
      _FormInspeksiJalanTambangPageState();
}

class _FormInspeksiJalanTambangPageState
    extends State<FormInspeksiJalanTambang> {
  TextEditingController nama = TextEditingController();
  TextEditingController nrp = TextEditingController();
  TextEditingController jumlah_inspektor = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController ket_hasil_temuan = TextEditingController();
  TextEditingController saran_masuk = TextEditingController();

  String? department;
  String? status_inspeksi;
  String? perusahaan;
  String? apar;

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
  static const fApar = "Tersedia APAR di semua unit?";

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

    if (apar == null || apar!.isEmpty) {
      missing.add(fApar);
    }

    if (foto1 == null) missing.add(fFoto1);
    if (foto2 == null) missing.add(fFoto2);
    if (foto3 == null) missing.add(fFoto3);

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

  File? foto1;
  File? foto2;
  File? foto3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeef1f6),

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
            "Form Inspeksi Jalan Tambang",
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
            /// HEADER BOX
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.greenAccent, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.white, size: 45),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Inspeksi Jalan Tambang",
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

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  sectionTitle("Informasi Pengisi"),
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

                  SizedBox(height: 10),

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

                  SizedBox(height: 15),

                  sectionTitle("Checklist Kondisi Lapangan"),

                  checklist(
                    1,
                    "Pengendalian Debu Tambang: Penyiraman terjadwal, jumlah water truck cukup",
                    opsi1,
                    (v) => opsi1 = v,
                  ),

                  checklist(
                    2,
                    "Kondisi Slop / Bench : Ketinggian dan kemiringan standar",
                    opsi2,
                    (v) => opsi2 = v,
                  ),
                  checklist(
                    3,
                    "Penerangan di front dan disposal memadai",
                    opsi3,
                    (v) => opsi3 = v,
                  ),
                  checklist(
                    4,
                    "House keeping / kebersihan tambang",
                    opsi4,
                    (v) => opsi4 = v,
                  ),
                  checklist(
                    5,
                    "Semua Equipment bersih & lampu berfungsi",
                    opsi5,
                    (v) => opsi5 = v,
                  ),
                  checklist(
                    6,
                    "Semua Operator & Driver melaksanakan P2H",
                    opsi6,
                    (v) => opsi6 = v,
                  ),
                  checklist(
                    7,
                    "Rambu-rambu lalu lintas memadai",
                    opsi7,
                    (v) => opsi7 = v,
                  ),
                  checklist(
                    8,
                    "Karyawan memakai APD sesuai standar",
                    opsi8,
                    (v) => opsi8 = v,
                  ),
                  checklist(
                    9,
                    "Ada rambu petunjuk arah ke PIT",
                    opsi9,
                    (v) => opsi9 = v,
                  ),
                  checklist(
                    10,
                    "Setiap kendaraan dilengkapi P3K",
                    opsi10,
                    (v) => opsi10 = v,
                  ),
                  checklist(
                    11,
                    "Kendaraan rendah dilengkapi buggy whip",
                    opsi11,
                    (v) => opsi11 = v,
                  ),
                  checklist(
                    12,
                    "Klakson digunakan dengan disiplin",
                    opsi12,
                    (v) => opsi12 = v,
                  ),
                  checklist(
                    13,
                    "Jalan angkut rata dan bebas batuan",
                    opsi13,
                    (v) => opsi13 = v,
                  ),
                  checklist(
                    14,
                    "Lebar jalan angkut sesuai standar",
                    opsi14,
                    (v) => opsi14 = v,
                  ),
                  checklist(
                    15,
                    "Jalan angkut ada bundwall & drainase",
                    opsi15,
                    (v) => opsi15 = v,
                  ),
                  checklist(
                    16,
                    "Tikungan buta ada cermin cembung",
                    opsi16,
                    (v) => opsi16 = v,
                  ),

                  LabelText(
                    "Seat Belt digunakan oleh semua Driver/Operator",
                    showError: _missingFields.contains("$fOpsiPrefix 17"),
                  ),
                  DropdownYesnona(
                    value: opsi17,
                    onChanged: (v) {
                      setState(() => opsi17 = v);
                      _clearMissing("$fOpsiPrefix 17");
                    },
                  ),

                  checklist(
                    18,
                    "Pekerja dewatering memakai pelampung",
                    opsi18,
                    (v) => opsi18 = v,
                  ),
                  checklist(
                    19,
                    "Pompa/tower lamp ada pengaman",
                    opsi19,
                    (v) => opsi19 = v,
                  ),
                  checklist(
                    20,
                    "Sling dan alat angkat lengkap KIP",
                    opsi20,
                    (v) => opsi20 = v,
                  ),
                  checklist(
                    21,
                    "Semua unit punya lampu rotary",
                    opsi21,
                    (v) => opsi21 = v,
                  ),
                  checklist(
                    22,
                    "Kondisi Slop aman & bebas batu lepas",
                    opsi22,
                    (v) => opsi22 = v,
                  ),

                  SizedBox(height: 15),

                  sectionTitle("Upload Foto Temuan"),

                  uploadBox("Temuan 1", foto1, fFoto1, () => pickFoto(1)),
                  uploadBox("Temuan 2", foto2, fFoto2, () => pickFoto(2)),
                  uploadBox("Temuan 3", foto3, fFoto3, () => pickFoto(3)),

                  SizedBox(height: 20),

                  sectionTitle("Analisa & Tindak Lanjut"),

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

                  LabelText(fApar, showError: _missingFields.contains(fApar)),
                  DropdownYesnona(
                    value: apar,
                    onChanged: (v) {
                      setState(() => apar = v);
                      _clearMissing(fApar);
                    },
                  ),

                  SizedBox(height: 35),

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
                        onPressed: _isSubmitting
                            ? null
                            : submitInspeksiJalanTambang,
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

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget checklist(
    int index,
    String title,
    String? selected,
    Function(String?) onSelect,
  ) {
    final fieldKey = "$fOpsiPrefix $index";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelText(title, showError: _missingFields.contains(fieldKey)),
        const SizedBox(height: 2),
        OpsiRow3(
          selected: selected,
          onSelected: (v) {
            setState(() => onSelect(v));
            _clearMissing(fieldKey);
          },
        ),
      ],
    );
  }

  Widget uploadBox(
    String title,
    File? foto,
    String fieldKey,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelText(title, showError: _missingFields.contains(fieldKey)),
        UploadBox(
          text: foto == null ? "Pilih Foto" : foto.path.split("/").last,
          icon: Icons.photo,
          onTap: onTap,
        ),
        const SizedBox(height: 5),
      ],
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
      });
    }
  }

  void submitInspeksiJalanTambang() async {
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
      ok = await InspeksiJalanTambangService.submitInspeksiJalanTambang(
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

        ketHasil: ket_hasil_temuan.text,
        saranMasuk: saran_masuk.text,
        statusInspeksi: status_inspeksi ?? "",
        apar: apar ?? "",

        foto1Path: foto1?.path,
        foto2Path: foto2?.path,
        foto3Path: foto3?.path,
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
