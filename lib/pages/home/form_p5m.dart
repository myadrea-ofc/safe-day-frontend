import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_jabatan.dart';
import '../../service/p5m_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/upload_box.dart';
import '../../widgets/dropdown/dropdown_department.dart';
import '../../widgets/dropdown/dropdown_perusahaan.dart';

class FormP5MPage extends StatefulWidget {
  @override
  _FormP5MPageState createState() => _FormP5MPageState();
}

class _FormP5MPageState extends State<FormP5MPage> {
  TextEditingController nama = TextEditingController();
  TextEditingController nama_pembicara = TextEditingController();
  TextEditingController topik = TextEditingController();
  TextEditingController umpan_balik = TextEditingController();

  String? department;
  String? jabatan;
  String? perusahaan;

  String? kondisi_kesehatan;
  String? status_hari_kerja;
  String? siap_kerja;
  String? jam_tidur;

  File? fileFoto;

  bool _isSubmitting = false;

  static const fNamaPeserta = "Nama Peserta";
  static const fPerusahaan = "Perusahaan";
  static const fDepartment = "Department";
  static const fNamaPembicara = "Nama Pembicara";
  static const fTopik = "Topik P5M";
  static const fJabatan = "Jabatan";
  static const fKondisiKesehatan = "Kondisi Kesehatan";
  static const fJamTidur = "Jam Tidur";
  static const fSiapKerja = "Siap Kerja";
  static const fStatusHariKerja = "Status Hari Kerja";
  static const fUmpanBalik = "Umpan Balik";
  static const fFotoKegiatan = "Foto Kegiatan";

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNamaPeserta);
    if (perusahaan == null || perusahaan!.isEmpty) missing.add(fPerusahaan);
    if (department == null || department!.isEmpty) missing.add(fDepartment);
    if (nama_pembicara.text.trim().isEmpty) missing.add(fNamaPembicara);
    if (topik.text.trim().isEmpty) missing.add(fTopik);
    if (jabatan == null || jabatan!.isEmpty) missing.add(fJabatan);
    if (kondisi_kesehatan == null) missing.add(fKondisiKesehatan);
    if (jam_tidur == null) missing.add(fJamTidur);
    if (siap_kerja == null) missing.add(fSiapKerja);
    if (status_hari_kerja == null) missing.add(fStatusHariKerja);
    if (umpan_balik.text.trim().isEmpty) missing.add(fUmpanBalik);
    if (fileFoto == null) missing.add(fFotoKegiatan);

    return missing;
  }

  List<String> _missingFields = [];

  void _clearMissing(String field) {
    if (_missingFields.contains(field)) {
      setState(() {
        _missingFields.remove(field);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    nama.text = AuthSession.name ?? "";

    nama.addListener(() {
      if (nama.text.trim().isNotEmpty) {
        _clearMissing(fNamaPeserta);
      }
    });

    nama_pembicara.addListener(() {
      if (nama_pembicara.text.trim().isNotEmpty) {
        _clearMissing(fNamaPembicara);
      }
    });

    topik.addListener(() {
      if (topik.text.trim().isNotEmpty) {
        _clearMissing(fTopik);
      }
    });

    umpan_balik.addListener(() {
      if (umpan_balik.text.trim().isNotEmpty) {
        _clearMissing(fUmpanBalik);
      }
    });
  }

  void pickFoto() async {
    final picker = ImagePicker();
    XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() => fileFoto = File(img.path));
      _clearMissing(fFotoKegiatan);
    }
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
            "Form P5M",
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
                      "Form P5M",
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
                  LabelText(
                    fNamaPeserta,
                    showError: _missingFields.contains(fNamaPeserta),
                  ),
                  InputField(
                    controller: nama,
                    hint: "Masukkan nama peserta",
                    onChanged: null,
                    readOnly: true,
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
                    fNamaPembicara,
                    showError: _missingFields.contains(fNamaPembicara),
                  ),
                  InputField(
                    controller: nama_pembicara,
                    hint: "Masukkan nama pembicara",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fNamaPembicara);
                      }
                    },
                  ),
                  LabelText(fTopik, showError: _missingFields.contains(fTopik)),
                  InputField(
                    controller: topik,
                    hint: "Masukkan topik",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fTopik);
                      }
                    },
                  ),
                  LabelText(
                    fJabatan,
                    showError: _missingFields.contains(fJabatan),
                  ),
                  DropdownJabatan(
                    value: jabatan,
                    onChanged: (v) {
                      setState(() => jabatan = v);
                      if (v != null) _clearMissing(fJabatan);
                    },
                  ),
                  LabelText(
                    fKondisiKesehatan,
                    showError: _missingFields.contains(fKondisiKesehatan),
                  ),
                  CheckboxForm(
                    selected: kondisi_kesehatan,
                    options: ["Sehat", "Tidak Sehat"],
                    onChanged: (v) {
                      setState(() => kondisi_kesehatan = v);
                      _clearMissing(fKondisiKesehatan);
                    },
                  ),
                  LabelText(
                    fJamTidur,
                    showError: _missingFields.contains(fJamTidur),
                  ),
                  CheckboxForm(
                    selected: jam_tidur,
                    options: [
                      "1 Jam",
                      "2 Jam",
                      "3 Jam",
                      "4 Jam",
                      "5 Jam",
                      "6 Jam",
                      "Diatas Jam 6",
                    ],
                    onChanged: (v) {
                      setState(() => jam_tidur = v);
                      _clearMissing(fJamTidur);
                    },
                  ),
                  LabelText(
                    fSiapKerja,
                    showError: _missingFields.contains(fSiapKerja),
                  ),
                  CheckboxForm(
                    selected: siap_kerja,
                    options: ["Iya", "Tidak"],
                    onChanged: (v) {
                      setState(() => siap_kerja = v);
                      _clearMissing(fSiapKerja);
                    },
                  ),
                  LabelText(
                    fStatusHariKerja,
                    showError: _missingFields.contains(fStatusHariKerja),
                  ),
                  CheckboxForm(
                    selected: status_hari_kerja,
                    options: ["Aman", "Tidak aman"],
                    onChanged: (v) {
                      setState(() => status_hari_kerja = v);
                      _clearMissing(fStatusHariKerja);
                    },
                  ),

                  LabelText(
                    fUmpanBalik,
                    showError: _missingFields.contains(fUmpanBalik),
                  ),
                  InputField(
                    controller: umpan_balik,
                    hint: "Masukkan umpan balik",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fUmpanBalik);
                      }
                    },
                  ),

                  SizedBox(height: 15),
                  LabelText(
                    fFotoKegiatan,
                    showError: _missingFields.contains(fFotoKegiatan),
                  ),
                  UploadBox(
                    text: fileFoto == null
                        ? "Pilih Foto"
                        : fileFoto!.path.split("/").last,
                    icon: Icons.photo_camera_back_rounded,
                    onTap: pickFoto,
                  ),

                  const SizedBox(height: 25),
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
                        onPressed: _isSubmitting ? null : submitP5M,

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
                                "Kirim Report P5M",
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

  void submitP5M() async {
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
                Text("Mengirim data P5M..."),
              ],
            ),
          ),
        );
      },
    );

    bool ok = false;

    try {
      ok = await P5MService.submitP5M(
        nama: nama.text,
        perusahaan: perusahaan ?? "",
        department: department ?? "",
        namaPembicara: nama_pembicara.text,
        topik: topik.text,
        jabatan: jabatan ?? "",
        kondisiKesehatan: kondisi_kesehatan ?? "",
        jamTidur: jam_tidur ?? "",
        siapKerja: siap_kerja ?? "",
        statusHariKerja: status_hari_kerja ?? "",
        umpanBalik: umpan_balik.text,
        fotoPath: fileFoto?.path,
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
            success ? "Data P5M berhasil dikirim" : "Data P5M Belum Lengkap",
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
