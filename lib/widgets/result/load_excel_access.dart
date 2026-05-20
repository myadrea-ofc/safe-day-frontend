import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/service/excel_access_service.dart';

class LoadExcelAccessResult {
  final List<ExcelAccess> accessList;
  final int unseenAddedBySuperadmin;
  final String feature;

  LoadExcelAccessResult({
    required this.accessList,
    required this.unseenAddedBySuperadmin,
    required this.feature,
  });
}

Future<LoadExcelAccessResult> loadExcelAccess({
  required String role,
  required int currentSiteId,
  required String feature,
}) async {
  final response = await ExcelAccessService.fetchAccess();

  final list = response
      .map(
        (e) => ExcelAccess(
          userId: e["user_id"],
          userName: e["user_name"],
          userRole: e["role_name"],
          siteId: e["site_id"],
          siteName: e["site_name"],
          canDownload: e["can_download"],
          grantedBy: 0,
          createdAt:
              DateTime.tryParse(e["created_at"]?.toString() ?? "") ??
              DateTime(2000),
          seenByAdmin: e["seen_by_admin"],
          feature: e["feature"],
        ),
      )
      .toList();

  final filteredByRole = (role == 'admin')
      ? list.where((e) => e.siteId == currentSiteId).toList()
      : list;

  final unseenAddedBySuperadmin = role == 'admin'
      ? filteredByRole.where((e) => e.seenByAdmin == false).length
      : 0;

  return LoadExcelAccessResult(
    accessList: filteredByRole,
    unseenAddedBySuperadmin: unseenAddedBySuperadmin,
    feature: feature,
  );
}
