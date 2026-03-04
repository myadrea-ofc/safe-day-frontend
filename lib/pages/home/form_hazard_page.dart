import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/dropdown/dropdown_jabatan.dart';
import 'package:safety_apps/widgets/dropdown/dropdwon_temuan.dart';
import '../../service/hazard_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/opsi/opsi_row.dart';
import '../../widgets/upload_box.dart';
import '../../widgets/dropdown/dropdown_department.dart';
import '../../widgets/dropdown/dropdown_perusahaan.dart';

class FormHazardPage extends StatefulWidget {
  @override
  _FormHazardPageState createState() => _FormHazardPageState();
}

class _FormHazardPageState extends State<FormHazardPage> {
  TextEditingController nama = TextEditingController();
  TextEditingController id_karyawan = TextEditingController();
  TextEditingController lokasi_temuan = TextEditingController();
  TextEditingController narasi_temuan = TextEditingController();
  TextEditingController info_perbaikan = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController waktu = TextEditingController();

  String? department;
  String? jenis_temuan;
  String? jabatan;
  String? status_sesuai;
  String? perusahaan;

  File? foto1;
  File? foto2;
  File? foto3;

  bool _isSubmitting = false;

  static const fNamaPengisi = "Nama Pengisi";
  static const fIdKaryawan = "ID Karyawan";
  static const fPerusahaan = "Perusahaan";
  static const fJabatan = "Jabatan";
  static const fDepartment = "Department";
  static const fLokasiTemuan = "Lokasi Temuan";
  static const fTanggalTemuan = "Tanggal Temuan";
  static const fWaktuTemuan = "Waktu Temuan";
  static const fJenisTemuan = "Jenis Temuan";
  static const fNarasiTemuan = "Narasi Temuan";
  static const fInfoPerbaikan = "Info Perbaikan";
  static const fStatusSesuai = "Status Temuan";
  static const fFoto1 = "Dokumentasi 1";
  static const fFoto2 = "Dokumentasi 2";
  static const fFoto3 = "Dokumentasi 3";

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNamaPengisi);
    if (id_karyawan.text.trim().isEmpty) missing.add(fIdKaryawan);
    if (perusahaan == null || perusahaan!.isEmpty) missing.add(fPerusahaan);
    if (jabatan == null || jabatan!.isEmpty) missing.add(fJabatan);
    if (department == null || department!.isEmpty) missing.add(fDepartment);
    if (lokasi_temuan.text.trim().isEmpty) missing.add(fLokasiTemuan);
    if (tanggal.text.trim().isEmpty) missing.add(fTanggalTemuan);
    if (waktu.text.trim().isEmpty) missing.add(fWaktuTemuan);
    if (jenis_temuan == null || jenis_temuan!.isEmpty)
      missing.add(fJenisTemuan);
    if (narasi_temuan.text.trim().isEmpty) missing.add(fNarasiTemuan);
    if (info_perbaikan.text.trim().isEmpty) missing.add(fInfoPerbaikan);
    if (status_sesuai == null) missing.add(fStatusSesuai);
    if (foto1 == null) missing.add(fFoto1);
    if (foto2 == null) missing.add(fFoto2);
    if (foto3 == null) missing.add(fFoto3);

    return missing;
  }

  @override
  void initState() {
    super.initState();

    nama.text = AuthSession.name ?? "";
    id_karyawan.text = AuthSession.employeeId ?? "";

    nama.addListener(() {
      if (nama.text.trim().isNotEmpty) {
        _clearMissing(fNamaPengisi);
      }
    });

    id_karyawan.addListener(() {
      if (id_karyawan.text.trim().isNotEmpty) {
        _clearMissing(fIdKaryawan);
      }
    });

    lokasi_temuan.addListener(() {
      if (lokasi_temuan.text.trim().isNotEmpty) {
        _clearMissing(fLokasiTemuan);
      }
    });

    narasi_temuan.addListener(() {
      if (narasi_temuan.text.trim().isNotEmpty) {
        _clearMissing(fNarasiTemuan);
      }
    });

    info_perbaikan.addListener(() {
      if (info_perbaikan.text.trim().isNotEmpty) {
        _clearMissing(fInfoPerbaikan);
      }
    });
  }

  List<String> _missingFields = [];

  void _clearMissing(String field) {
    setState(() {
      _missingFields.remove(field);
    });
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
            "Form Hazard",
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
            // ===== HEADER CARD =====
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
                      "Hazard Report Form",
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
                    fNamaPengisi,
                    showError: _missingFields.contains(fNamaPengisi),
                  ),
                  InputField(
                    controller: nama,
                    hint: "Masukkan nama",
                    onChanged: null,
                    readOnly: true,
                  ),

                  LabelText(
                    fIdKaryawan,
                    showError: _missingFields.contains(fIdKaryawan),
                  ),
                  InputField(
                    controller: id_karyawan,
                    hint: "Masukkan ID",
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

                  const SizedBox(height: 15),

                  LabelText(
                    fLokasiTemuan,
                    showError: _missingFields.contains(fLokasiTemuan),
                  ),
                  InputField(
                    controller: lokasi_temuan,
                    hint: "Lokasi temuan",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fLokasiTemuan);
                      }
                    },
                  ),

                  LabelText(
                    fTanggalTemuan,
                    showError: _missingFields.contains(fTanggalTemuan),
                  ),
                  DateField(
                    controller: tanggal,
                    onTap: pilihTanggal,
                    icon: Icons.calendar_today,
                  ),

                  LabelText(
                    fWaktuTemuan,
                    showError: _missingFields.contains(fWaktuTemuan),
                  ),
                  DateField(
                    controller: waktu,
                    onTap: pilihWaktu,
                    icon: Icons.access_time,
                  ),

                  LabelText(
                    fJenisTemuan,
                    showError: _missingFields.contains(fJenisTemuan),
                  ),
                  DropdownTemuan(
                    value: jenis_temuan,
                    onChanged: (v) {
                      setState(() => jenis_temuan = v);
                      if (v != null) _clearMissing(fPerusahaan);
                    },
                  ),

                  LabelText(
                    fNarasiTemuan,
                    showError: _missingFields.contains(fNarasiTemuan),
                  ),
                  InputField(
                    controller: narasi_temuan,
                    hint: "Tuliskan narasi",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fNarasiTemuan);
                      }
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

                  LabelText(
                    fInfoPerbaikan,
                    showError: _missingFields.contains(fInfoPerbaikan),
                  ),
                  InputField(
                    controller: info_perbaikan,
                    hint: "Tuliskan narasi",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fInfoPerbaikan);
                      }
                    },
                  ),

                  LabelText(
                    fStatusSesuai,
                    showError: _missingFields.contains(fStatusSesuai),
                  ),
                  OpsiRow(
                    selected: status_sesuai,
                    onSelected: (v) {
                      setState(() => status_sesuai = v);
                      _clearMissing(fStatusSesuai);
                    },
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
                        onPressed: _isSubmitting ? null : submitHazard,
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
                                "Kirim Report Hazard",
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
      tanggal.text = DateFormat("yyyy-MM-dd").format(pick);
      _clearMissing(fTanggalTemuan);
      setState(() {});
    }
  }

  void pilihWaktu() async {
    TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      waktu.text =
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      _clearMissing(fWaktuTemuan);
      setState(() {});
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

  void submitHazard() async {
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
                Text("Mengirim data Hazard..."),
              ],
            ),
          ),
        );
      },
    );

    bool ok = false;

    try {
      ok = await HazardService.submitHazard(
        nama: nama.text,
        idKaryawan: id_karyawan.text,
        perusahaan: perusahaan ?? "",
        jabatan: jabatan ?? "",
        department: department ?? "",
        lokasiTemuan: lokasi_temuan.text,
        tanggal: tanggal.text,
        waktu: waktu.text,
        jenisTemuan: jenis_temuan ?? "",
        narasiTemuan: narasi_temuan.text,
        infoPerbaikan: info_perbaikan.text,
        statusSesuai: status_sesuai ?? "",
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
                  ? "Data Hazard berhasil dikirim"
                  : "Data Hazard Belum Lengkap",
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
