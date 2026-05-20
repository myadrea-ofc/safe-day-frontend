import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/checkbox/checkbox_form.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';
import '../../service/p5m_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/upload_box.dart';

class FormP5MPage extends StatefulWidget {
  @override
  _FormP5MPageState createState() => _FormP5MPageState();
}

class _FormP5MPageState extends State<FormP5MPage> {
  TextEditingController nama = TextEditingController();
  TextEditingController nama_pembicara = TextEditingController();
  TextEditingController topik = TextEditingController();
  TextEditingController umpan_balik = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    nama_pembicara.dispose();
    topik.dispose();
    umpan_balik.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedPerusahaan;
  DropdownItemModel? selectedJabatan;

  String? departmentManual;
  String? perusahaanManual;
  String? jabatanManual;

  String? kondisi_kesehatan;
  String? status_hari_kerja;
  String? siap_kerja;
  String? jam_tidur;

  XFile? fileFoto;
  Uint8List? fotoBytes;

  bool _isSubmitting = false;

  static const int _maxAutoRetry = 3;
  static const Duration _submitTimeout = Duration(seconds: 15);
  static const Duration _retryDelay = Duration(seconds: 1);

  final ValueNotifier<String> _submitProgressText = ValueNotifier(
    "Mengirim data P5M...",
  );

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
    if (nama_pembicara.text.trim().isEmpty) missing.add(fNamaPembicara);
    if (topik.text.trim().isEmpty) missing.add(fTopik);
    if (kondisi_kesehatan == null) missing.add(fKondisiKesehatan);
    if (jam_tidur == null) missing.add(fJamTidur);
    if (siap_kerja == null) missing.add(fSiapKerja);
    if (status_hari_kerja == null) missing.add(fStatusHariKerja);
    if (umpan_balik.text.trim().isEmpty) missing.add(fUmpanBalik);
    if (fileFoto == null) missing.add(fFotoKegiatan);
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

    if (selectedJabatan == null) {
      missing.add(fJabatan);
    } else if (selectedJabatan!.isOther &&
        (jabatanManual == null || jabatanManual!.trim().isEmpty)) {
      missing.add(fJabatan);
    }

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
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = await img.readAsBytes();
      }

      setState(() {
        fileFoto = img;
        fotoBytes = bytes;
      });

      _clearMissing(fFotoKegiatan);
    }
  }

  Map<String, dynamic> _buildP5MPayload() {
    return {
      'nama': nama.text,
      'jabatan': selectedJabatan?.isOther == true
          ? (jabatanManual ?? "")
          : (selectedJabatan?.label ?? ""),
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'namaPembicara': nama_pembicara.text,
      'topik': topik.text,
      'kondisiKesehatan': kondisi_kesehatan ?? "",
      'jamTidur': jam_tidur ?? "",
      'siapKerja': siap_kerja ?? "",
      'statusHariKerja': status_hari_kerja ?? "",
      'umpanBalik': umpan_balik.text,
    };
  }

  List<String> _buildP5MFilePaths() {
    if (kIsWeb) return [];

    return [
      if (fileFoto?.path != null && fileFoto!.path.isNotEmpty) fileFoto!.path,
    ];
  }

  Future<bool> _submitP5MOnce(Map<String, dynamic> payload) async {
    return await P5MService.submitP5M(
      nama: (payload['nama'] ?? '').toString().trim(),
      jabatan: (payload['jabatan'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      namaPembicara: (payload['namaPembicara'] ?? '').toString().trim(),
      topik: (payload['topik'] ?? '').toString().trim(),
      kondisiKesehatan: (payload['kondisiKesehatan'] ?? '').toString().trim(),
      jamTidur: (payload['jamTidur'] ?? '').toString().trim(),
      siapKerja: (payload['siapKerja'] ?? '').toString().trim(),
      statusHariKerja: (payload['statusHariKerja'] ?? '').toString().trim(),
      umpanBalik: (payload['umpanBalik'] ?? '').toString().trim(),

      fotoPath: kIsWeb ? null : fileFoto?.path,
      fotoBytes: kIsWeb ? fotoBytes : null,
      fotoName: fileFoto?.name,
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT P5M TIMEOUT");
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
                    text: fileFoto == null ? "Pilih Foto" : fileFoto!.name,
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
                                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
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
      await ValidationErrorDialog.show(
        context: context,
        missingFields: missing,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _submitProgressText.value = "Mengirim data P5M...";

    SubmitLoadingDialog.show(
      context: context,
      messageNotifier: _submitProgressText,
    );

    final payload = _buildP5MPayload();
    final filePaths = _buildP5MFilePaths();

    bool ok = false;
    bool savedToPending = false;

    try {
      ok = await RetrySubmitHelper.run(
        maxRetry: _maxAutoRetry,
        retryDelay: _retryDelay,
        onProgress: (attempt, maxRetry) {
          if (!mounted) return;

          _submitProgressText.value = attempt == 1
              ? "Mengirim data P5M..."
              : "Mengirim ulang... percobaan $attempt dari $maxRetry";
        },
        action: () => _submitP5MOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveP5M(payload: payload, filePaths: filePaths);
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveP5M(payload: payload, filePaths: filePaths);
      savedToPending = true;
    }

    if (!mounted) return;

    SubmitLoadingDialog.close(context);

    setState(() {
      _isSubmitting = false;
    });

    _submitProgressText.value = "Mengirim data P5M...";

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
