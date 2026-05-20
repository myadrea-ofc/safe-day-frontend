import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/app_bottom_nav.dart';

import '../../models/pending_submission_entity.dart';
import '../service/pending/pending_submission_service.dart';
import '../service/pending/submission_dispatcher.dart';

class PendingSubmissionPage extends StatefulWidget {
  const PendingSubmissionPage({super.key});

  @override
  State<PendingSubmissionPage> createState() => _PendingSubmissionPageState();
}

class _PendingSubmissionPageState extends State<PendingSubmissionPage> {
  List<PendingSubmissionEntity> items = [];
  bool isLoading = true;
  String? sendingId;

  int totalSend = 0;
  int currentSend = 0;
  bool isSendingAll = false;

  static const Color primaryBlue = Color(0xff1d63ff);
  static const Color secondaryBlue = Color(0xff4fa9ff);
  static const Color pageBg = Color(0xfff5f8ff);
  static const Color cardBg = Colors.white;
  static const Color darkText = Color(0xff172033);
  static const Color mutedText = Color(0xff6f7b8f);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    final data = await PendingSubmissionService.getAll();

    if (!mounted) return;

    setState(() {
      items = data;
      isLoading = false;
    });
  }

  Future<void> resendItem(PendingSubmissionEntity item) async {
    setState(() {
      sendingId = item.id;
    });

    await PendingSubmissionService.updateStatus(item.id, 'sending');

    final ok = await SubmissionDispatcher.resend(item);

    if (ok) {
      await PendingSubmissionService.remove(item.id);
    } else {
      await PendingSubmissionService.incrementRetry(item.id);
      await PendingSubmissionService.updateStatus(item.id, 'failed_retry');
    }

    if (!mounted) return;

    setState(() {
      sendingId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? const Color(0xff16324f) : const Color(0xff7a1f1f),
        content: Text(
          ok
              ? 'Submitan berhasil dikirim ulang'
              : 'Gagal kirim ulang. Handler modul belum disambungkan atau jaringan bermasalah.',
        ),
      ),
    );

    await loadData();
  }

  Future<void> deleteItem(PendingSubmissionEntity item) async {
    await PendingSubmissionService.remove(item.id);
    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Submitan pending dihapus'),
      ),
    );
  }

  Future<void> clearAll() async {
    await PendingSubmissionService.clearAll();
    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Semua pending submission dihapus'),
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static const Map<String, String> moduleLabels = {
    'p5m': 'P5M',
    'hazard': 'Hazard',
    'lpi': 'LPI',

    // INSPEKSI
    'inspeksi_jalan_tambang': 'Inspeksi Jalan Tambang',
    'inspeksi_kantor': 'Inspeksi Kantor',
    'inspeksi_mtd': 'Inspeksi Mess, Toilet dan Dapur',
    'inspeksi_plant': 'Inspeksi Plant',
    'inspeksi_chp': 'Inspeksi CHP',
    'inspeksi_fasilitas_bbm': 'Inspeksi BBM',

    // P2H
    'p2h_bus': 'P2H Bus',
    'p2h_compactor': 'P2H Compactor',
    'p2h_crane': 'P2H Crane',
    'p2h_dozer': 'P2H Dozer',
    'p2h_dt': 'P2H Heavy Duty',
    'p2h_excavator': 'P2H Excavator',
    'p2h_forklift': 'P2H Forklift',
    'p2h_fuel_truck': 'P2H Fuel Truck',
    'p2h_grader': 'P2H Grader',
    'p2h_lv': 'P2H LV',
    'p2h_service_truck': 'P2H Service Truck',
    'p2h_tower_lamp': 'P2H Tower Lamp',
    'p2h_truck_hauling': 'P2H Truck Hauling',
    'p2h_water_pump': 'P2H Water Pump',
    'p2h_water_truck': 'P2H Water Truck',
    'p2h_wheel_loader': 'P2H Wheel Loader',
  };
  String moduleLabel(String module) {
    return moduleLabels[module] ??
        module
            .replaceAll('_', ' ')
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
            .join(' ');
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xfff59e0b);
      case 'sending':
        return primaryBlue;
      case 'failed_retry':
        return const Color(0xffef4444);
      default:
        return Colors.grey;
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'sending':
        return 'Mengirim';
      case 'failed_retry':
        return 'Gagal Retry';
      default:
        return status;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'sending':
        return Icons.sync_rounded;
      case 'failed_retry':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryBlue.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  Future<void> showDeleteAllDialog() async {
    if (items.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus semua pending?'),
        content: const Text(
          'Semua data pending submission dan file lokalnya akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await clearAll();
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Future<void> resendAll() async {
    final currentItems = List<PendingSubmissionEntity>.from(items);

    if (currentItems.isEmpty) return;

    setState(() {
      isLoading = true;
      isSendingAll = true;
      totalSend = currentItems.length;
      currentSend = 0;
    });

    int successCount = 0;
    int failedCount = 0;

    for (int i = 0; i < currentItems.length; i++) {
      final item = currentItems[i];

      setState(() {
        currentSend = i + 1;
      });

      await PendingSubmissionService.updateStatus(item.id, 'sending');

      final ok = await SubmissionDispatcher.resend(item);

      if (ok) {
        await PendingSubmissionService.remove(item.id);
        successCount++;
      } else {
        await PendingSubmissionService.incrementRetry(item.id);
        await PendingSubmissionService.updateStatus(item.id, 'failed_retry');
        failedCount++;
      }
    }

    await loadData();

    if (!mounted) return;

    setState(() {
      isSendingAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Kirim semua selesai. Berhasil: $successCount, Gagal: $failedCount',
        ),
      ),
    );
  }

  Future<void> showResendAllDialog() async {
    if (items.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kirim semua pending?'),
        content: Text(
          'Ada ${items.length} submitan pending yang akan dicoba dikirim ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await resendAll();
            },
            child: const Text('Kirim Semua'),
          ),
        ],
      ),
    );
  }

  Widget buildPreviewFiles(PendingSubmissionEntity item) {
    if (item.localFiles.isEmpty) return const SizedBox();

    final previews = item.localFiles.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: previews.map((path) {
          final file = File(path);

          if (!file.existsSync()) {
            return _buildMissingFilePreview();
          }

          final lower = path.toLowerCase();
          final isImage =
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png');

          if (isImage) {
            return Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryBlue.withOpacity(0.08)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(file, fit: BoxFit.cover),
            );
          }

          return Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: primaryBlue,
              size: 32,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissingFilePreview() {
    return Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.hide_image_outlined, color: Colors.grey.shade500),
    );
  }

  Widget buildHeaderSummary() {
    final totalItems = items.length;
    final pendingCount = items.where((e) => e.status == 'pending').length;
    final failedCount = items.where((e) => e.status == 'failed_retry').length;
    final fileCount = items.fold<int>(
      0,
      (sum, item) => sum + item.localFiles.length,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submission Tertunda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pantau, kirim ulang, atau hapus data pending',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: 'Total',
                  value: '$totalItems',
                  icon: Icons.inbox_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  label: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: 'Gagal',
                  value: '$failedCount',
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  label: 'Lampiran',
                  value: '$fileCount',
                  icon: Icons.attach_file_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: items.isEmpty ? null : showResendAllDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: items.isEmpty
                          ? Colors.white24
                          : const Color(0xff22c55e),
                      foregroundColor: items.isEmpty
                          ? Colors.white60
                          : Colors.white,
                      elevation: items.isEmpty ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.send_and_archive_rounded),
                    label: const Text(
                      'Kirim Semua',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: items.isEmpty ? null : showDeleteAllDialog,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: items.isEmpty
                        ? Colors.transparent
                        : const Color(0xffef4444),
                    foregroundColor: items.isEmpty
                        ? Colors.white54
                        : Colors.white,
                    side: BorderSide(
                      color: items.isEmpty
                          ? Colors.white.withOpacity(0.35)
                          : const Color(0xffef4444),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text(
                    'Hapus Semua',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSendingAllState() {
    final progress = totalSend == 0 ? 0.0 : currentSend / totalSend;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: softShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, secondaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Sedang Mengirim Semua',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Harap tunggu, jangan keluar dari halaman.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: progress,
                        backgroundColor: primaryBlue.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Mengirim $currentSend dari $totalSend...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLoadingState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memuat pending submission...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        buildHeaderSummary(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: softShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.14),
                        secondaryBlue.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 42,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tidak Ada Pending Submission',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Semua submitan Anda sudah terkirim atau belum ada data pending yang tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: mutedText, height: 1.5),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: loadData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPendingCard(PendingSubmissionEntity item) {
    final isSending = sendingId == item.id;
    final module = moduleLabel(item.module);
    final status = item.status;
    final statusCol = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow,
        border: Border.all(color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.12),
                        secondaryBlue.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        size: 16,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        module,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusCol.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon(status), size: 15, color: statusCol),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel(status),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusCol,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkText,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildInfoPill(
                  icon: Icons.calendar_today_rounded,
                  text: formatDate(item.createdAt),
                ),
                _buildInfoPill(
                  icon: Icons.refresh_rounded,
                  text: 'Retry ${item.retryCount}',
                ),
                if (item.localFiles.isNotEmpty)
                  _buildInfoPill(
                    icon: Icons.attach_file_rounded,
                    text: '${item.localFiles.length} lampiran',
                  ),
              ],
            ),
            buildPreviewFiles(item),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isSending
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade500,
                                ],
                              )
                            : const LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isSending
                            ? []
                            : [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.22),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isSending ? null : () => resendItem(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        label: Text(
                          isSending ? 'Mengirim...' : 'Kirim Ulang',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => deleteItem(item),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffef4444),
                      side: BorderSide(
                        color: const Color(0xffef4444).withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff7f9fc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primaryBlue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListContent() {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: primaryBlue,
        onRefresh: loadData,
        child: buildEmptyState(),
      );
    }

    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 0, 16, 28),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: buildHeaderSummary(),
            );
          }

          final dataIndex = index - 1;
          final item = items[dataIndex];

          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: buildPendingCard(item),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PENDING SUBMISSION',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Kelola submitan offline yang belum terkirim',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSendingAll
              ? buildSendingAllState()
              : isLoading
              ? buildLoadingState()
              : buildListContent(),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        role: AuthSession.role ?? '',
        site: AuthSession.siteName ?? '',
        department: AuthSession.departmentName ?? '',
        name: AuthSession.name ?? '',
      ),
    );
  }
}
