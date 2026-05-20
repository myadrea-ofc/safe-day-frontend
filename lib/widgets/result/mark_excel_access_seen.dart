import 'package:safety_apps/network/api_client.dart';

Future<void> markExcelAccessSeen({
  required String role,
  String? feature,
  required Future<void> Function() onReloadAccess,
}) async {
  if (role != 'admin') return;

  try {
    final f = (feature ?? "").trim();

    final url = f.isEmpty
        ? "/excel-access/mark-seen"
        : "/excel-access/mark-seen?feature=$f";

    final res = await ApiClient.post(url);
    if (res.statusCode == 200) {
      await onReloadAccess();
    }
  } catch (_) {}
}
