import 'package:safety_apps/models/pending_submission_entity.dart';
import 'package:safety_apps/service/hazard_service.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_chp_service.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_fasilitas_bbm.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_jalan_tambang_service.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_kantor_service.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_mtd.service.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_plant_service.dart';
import 'package:safety_apps/service/lpi_service.dart';
import 'package:safety_apps/service/p2h/p2h_bus_service.dart';
import 'package:safety_apps/service/p2h/p2h_compactor_service.dart';
import 'package:safety_apps/service/p2h/p2h_crane_service.dart';
import 'package:safety_apps/service/p2h/p2h_dozer_service.dart';
import 'package:safety_apps/service/p2h/p2h_dt_service.dart';
import 'package:safety_apps/service/p2h/p2h_exca_service.dart';
import 'package:safety_apps/service/p2h/p2h_forklift_service.dart';
import 'package:safety_apps/service/p2h/p2h_fueltruck_service.dart';
import 'package:safety_apps/service/p2h/p2h_grader_service.dart';
import 'package:safety_apps/service/p2h/p2h_lv_service.dart';
import 'package:safety_apps/service/p2h/p2h_service_truck_service.dart';
import 'package:safety_apps/service/p2h/p2h_towerlamp.service.dart';
import 'package:safety_apps/service/p2h/p2h_truck.dart';
import 'package:safety_apps/service/p2h/p2h_water_pump_service.dart';
import 'package:safety_apps/service/p2h/p2h_water_truck.service.dart';
import 'package:safety_apps/service/p2h/p2h_wheelloader.dart';
import 'package:safety_apps/service/p5m_service.dart';

class SubmissionDispatcher {
  static Future<bool> resend(PendingSubmissionEntity item) async {
    switch (item.module) {
      case 'hazard':
        return await _resendHazard(item);
      case 'p5m':
        return await _resendP5M(item);
      case 'lpi':
        return await _resendLPI(item);
      case 'inspeksi_jalan_tambang':
        return await _resendInspeksiJalanTambang(item);
      case 'inspeksi_kantor':
        return await _resendInspeksiKantor(item);
      case 'inspeksi_mtd':
        return await _resendInspeksiMTD(item);
      case 'inspeksi_plant':
        return await _resendInspeksiPlant(item);
      case 'inspeksi_chp':
        return await _resendInspeksiCHP(item);
      case 'inspeksi_fasilitas_bbm':
        return await _resendInspeksiFasilitasBBM(item);
      case 'p2h_bus':
        return await _resendP2HBus(item);
      case 'p2h_compactor':
        return await _resendP2HCompactor(item);
      case 'p2h_crane':
        return await _resendP2HCrane(item);
      case 'p2h_dozer':
        return await _resendP2HDozer(item);
      case 'p2h_heavy_duty':
        return await _resendP2HHeavyDuty(item);
      case 'p2h_excavator':
        return await _resendP2HExcavator(item);
      case 'p2h_forklift':
        return await _resendP2HForklift(item);
      case 'p2h_fuel_truck':
        return await _resendP2HFuelTruck(item);
      case 'p2h_grader':
        return await _resendP2HGrader(item);
      case 'p2h_lv':
        return await _resendP2HLV(item);
      case 'p2h_service_truck':
        return await _resendP2HServiceTruck(item);
      case 'p2h_tower_lamp':
        return await _resendP2HTowerLamp(item);
      case 'p2h_truck_hauling':
        return await _resendP2HTruckHauling(item);
      case 'p2h_water_pump':
        return await _resendP2HWaterPump(item);
      case 'p2h_water_truck':
        return await _resendP2HWaterTruck(item);
      case 'p2h_wheel_loader':
        return await _resendP2HWheelLoader(item);
      default:
        return false;
    }
  }

  static Future<bool> _resendHazard(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];

    try {
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
        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendLPI(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? filePath;
    List<String> fotoPaths = [];

    if (files.isNotEmpty) {
      filePath = files.first;
    }

    if (files.length > 1) {
      fotoPaths = files.sublist(1);
    }

    try {
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
        filePath: filePath,
        fotoPaths: fotoPaths,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP5M(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? fotoPath;
    if (files.isNotEmpty) {
      fotoPath = files.first;
    }

    try {
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
        fotoPath: fotoPath,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiJalanTambang(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];

    try {
      return await InspeksiJalanTambangService.submitInspeksiJalanTambang(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),
        opsi21: (payload['opsi21'] ?? '').toString().trim(),
        opsi22: (payload['opsi22'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),
        apar: (payload['apar'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiKantor(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;
    String? foto4Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];
    if (files.length > 3) foto4Path = files[3];

    try {
      return await InspeksiKantorService.submitInspeksiKantor(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),
        opsi21: (payload['opsi21'] ?? '').toString().trim(),
        opsi22: (payload['opsi22'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
        foto4Path: foto4Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiMTD(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;
    String? foto4Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];
    if (files.length > 3) foto4Path = files[3];

    try {
      return await InspeksiMTDService.submitInspeksiMTD(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),
        opsi21: (payload['opsi21'] ?? '').toString().trim(),
        opsi22: (payload['opsi22'] ?? '').toString().trim(),
        opsi23: (payload['opsi23'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
        foto4Path: foto4Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiPlant(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;
    String? foto4Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];
    if (files.length > 3) foto4Path = files[3];

    try {
      return await InspeksiPlantService.submitInspeksiPlant(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),
        opsi21: (payload['opsi21'] ?? '').toString().trim(),
        opsi22: (payload['opsi22'] ?? '').toString().trim(),
        opsi23: (payload['opsi23'] ?? '').toString().trim(),
        opsi24: (payload['opsi24'] ?? '').toString().trim(),
        opsi25: (payload['opsi25'] ?? '').toString().trim(),
        opsi26: (payload['opsi26'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
        foto4Path: foto4Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiCHP(PendingSubmissionEntity item) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;
    String? foto4Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];
    if (files.length > 3) foto4Path = files[3];

    try {
      return await InspeksiCHPService.submitInspeksiCHP(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
        foto4Path: foto4Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendInspeksiFasilitasBBM(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;
    final files = item.localFiles;

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;
    String? foto4Path;

    if (files.isNotEmpty) foto1Path = files[0];
    if (files.length > 1) foto2Path = files[1];
    if (files.length > 2) foto3Path = files[2];
    if (files.length > 3) foto4Path = files[3];

    try {
      return await InspeksiFasilitasBBMService.submitInspeksiFasilitasBBM(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jumlahInspektor: (payload['jumlahInspektor'] ?? '').toString().trim(),

        opsi1: (payload['opsi1'] ?? '').toString().trim(),
        opsi2: (payload['opsi2'] ?? '').toString().trim(),
        opsi3: (payload['opsi3'] ?? '').toString().trim(),
        opsi4: (payload['opsi4'] ?? '').toString().trim(),
        opsi5: (payload['opsi5'] ?? '').toString().trim(),
        opsi6: (payload['opsi6'] ?? '').toString().trim(),
        opsi7: (payload['opsi7'] ?? '').toString().trim(),
        opsi8: (payload['opsi8'] ?? '').toString().trim(),
        opsi9: (payload['opsi9'] ?? '').toString().trim(),
        opsi10: (payload['opsi10'] ?? '').toString().trim(),
        opsi11: (payload['opsi11'] ?? '').toString().trim(),
        opsi12: (payload['opsi12'] ?? '').toString().trim(),
        opsi13: (payload['opsi13'] ?? '').toString().trim(),
        opsi14: (payload['opsi14'] ?? '').toString().trim(),
        opsi15: (payload['opsi15'] ?? '').toString().trim(),
        opsi16: (payload['opsi16'] ?? '').toString().trim(),
        opsi17: (payload['opsi17'] ?? '').toString().trim(),
        opsi18: (payload['opsi18'] ?? '').toString().trim(),
        opsi19: (payload['opsi19'] ?? '').toString().trim(),
        opsi20: (payload['opsi20'] ?? '').toString().trim(),
        opsi21: (payload['opsi21'] ?? '').toString().trim(),

        ketHasil: (payload['ketHasil'] ?? '').toString().trim(),
        saranMasuk: (payload['saranMasuk'] ?? '').toString().trim(),
        statusInspeksi: (payload['statusInspeksi'] ?? '').toString().trim(),

        foto1Path: foto1Path,
        foto2Path: foto2Path,
        foto3Path: foto3Path,
        foto4Path: foto4Path,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HBus(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HBusService.submitP2HBus(
        nama: (payload['nama'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        kmSekarang: (payload['kmSekarang'] ?? '').toString().trim(),
        waktu: (payload['waktu'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),

        opsiKeselamatan1: (payload['opsiKeselamatan1'] ?? '').toString().trim(),
        opsiKeselamatan2: (payload['opsiKeselamatan2'] ?? '').toString().trim(),
        opsiKeselamatan3: (payload['opsiKeselamatan3'] ?? '').toString().trim(),
        opsiKeselamatan4: (payload['opsiKeselamatan4'] ?? '').toString().trim(),

        opsiMasukTambang1: (payload['opsiMasukTambang1'] ?? '')
            .toString()
            .trim(),
        opsiMasukTambang2: (payload['opsiMasukTambang2'] ?? '')
            .toString()
            .trim(),
        opsiMasukTambang3: (payload['opsiMasukTambang3'] ?? '')
            .toString()
            .trim(),
        opsiMasukTambang4: (payload['opsiMasukTambang4'] ?? '')
            .toString()
            .trim(),
        opsiMasukTambang5: (payload['opsiMasukTambang5'] ?? '')
            .toString()
            .trim(),

        laporanTemuan: (payload['laporanTemuan'] ?? '').toString().trim(),
        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),
        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),
        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HCompactor(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HCompactorService.submitP2HCompactor(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HCrane(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HCraneService.submitP2HCrane(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        shiftKerja: (payload['shiftKerja'] ?? '').toString().trim(),
        waktu: (payload['waktu'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
        opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),
        opsiItem34: (payload['opsiItem34'] ?? '').toString().trim(),
        opsiItem35: (payload['opsiItem35'] ?? '').toString().trim(),
        opsiItem36: (payload['opsiItem36'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HDozer(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HDozerService.submitP2HDozer(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        waktu: (payload['waktu'] ?? '').toString().trim(),
        brandUnit: (payload['brandUnit'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
        opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HHeavyDuty(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HDTService.submitP2HDT(
        nama: (payload['nama'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        hmSekarang: (payload['hmSekarang'] ?? '').toString().trim(),
        waktuP2h: (payload['waktuP2h'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        laporanTemuan: (payload['laporanTemuan'] ?? '').toString().trim(),
        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamOperasi: (payload['jamOperasi'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HExcavator(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HExcaService.submitP2HExca(
        nama: (payload['nama'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        hmSekarang: (payload['hmSekarang'] ?? '').toString().trim(),
        waktuP2H: (payload['waktuP2H'] ?? '').toString().trim(),
        lokKerja: (payload['lokKerja'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan4: (payload['opsiStandarKeselamatan4'] ?? '')
            .toString()
            .trim(),

        laporanTemuan: (payload['laporanTemuan'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HForklift(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HForkliftService.submitP2HForklift(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        brandUnit: (payload['brandUnit'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HFuelTruck(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HFuelTruckService.submitP2HFuelTruck(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HGrader(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HGraderService.submitP2HGrader(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
        opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HLV(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
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
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HServiceTruck(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;

    try {
      return await P2HServiceTruckService.submitP2HServiceTruck(
        nama: (payload['nama'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        waktu: (payload['waktu'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),

        opsiKeselamatan1: (payload['opsiKeselamatan1'] ?? '').toString().trim(),
        opsiKeselamatan2: (payload['opsiKeselamatan2'] ?? '').toString().trim(),
        opsiKeselamatan3: (payload['opsiKeselamatan3'] ?? '').toString().trim(),

        penjelasanKondisiUnit: (payload['penjelasanKondisiUnit'] ?? '')
            .toString()
            .trim(),
        jamOperasi: (payload['jamOperasi'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        unitAman: (payload['unitAman'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HTowerLamp(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HTowerlampService.submitP2HTowerlamp(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

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

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HTruckHauling(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;

    try {
      return await P2HTruckService.submitP2HTruck(
        nama: (payload['nama'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),
        waktu: (payload['waktu'] ?? '').toString().trim(),
        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
        opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),
        opsiItem34: (payload['opsiItem34'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        laporanTemuan: (payload['laporanTemuan'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HWaterPump(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
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

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HWaterTruck(PendingSubmissionEntity item) async {
    final payload = item.payload;

    try {
      return await P2HWaterTruckService.submitP2HWaterTruck(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),

        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),
        opsiItem32: (payload['opsiItem32'] ?? '').toString().trim(),
        opsiItem33: (payload['opsiItem33'] ?? '').toString().trim(),
        opsiItem34: (payload['opsiItem34'] ?? '').toString().trim(),

        opsiKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        kimperBerlaku: (payload['kimperBerlaku'] ?? '').toString().trim(),
        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),

        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _resendP2HWheelLoader(
    PendingSubmissionEntity item,
  ) async {
    final payload = item.payload;

    try {
      return await P2HWheelLoaderService.submitP2HWheelLoader(
        nama: (payload['nama'] ?? '').toString().trim(),
        nrp: (payload['nrp'] ?? '').toString().trim(),
        jabatan: (payload['jabatan'] ?? '').toString().trim(),
        tanggal: (payload['tanggal'] ?? '').toString().trim(),
        department: (payload['department'] ?? '').toString().trim(),
        noLambungUnit: (payload['noLambungUnit'] ?? '').toString().trim(),
        perusahaan: (payload['perusahaan'] ?? '').toString().trim(),

        lokasiKerja: (payload['lokasiKerja'] ?? '').toString().trim(),
        hmUnit: (payload['hmUnit'] ?? '').toString().trim(),

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
        opsiItem21: (payload['opsiItem21'] ?? '').toString().trim(),
        opsiItem22: (payload['opsiItem22'] ?? '').toString().trim(),
        opsiItem23: (payload['opsiItem23'] ?? '').toString().trim(),
        opsiItem24: (payload['opsiItem24'] ?? '').toString().trim(),
        opsiItem25: (payload['opsiItem25'] ?? '').toString().trim(),
        opsiItem26: (payload['opsiItem26'] ?? '').toString().trim(),
        opsiItem27: (payload['opsiItem27'] ?? '').toString().trim(),
        opsiItem28: (payload['opsiItem28'] ?? '').toString().trim(),
        opsiItem29: (payload['opsiItem29'] ?? '').toString().trim(),
        opsiItem30: (payload['opsiItem30'] ?? '').toString().trim(),
        opsiItem31: (payload['opsiItem31'] ?? '').toString().trim(),

        opsiStandarKeselamatan1: (payload['opsiStandarKeselamatan1'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan2: (payload['opsiStandarKeselamatan2'] ?? '')
            .toString()
            .trim(),
        opsiStandarKeselamatan3: (payload['opsiStandarKeselamatan3'] ?? '')
            .toString()
            .trim(),

        jamTidur: (payload['jamTidur'] ?? '').toString().trim(),

        statusKeadaan1: (payload['statusKeadaan1'] ?? '').toString().trim(),
        statusKeadaan2: (payload['statusKeadaan2'] ?? '').toString().trim(),
        statusKeadaan3: (payload['statusKeadaan3'] ?? '').toString().trim(),
        statusKeadaan4: (payload['statusKeadaan4'] ?? '').toString().trim(),
        statusKeadaan5: (payload['statusKeadaan5'] ?? '').toString().trim(),
        statusKeadaan6: (payload['statusKeadaan6'] ?? '').toString().trim(),

        statusSiap: (payload['statusSiap'] ?? '').toString().trim(),
        filePaths: List<String>.from(payload['filePaths'] ?? const []),
      );
    } catch (_) {
      return false;
    }
  }
}
