import 'pending_submission_service.dart';

class PendingFormHelper {
  static Future<void> saveP5M({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final topik = (payload['topik'] ?? '-').toString();
    final peserta = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'p5m',
      title: 'P5M - $topik',
      subtitle: 'Peserta: $peserta',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveHazard({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final lokasi = (payload['lokasiTemuan'] ?? '-').toString();
    final pelapor = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'hazard',
      title: 'Hazard - $lokasi',
      subtitle: 'Pelapor: $pelapor',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveLPI({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final namaKorban = (payload['namaKorban'] ?? '-').toString();
    final pelapor = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'lpi',
      title: 'LPI - $namaKorban',
      subtitle: 'Pelapor: $pelapor',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiJalanTambang({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_jalan_tambang',
      title: 'Inspeksi Jalan Tambang - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiKantor({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_kantor',
      title: 'Inspeksi Kantor - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiMTD({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_mtd',
      title: 'Inspeksi MTD - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiPlant({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_plant',
      title: 'Inspeksi Plant - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiCHP({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_chp',
      title: 'Inspeksi CHP - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveInspeksiFasilitasBBM({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'inspeksi_fasilitas_bbm',
      title: 'Inspeksi Fasilitas BBM - $tanggal',
      subtitle: 'Pengisi: $nama',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HBus({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    final tanggal = (payload['tanggal'] ?? '-').toString();
    final nama = (payload['nama'] ?? '-').toString();
    final unit = (payload['noLambungUnit'] ?? '-').toString();

    await PendingSubmissionService.save(
      module: 'p2h_bus',
      title: 'P2H Bus - $unit',
      subtitle: 'Pengisi: $nama | Tanggal: $tanggal',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HCompactor({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_compactor',
      title: 'P2H Compactor',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HCrane({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_crane',
      title: 'P2H Crane',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HDozer({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_dozer',
      title: 'P2H Dozer',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HHeavyDuty({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_heavy_duty',
      title: 'P2H Heavy Duty',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HExcavator({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_excavator',
      title: 'P2H Excavator',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HForklift({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_forklift',
      title: 'P2H Forklift',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HFuelTruck({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_fuel_truck',
      title: 'P2H Fuel Truck',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HGrader({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_grader',
      title: 'P2H Grader',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HLV({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_lv',
      title: 'P2H LV',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HServiceTruck({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_service_truck',
      title: 'P2H Service Truck',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HTowerLamp({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_tower_lamp',
      title: 'P2H Tower Lamp',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HTruckHauling({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_truck_hauling',
      title: 'P2H Truck Hauling',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HWaterPump({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_water_pump',
      title: 'P2H Water Pump',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HWaterTruck({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_water_truck',
      title: 'P2H Water Truck',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }

  static Future<void> saveP2HWheelLoader({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
  }) async {
    await PendingSubmissionService.save(
      module: 'p2h_wheel_loader',
      title: 'P2H Wheel Loader',
      subtitle: payload['nama'] ?? '-',
      payload: payload,
      originalFilePaths: filePaths,
    );
  }
}
