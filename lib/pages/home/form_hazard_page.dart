import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/dropdown/dropdwon_temuan.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';
import '../../service/hazard_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/opsi/opsi_row.dart';
import '../../widgets/upload_box.dart';

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

  @override
  void dispose() {
    nama.dispose();
    id_karyawan.dispose();
    lokasi_temuan.dispose();
    narasi_temuan.dispose();
    info_perbaikan.dispose();
    tanggal.dispose();
    waktu.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedPerusahaan;
  DropdownItemModel? selectedJabatan;

  String? departmentManual;
  String? perusahaanManual;
  String? jabatanManual;
  String? jenis_temuan;
  String? status_sesuai;

  XFile? foto1;
  XFile? foto2;
  XFile? foto3;

  Uint8List? foto1Bytes;
  Uint8List? foto2Bytes;
  Uint8List? foto3Bytes;

  bool _isSubmitting = false;

  static const int _maxAutoRetry = 3;
  static const Duration _submitTimeout = Duration(seconds: 15);
  static const Duration _retryDelay = Duration(seconds: 2);
  final ValueNotifier<String> _submitProgressText = ValueNotifier(
    "Mengirim data Hazard...",
  );

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
  static const fStatusSesuai =
      "Apakah temuan yang disampaikan sudah sesuai dengan kondisi di lapangan?";
  static const fFoto1 = "Dokumentasi 1";
  static const fFoto2 = "Dokumentasi 2";
  static const fFoto3 = "Dokumentasi 3";

  List<String> _getMissingFields() {
    List<String> missing = [];

    if (nama.text.trim().isEmpty) missing.add(fNamaPengisi);
    if (id_karyawan.text.trim().isEmpty) missing.add(fIdKaryawan);
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

  Map<String, dynamic> _buildHazardPayload() {
    return {
      'nama': nama.text,
      'idKaryawan': id_karyawan.text,
      'jabatan': selectedJabatan?.isOther == true
          ? (jabatanManual ?? "")
          : (selectedJabatan?.label ?? ""),
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'lokasiTemuan': lokasi_temuan.text,
      'tanggal': tanggal.text,
      'waktu': waktu.text,
      'jenisTemuan': jenis_temuan ?? "",
      'narasiTemuan': narasi_temuan.text,
      'infoPerbaikan': info_perbaikan.text,
      'statusSesuai': status_sesuai ?? "",
    };
  }

  List<String> _buildHazardFilePaths() {
    if (kIsWeb) return [];

    return [
      if (foto1 != null && foto1!.path.isNotEmpty) foto1!.path,
      if (foto2 != null && foto2!.path.isNotEmpty) foto2!.path,
      if (foto3 != null && foto3!.path.isNotEmpty) foto3!.path,
    ];
  }

  Future<bool> _submitHazardOnce(Map<String, dynamic> payload) async {
    return await HazardService.submitHazard(
      nama: (payload['nama'] ?? '').toString().trim(),
      idKaryawan: (payload['idKaryawan'] ?? '').toString().trim(),
      jabatan: (payload['jabatan'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      lokasiTemuan: (payload['lokasiTemuan'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),
      waktu: (payload['waktu'] ?? '').toString().trim(),
      jenisTemuan: (payload['jenisTemuan'] ?? '').toString().trim(),
      narasiTemuan: (payload['narasiTemuan'] ?? '').toString().trim(),
      infoPerbaikan: (payload['infoPerbaikan'] ?? '').toString().trim(),
      statusSesuai: (payload['statusSesuai'] ?? '').toString().trim(),

      foto1Path: kIsWeb ? null : foto1?.path,
      foto2Path: kIsWeb ? null : foto2?.path,
      foto3Path: kIsWeb ? null : foto3?.path,

      foto1Bytes: kIsWeb ? foto1Bytes : null,
      foto2Bytes: kIsWeb ? foto2Bytes : null,
      foto3Bytes: kIsWeb ? foto3Bytes : null,

      foto1Name: foto1?.name,
      foto2Name: foto2?.name,
      foto3Name: foto3?.name,
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT HAZARD TIMEOUT");
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

                  DropdownTemuan(
                    value: jenis_temuan,
                    showError: _missingFields.contains(fJenisTemuan),
                    onChanged: (selectedValue, manualValue) {
                      setState(() {
                        jenis_temuan = selectedValue == "Lainnya"
                            ? (manualValue ?? "")
                            : selectedValue;
                      });

                      if ((jenis_temuan ?? '').isNotEmpty) {
                        _clearMissing(fJenisTemuan);
                      }
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
                  const SizedBox(height: 15),

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
                                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
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
      await ValidationErrorDialog.show(
        context: context,
        missingFields: missing,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _submitProgressText.value = "Mengirim data Hazard...";

    SubmitLoadingDialog.show(
      context: context,
      messageNotifier: _submitProgressText,
    );

    final payload = _buildHazardPayload();
    final filePaths = _buildHazardFilePaths();

    bool ok = false;
    bool savedToPending = false;

    try {
      ok = await RetrySubmitHelper.run(
        maxRetry: _maxAutoRetry,
        retryDelay: _retryDelay,
        onProgress: (attempt, maxRetry) {
          if (!mounted) return;

          _submitProgressText.value = attempt == 1
              ? "Mengirim data Hazard..."
              : "Mengirim ulang... percobaan $attempt dari $maxRetry";
        },
        action: () => _submitHazardOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveHazard(
          payload: payload,
          filePaths: filePaths,
        );
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveHazard(
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

    _submitProgressText.value = "Mengirim data Hazard...";

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
