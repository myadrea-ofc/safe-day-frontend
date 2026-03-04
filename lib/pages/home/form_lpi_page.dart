import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/session/auth_session.dart';

import 'package:safety_apps/widgets/dropdown/dropdown_jabatan.dart';
import 'package:safety_apps/widgets/dropdown/dropdwon_klasifikasi_insiden.dart';
import '../../service/lpi_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/opsi/opsi_row.dart';
import '../../widgets/upload_box.dart';
import '../../widgets/dropdown/dropdown_department.dart';
import '../../widgets/dropdown/dropdown_perusahaan.dart';

class FormLPIPage extends StatefulWidget {
  @override
  _FormLPIPageState createState() => _FormLPIPageState();
}

class _FormLPIPageState extends State<FormLPIPage> {
  TextEditingController nama = TextEditingController();
  TextEditingController nama_korban = TextEditingController();
  TextEditingController nama_spv = TextEditingController();
  TextEditingController tanggal = TextEditingController();
  TextEditingController waktu = TextEditingController();
  TextEditingController jenis_aset_perusahaan = TextEditingController();
  TextEditingController nama_saksi = TextEditingController();
  TextEditingController jabatan_saksi = TextEditingController();
  TextEditingController kronologi = TextEditingController();

  String? department;
  String? department_spv;
  String? department_saksi;
  String? jabatan_korban;
  String? klasifikasi_insiden;
  String? status_lokasi;
  String? perusahaan;

  File? fileDokumen;
  List<File> fotoList = [];

  bool _isSubmitting = false;

  static const fNamaPengisi = "Nama Pengisi";
  static const fPerusahaan = "Perusahaan";
  static const fDepartment = "Department";
  static const fTanggal = "Tanggal Kejadian";
  static const fWaktu = "Waktu Kejadian";
  static const fNamaKorban = "Nama Korban / Pelaku";
  static const fJabatanKorban = "Jabatan Korban / Pelaku";
  static const fNamaSpv = "Nama Supervisor";
  static const fDepartmentSpv = "Department Supervisor";
  static const fJenisAset = "Jenis Aset Perusahaan";
  static const fNamaSaksi = "Nama Saksi";
  static const fJabatanSaksi = "Jabatan Saksi";
  static const fDepartmentSaksi = "Department Saksi";
  static const fKlasifikasi = "Klasifikasi Insiden";
  static const fKronologi = "Deskripsi Kronologi";
  static const fStatusLokasi = "Status Lokasi Kejadian";
  static const fDokumen = "Dokumen Sketsa Kejadian";
  static const fFoto = "Foto Kejadian";

  List<String> _getMissingFields() {
    List<String> missing = [];
    if (nama.text.trim().isEmpty) missing.add(fNamaPengisi);
    if (perusahaan == null || perusahaan!.isEmpty) missing.add(fPerusahaan);
    if (department == null || department!.isEmpty) missing.add(fDepartment);
    if (tanggal.text.trim().isEmpty) missing.add(fTanggal);
    if (waktu.text.trim().isEmpty) missing.add(fWaktu);
    if (nama_korban.text.trim().isEmpty) missing.add(fNamaKorban);
    if (jabatan_korban == null || jabatan_korban!.isEmpty)
      missing.add(fJabatanKorban);
    if (nama_spv.text.trim().isEmpty) missing.add(fNamaSpv);
    if (department_spv == null || department_spv!.isEmpty)
      missing.add(fDepartmentSpv);
    if (jenis_aset_perusahaan.text.trim().isEmpty) missing.add(fJenisAset);
    if (nama_saksi.text.trim().isEmpty) missing.add(fNamaSaksi);
    if (jabatan_saksi.text.trim().isEmpty) missing.add(fJabatanSaksi);
    if (department_saksi == null || department_saksi!.isEmpty)
      missing.add(fDepartmentSaksi);
    if (klasifikasi_insiden == null || klasifikasi_insiden!.isEmpty)
      missing.add(fKlasifikasi);
    if (kronologi.text.trim().isEmpty) missing.add(fKronologi);
    if (status_lokasi == null || status_lokasi!.isEmpty)
      missing.add(fStatusLokasi);
    if (fileDokumen == null) missing.add(fDokumen);
    if (fotoList.isEmpty) missing.add(fFoto);

    return missing;
  }

  @override
  void initState() {
    super.initState();
    nama.text = AuthSession.name ?? "";

    nama.addListener(() {
      if (nama.text.trim().isNotEmpty) {
        _clearMissing(fNamaPengisi);
      }
    });

    nama_korban.addListener(() {
      if (nama_korban.text.trim().isNotEmpty) {
        _clearMissing(fNamaKorban);
      }
    });

    nama_spv.addListener(() {
      if (nama_spv.text.trim().isNotEmpty) {
        _clearMissing(fNamaSpv);
      }
    });

    jenis_aset_perusahaan.addListener(() {
      if (jenis_aset_perusahaan.text.trim().isNotEmpty) {
        _clearMissing(fJenisAset);
      }
    });

    nama_saksi.addListener(() {
      if (nama_saksi.text.trim().isNotEmpty) {
        _clearMissing(fNamaSaksi);
      }
    });

    jabatan_saksi.addListener(() {
      if (jabatan_saksi.text.trim().isNotEmpty) {
        _clearMissing(fJabatanSaksi);
      }
    });

    kronologi.addListener(() {
      if (kronologi.text.trim().isNotEmpty) {
        _clearMissing(fKronologi);
      }
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeef2f7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Form LPI",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff4fa9ff), Color(0xff1d63ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.report_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Laporan Potensi Insiden (LPI)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 5),
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

                  LabelText(fWaktu, showError: _missingFields.contains(fWaktu)),
                  DateField(
                    controller: waktu,
                    onTap: pilihWaktu,
                    icon: Icons.access_time,
                  ),

                  LabelText(
                    fNamaKorban,
                    showError: _missingFields.contains(fNamaKorban),
                  ),
                  InputField(
                    controller: nama_korban,
                    hint: "Masukkan nama",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fNamaKorban);
                      }
                    },
                  ),

                  LabelText(
                    fJabatanKorban,
                    showError: _missingFields.contains(fJabatanKorban),
                  ),
                  DropdownJabatan(
                    value: jabatan_korban,
                    onChanged: (v) {
                      setState(() => jabatan_korban = v);
                      _clearMissing(fJabatanKorban);
                    },
                  ),

                  LabelText(
                    fNamaSpv,
                    showError: _missingFields.contains(fNamaSpv),
                  ),
                  InputField(
                    controller: nama_spv,
                    hint: "Masukkan nama supervisor",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fNamaSpv);
                      }
                    },
                  ),

                  LabelText(
                    fDepartmentSpv,
                    showError: _missingFields.contains(fDepartmentSpv),
                  ),
                  DropdownDepartment(
                    value: department_spv,
                    onChanged: (v) {
                      setState(() => department_spv = v);
                      _clearMissing(fDepartmentSpv);
                    },
                  ),

                  LabelText(
                    fJenisAset,
                    showError: _missingFields.contains(fJenisAset),
                  ),
                  InputField(
                    controller: jenis_aset_perusahaan,
                    hint: "Masukkan jenis aset",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fJenisAset);
                      }
                    },
                  ),

                  LabelText(
                    fNamaSaksi,
                    showError: _missingFields.contains(fNamaSaksi),
                  ),
                  InputField(
                    controller: nama_saksi,
                    hint: "Masukkan nama saksi",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fNamaSaksi);
                      }
                    },
                  ),

                  LabelText(
                    fJabatanSaksi,
                    showError: _missingFields.contains(fJabatanSaksi),
                  ),
                  InputField(
                    controller: jabatan_saksi,
                    hint: "Masukkan jabatan saksi",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fJabatanSaksi);
                      }
                    },
                  ),

                  LabelText(
                    fDepartmentSaksi,
                    showError: _missingFields.contains(fDepartmentSaksi),
                  ),
                  DropdownDepartment(
                    value: department_saksi,
                    onChanged: (v) {
                      setState(() => department_saksi = v);
                      _clearMissing(fDepartmentSaksi);
                    },
                  ),

                  LabelText(
                    fKlasifikasi,
                    showError: _missingFields.contains(fKlasifikasi),
                  ),
                  DropdownKlasifikasiInsiden(
                    value: klasifikasi_insiden,
                    onChanged: (v) {
                      setState(() => klasifikasi_insiden = v);
                      _clearMissing(fKlasifikasi);
                    },
                  ),

                  LabelText(
                    fKronologi,
                    showError: _missingFields.contains(fKronologi),
                  ),
                  InputField(
                    controller: kronologi,
                    hint: "Tuliskan kronologi kejadian",
                    onChanged: (v) {
                      if (v.trim().isNotEmpty) {
                        _clearMissing(fKronologi);
                      }
                    },
                  ),

                  LabelText(
                    fDokumen,
                    showError: _missingFields.contains(fDokumen),
                  ),
                  UploadBox(
                    text: fileDokumen == null
                        ? "Pilih Dokumen"
                        : fileDokumen!.path.split("/").last,
                    icon: Icons.attach_file_rounded,
                    onTap: pickFile,
                  ),

                  LabelText(fFoto, showError: _missingFields.contains(fFoto)),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...fotoList.asMap().entries.map((e) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                e.value,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    fotoList.removeAt(e.key);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }),

                      if (fotoList.length < 5)
                        GestureDetector(
                          onTap: pickFoto,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_a_photo, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),

                  LabelText(
                    fStatusLokasi,
                    showError: _missingFields.contains(fStatusLokasi),
                  ),
                  OpsiRow(
                    selected: status_lokasi,
                    onSelected: (v) {
                      setState(() => status_lokasi = v);
                      _clearMissing(fStatusLokasi);
                    },
                  ),

                  SizedBox(height: 28),

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
                        onPressed: _isSubmitting ? null : submitLPI,
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
                                "Kirim LPI",
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
        setState(() {});
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
        setState(() {});
      });
    }
  }

  void pickFoto() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images == null) return;

    if (fotoList.length + images.length > 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Maksimal 5 foto")));
      return;
    }

    setState(() {
      fotoList.addAll(images.map((e) => File(e.path)));
    });
    _clearMissing(fTanggal);
    setState(() {});
  }

  void pickFile() async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(
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
      ],
    );

    if (r != null && r.files.single.path != null) {
      setState(() {
        fileDokumen = File(r.files.single.path!);
        _clearMissing(fTanggal);
        setState(() {});
      });
    }
  }

  void submitLPI() async {
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
                Text("Mengirim data LPI..."),
              ],
            ),
          ),
        );
      },
    );

    bool ok = false;

    try {
      ok = await LPIService.submitLPI(
        nama: nama.text,
        perusahaan: perusahaan ?? "",
        department: department ?? "",
        tanggal: tanggal.text,
        waktu: waktu.text,
        namaKorban: nama_korban.text,
        jabatanKorban: jabatan_korban ?? "",
        namaSpv: nama_spv.text,
        departmentSpv: department_spv ?? "",
        jenisAsetPerusahaan: jenis_aset_perusahaan.text,
        namaSaksi: nama_saksi.text,
        jabatanSaksi: jabatan_saksi.text,
        departmentSaksi: department_saksi ?? "",
        klasifikasiInsiden: klasifikasi_insiden ?? "",
        kronologi: kronologi.text,
        statusLokasi: status_lokasi ?? "",
        filePath: fileDokumen?.path,
        fotoPaths: fotoList.map((e) => e.path).toList(),
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
            success ? "Data LPI berhasil dikirim" : "Data LPI Belum Lengkap",
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
