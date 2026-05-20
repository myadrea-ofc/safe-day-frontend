import 'package:flutter/material.dart';
import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/service/excel_access_service.dart';

Future<void> toggleExcelAccess({
  required BuildContext context,
  required String role,
  required int currentSiteId,
  required ExcelAccess access,
  required bool value,
  required VoidCallback onOptimisticChange,
  required VoidCallback onRollback,
  required Future<void> Function() onRoleChanged,
  required String feature,
}) async {
  if (role == 'admin' && access.siteId != currentSiteId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Admin hanya bisa mengatur akses di site sendiri."),
      ),
    );
    return;
  }

  onOptimisticChange();

  try {
    if (value) {
      await ExcelAccessService.grant(
        userId: access.userId,
        siteId: access.siteId,
        feature: feature,
      );
    } else {
      await ExcelAccessService.revoke(
        userId: access.userId,
        siteId: access.siteId,
        feature: feature,
      );
    }
  } catch (e) {
    if (e.toString().contains("role_changed")) {
      await onRoleChanged();
      return;
    }

    onRollback();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Gagal update akses: $e")));
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        value ? "Akses download diaktifkan" : "Akses download dimatikan",
      ),
    ),
  );
}
