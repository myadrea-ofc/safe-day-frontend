import 'package:flutter/foundation.dart';

class PermissionRefresh {
  static final ValueNotifier<int> excelAccessVersion = ValueNotifier<int>(0);

  // 🔥 METHOD YANG KAMU BUTUHKAN
  static void notifyExcelAccessChanged() {
    excelAccessVersion.value++;
  }
}
