import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pending_submission_entity.dart';
import '../../session/auth_session.dart';

class PendingSubmissionService {
  static const String _boxPrefix = 'pending_submissions_box';
  static const Uuid _uuid = Uuid();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (!_isInitialized) {
      await Hive.initFlutter();
      _isInitialized = true;
    }

    final boxName = _currentBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static String _currentUserKey() {
    final employeeId = (AuthSession.employeeId ?? '').trim();
    if (employeeId.isNotEmpty) {
      return employeeId;
    }

    final email = (AuthSession.email ?? '').trim().toLowerCase();
    if (email.isNotEmpty) {
      return email.replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
    }

    final role = (AuthSession.role ?? 'guest').trim().toLowerCase();
    return role.isNotEmpty ? role : 'guest';
  }

  static String _currentBoxName() {
    return '${_boxPrefix}_${_currentUserKey()}';
  }

  static Future<Box> _getBox() async {
    await init();
    final boxName = _currentBoxName();

    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    return await Hive.openBox(boxName);
  }

  static Future<List<PendingSubmissionEntity>> getAll() async {
    final box = await _getBox();
    final items = box.values
        .whereType<Map>()
        .map(
          (e) => PendingSubmissionEntity.fromMap(Map<String, dynamic>.from(e)),
        )
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<PendingSubmissionEntity?> getById(String id) async {
    final box = await _getBox();
    final raw = box.get(id);
    if (raw is! Map) return null;

    return PendingSubmissionEntity.fromMap(Map<String, dynamic>.from(raw));
  }

  static Future<void> save({
    required String module,
    required String title,
    required String subtitle,
    required Map<String, dynamic> payload,
    required List<String> originalFilePaths,
  }) async {
    final box = await _getBox();
    final id = _uuid.v4();

    final copiedFiles = kIsWeb
        ? originalFilePaths
        : await _copyFilesToAppDir(
            submissionId: id,
            originalPaths: originalFilePaths,
          );

    final entity = PendingSubmissionEntity(
      id: id,
      module: module,
      title: title,
      subtitle: subtitle,
      payload: payload,
      localFiles: copiedFiles,
      status: 'pending',
      createdAt: DateTime.now(),
      retryCount: 0,
    );

    await box.put(id, entity.toMap());
  }

  static Future<void> remove(String id) async {
    final box = await _getBox();
    final existing = await getById(id);

    if (existing != null && !kIsWeb) {
      for (final path in existing.localFiles) {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      }

      final dir = await _submissionDirectory(id);

      if (await dir.exists()) {
        final children = dir.listSync();

        if (children.isEmpty) {
          await dir.delete(recursive: true);
        }
      }
    }

    await box.delete(id);
  }

  static Future<void> updateStatus(String id, String status) async {
    final box = await _getBox();
    final existing = await getById(id);
    if (existing == null) return;

    final updated = existing.copyWith(status: status);
    await box.put(id, updated.toMap());
  }

  static Future<void> incrementRetry(String id) async {
    final box = await _getBox();
    final existing = await getById(id);
    if (existing == null) return;

    final updated = existing.copyWith(retryCount: existing.retryCount + 1);
    await box.put(id, updated.toMap());
  }

  static Future<void> upsert(PendingSubmissionEntity entity) async {
    final box = await _getBox();
    await box.put(entity.id, entity.toMap());
  }

  static Future<int> count() async {
    final box = await _getBox();
    return box.length;
  }

  static Future<List<String>> _copyFilesToAppDir({
    required String submissionId,
    required List<String> originalPaths,
  }) async {
    if (kIsWeb) {
      return originalPaths;
    }

    final result = <String>[];
    final targetDir = await _submissionDirectory(submissionId);

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    for (int i = 0; i < originalPaths.length; i++) {
      final originalPath = originalPaths[i];

      if (originalPath.trim().isEmpty) continue;

      final source = File(originalPath);

      if (!await source.exists()) continue;

      final ext = p.extension(originalPath);

      final targetPath = p.join(targetDir.path, 'file_${i + 1}$ext');

      final copied = await source.copy(targetPath);

      result.add(copied.path);
    }

    return result;
  }

  static Future<Directory> _submissionDirectory(String submissionId) async {
    if (kIsWeb) {
      throw UnsupportedError('Directory access is not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();

    return Directory(
      p.join(
        appDir.path,
        'pending_submissions',
        _currentUserKey(),
        submissionId,
      ),
    );
  }

  static Future<void> clearAll() async {
    final box = await _getBox();
    final items = await getAll();

    if (!kIsWeb) {
      for (final item in items) {
        for (final path in item.localFiles) {
          final file = File(path);

          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    }

    await box.clear();
  }

  static Future<List<PendingSubmissionEntity>> getPendingOnly() async {
    final all = await getAll();
    return all
        .where((e) => e.status == 'pending' || e.status == 'failed_retry')
        .toList();
  }

  static Future<int> countPendingOnly() async {
    final data = await getPendingOnly();
    return data.length;
  }

  static Future<void> clearCurrentUserOnly() async {
    await clearAll();
  }
}
