import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/pending/pending_form_helper.dart';
import 'package:safety_apps/service/pending/retry_submit_helper.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/dropdown/dropdwon_klasifikasi_insiden.dart';
import 'package:safety_apps/widgets/result/status_pending_dialog.dart';
import 'package:safety_apps/widgets/search_dropdown.dart';
import 'package:safety_apps/widgets/submit_loading_dialog.dart';
import 'package:safety_apps/widgets/validation_error_dialog.dart';
import '../../service/lpi_service.dart';
import '../../widgets/label_text.dart';
import '../../widgets/input/input_field.dart';
import '../../widgets/date_field.dart';
import '../../widgets/opsi/opsi_row.dart';
import '../../widgets/upload_box.dart';

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
  TextEditingController kronologi = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    nama_korban.dispose();
    nama_spv.dispose();
    tanggal.dispose();
    waktu.dispose();
    jenis_aset_perusahaan.dispose();
    nama_saksi.dispose();
    kronologi.dispose();
    _submitProgressText.dispose();
    super.dispose();
  }

  DropdownItemModel? selectedDepartment;
  DropdownItemModel? selectedDepartmentSPV;
  DropdownItemModel? selectedDepartmentSaksi;
  DropdownItemModel? selectedPerusahaan;
  DropdownItemModel? selectedJabatanSaksi;
  DropdownItemModel? selectedJabatanKorban;

  String? departmentManual;
  String? departmentSPVManual;
  String? departmentSaksiManual;
  String? perusahaanManual;
  String? jabatanSaksiManual;
  String? jabatanKorbanManual;
  String? klasifikasi_insiden;
  String? status_lokasi;

  PlatformFile? fileDokumen;
  List<XFile> fotoList = [];
  List<Uint8List> fotoBytesList = [];

  bool _isSubmitting = false;

  static const int _maxAutoRetry = 3;
  static const Duration _submitTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 1);

  final ValueNotifier<String> _submitProgressText = ValueNotifier(
    "Mengirim data LPI...",
  );

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
    if (tanggal.text.trim().isEmpty) missing.add(fTanggal);
    if (waktu.text.trim().isEmpty) missing.add(fWaktu);
    if (nama_korban.text.trim().isEmpty) missing.add(fNamaKorban);
    if (jenis_aset_perusahaan.text.trim().isEmpty) missing.add(fJenisAset);
    if (nama_saksi.text.trim().isEmpty) missing.add(fNamaSaksi);

    if (klasifikasi_insiden == null || klasifikasi_insiden!.isEmpty)
      missing.add(fKlasifikasi);
    if (kronologi.text.trim().isEmpty) missing.add(fKronologi);
    if (status_lokasi == null || status_lokasi!.isEmpty)
      missing.add(fStatusLokasi);
    if (fileDokumen == null) missing.add(fDokumen);
    if (selectedDepartment == null) {
      missing.add(fDepartment);
    } else if (selectedDepartment!.isOther &&
        (departmentManual == null || departmentManual!.trim().isEmpty)) {
      missing.add(fDepartment);
    }
    if (selectedDepartmentSPV == null) {
      missing.add(fDepartmentSpv);
    } else if (selectedDepartmentSPV!.isOther &&
        (departmentSPVManual == null || departmentSPVManual!.trim().isEmpty)) {
      missing.add(fDepartmentSpv);
    }
    if (selectedDepartmentSaksi == null) {
      missing.add(fDepartmentSaksi);
    } else if (selectedDepartmentSaksi!.isOther &&
        (departmentSaksiManual == null ||
            departmentSaksiManual!.trim().isEmpty)) {
      missing.add(fDepartmentSaksi);
    }
    if (fotoList.isEmpty) missing.add(fFoto);
    if (selectedPerusahaan == null) {
      missing.add(fPerusahaan);
    } else if (selectedPerusahaan!.isOther &&
        (perusahaanManual == null || perusahaanManual!.trim().isEmpty)) {
      missing.add(fPerusahaan);
    }
    if (selectedJabatanSaksi == null) {
      missing.add(fJabatanSaksi);
    } else if (selectedJabatanSaksi!.isOther &&
        (jabatanSaksiManual == null || jabatanSaksiManual!.trim().isEmpty)) {
      missing.add(fJabatanSaksi);
    }
    if (selectedJabatanKorban == null) {
      missing.add(fJabatanKorban);
    } else if (selectedJabatanKorban!.isOther &&
        (jabatanKorbanManual == null || jabatanKorbanManual!.trim().isEmpty)) {
      missing.add(fJabatanKorban);
    }
    if (nama_spv.text.trim().isEmpty) missing.add(fNamaSpv);

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

  Map<String, dynamic> _buildLPIPayload() {
    return {
      'nama': nama.text,
      'tanggal': tanggal.text,
      'waktu': waktu.text,
      'department': selectedDepartment?.isOther == true
          ? (departmentManual ?? "")
          : (selectedDepartment?.label ?? ""),
      'perusahaan': selectedPerusahaan?.isOther == true
          ? (perusahaanManual ?? "")
          : (selectedPerusahaan?.label ?? ""),
      'namaKorban': nama_korban.text,
      'jabatanKorban': selectedJabatanKorban?.isOther == true
          ? (jabatanKorbanManual ?? "")
          : (selectedJabatanKorban?.label ?? ""),
      'namaSpv': nama_spv.text,
      'departmentSpv': selectedDepartmentSPV?.isOther == true
          ? (departmentSPVManual ?? "")
          : (selectedDepartmentSPV?.label ?? ""),
      'jenisAsetPerusahaan': jenis_aset_perusahaan.text,
      'namaSaksi': nama_saksi.text,
      'jabatanSaksi': selectedJabatanSaksi?.isOther == true
          ? (jabatanSaksiManual ?? "")
          : (selectedJabatanSaksi?.label ?? ""),
      'departmentSaksi': selectedDepartmentSaksi?.isOther == true
          ? (departmentSaksiManual ?? "")
          : (selectedDepartmentSaksi?.label ?? ""),
      'klasifikasiInsiden': klasifikasi_insiden ?? "",
      'kronologi': kronologi.text,
      'statusLokasi': status_lokasi ?? "",
    };
  }

  List<String> _buildLPIFilePaths() {
    if (kIsWeb) return [];

    return [
      if (fileDokumen?.path != null) fileDokumen!.path!,
      ...fotoList.map((e) => e.path),
    ];
  }

  Future<bool> _submitLPIOnce(Map<String, dynamic> payload) async {
    return await LPIService.submitLPI(
      nama: (payload['nama'] ?? '').toString().trim(),
      tanggal: (payload['tanggal'] ?? '').toString().trim(),
      waktu: (payload['waktu'] ?? '').toString().trim(),
      department: (payload['department'] ?? '').toString().trim(),
      perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
      namaKorban: (payload['namaKorban'] ?? '').toString().trim(),
      jabatanKorban: (payload['jabatanKorban'] ?? '').toString().trim(),
      namaSpv: (payload['namaSpv'] ?? '').toString().trim(),
      departmentSpv: (payload['departmentSpv'] ?? '').toString().trim(),
      jenisAsetPerusahaan: (payload['jenisAsetPerusahaan'] ?? '')
          .toString()
          .trim(),
      namaSaksi: (payload['namaSaksi'] ?? '').toString().trim(),
      jabatanSaksi: (payload['jabatanSaksi'] ?? '').toString().trim(),
      departmentSaksi: (payload['departmentSaksi'] ?? '').toString().trim(),
      klasifikasiInsiden: (payload['klasifikasiInsiden'] ?? '')
          .toString()
          .trim(),
      kronologi: (payload['kronologi'] ?? '').toString().trim(),
      statusLokasi: (payload['statusLokasi'] ?? '').toString().trim(),

      filePath: kIsWeb ? null : fileDokumen?.path,
      fileBytes: kIsWeb ? fileDokumen?.bytes : null,
      fileName: fileDokumen?.name,

      fotoPaths: kIsWeb ? [] : fotoList.map((e) => e.path).toList(),
      fotoBytesList: kIsWeb ? fotoBytesList : [],
      fotoNames: fotoList.map((e) => e.name).toList(),
    ).timeout(
      _submitTimeout,
      onTimeout: () {
        debugPrint("SUBMIT LPI TIMEOUT");
        return false;
      },
    );
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

                  SearchableMasterDropdown(
                    label: fJabatanKorban,
                    hint: "Pilih Jabatan Korban",
                    endpoint: "master/jabatan",
                    selectedValue: selectedJabatanKorban,
                    showError: _missingFields.contains(fJabatanKorban),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedJabatanKorban = selected;
                        jabatanKorbanManual = manualValue;
                      });
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

                  SearchableMasterDropdown(
                    label: fDepartmentSpv,
                    hint: "Pilih Department SPV",
                    endpoint: "master/department",
                    selectedValue: selectedDepartmentSPV,
                    showError: _missingFields.contains(fDepartmentSpv),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedDepartmentSPV = selected;
                        departmentSPVManual = manualValue;
                      });
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

                  SearchableMasterDropdown(
                    label: fJabatanSaksi,
                    hint: "Pilih Jabatan Saksi",
                    endpoint: "master/jabatan",
                    selectedValue: selectedJabatanSaksi,
                    showError: _missingFields.contains(fJabatanSaksi),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedJabatanSaksi = selected;
                        jabatanSaksiManual = manualValue;
                      });
                      _clearMissing(fJabatanSaksi);
                    },
                  ),

                  SearchableMasterDropdown(
                    label: fDepartmentSaksi,
                    hint: "Pilih Department Saksi",
                    endpoint: "master/department",
                    selectedValue: selectedDepartmentSaksi,
                    showError: _missingFields.contains(fDepartmentSaksi),
                    onChanged: (selected, manualValue) {
                      setState(() {
                        selectedDepartmentSaksi = selected;
                        departmentSaksiManual = manualValue;
                      });
                      _clearMissing(fDepartmentSaksi);
                    },
                  ),

                  DropdownKlasifikasiInsiden(
                    value: klasifikasi_insiden,
                    showError: _missingFields.contains(fKlasifikasi),
                    onChanged: (selectedValue, manualValue) {
                      setState(() {
                        if (selectedValue != "Lainnya") {
                          klasifikasi_insiden = selectedValue;
                        } else {
                          klasifikasi_insiden = manualValue;
                        }
                      });

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
                        : fileDokumen!.name,
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
                              child: kIsWeb
                                  ? Image.memory(
                                      fotoBytesList[e.key],
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(e.value.path),
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
                                    if (kIsWeb) {
                                      fotoBytesList.removeAt(e.key);
                                    }
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
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    if (fotoList.length + images.length > 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Maksimal 5 foto")));
      return;
    }

    if (kIsWeb) {
      final bytes = await Future.wait(images.map((e) => e.readAsBytes()));

      setState(() {
        fotoList.addAll(images);
        fotoBytesList.addAll(bytes);
      });
    } else {
      setState(() {
        fotoList.addAll(images);
      });
    }

    _clearMissing(fFoto);
  }

  void pickFile() async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: kIsWeb,
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

    if (r != null) {
      setState(() {
        fileDokumen = r.files.single;
        _clearMissing(fDokumen);
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
      await ValidationErrorDialog.show(
        context: context,
        missingFields: missing,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _submitProgressText.value = "Mengirim data LPI...";

    SubmitLoadingDialog.show(
      context: context,
      messageNotifier: _submitProgressText,
    );

    final payload = _buildLPIPayload();
    final filePaths = _buildLPIFilePaths();

    bool ok = false;
    bool savedToPending = false;

    try {
      ok = await RetrySubmitHelper.run(
        maxRetry: _maxAutoRetry,
        retryDelay: _retryDelay,
        onProgress: (attempt, maxRetry) {
          if (!mounted) return;

          _submitProgressText.value = attempt == 1
              ? "Mengirim data LPI..."
              : "Mengirim ulang... percobaan $attempt dari $maxRetry";
        },
        action: () => _submitLPIOnce(payload),
      );

      if (!ok) {
        await PendingFormHelper.saveLPI(payload: payload, filePaths: filePaths);
        savedToPending = true;
      }
    } catch (_) {
      await PendingFormHelper.saveLPI(payload: payload, filePaths: filePaths);
      savedToPending = true;
    }

    if (!mounted) return;

    SubmitLoadingDialog.close(context);

    setState(() {
      _isSubmitting = false;
    });

    _submitProgressText.value = "Mengirim data LPI...";

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
