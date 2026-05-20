import 'package:flutter/material.dart';
import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/widgets/result/confirm_delete_excel_access.dart';

Future<void> showExcelAccessBottomSheet({
  required BuildContext context,
  required List<ExcelAccess> allAccess,
  required Future<void> Function(ExcelAccess access, bool value) onToggleAccess,
  required Future<void> Function(ExcelAccess access) onDeletedAccess,
  required VoidCallback refreshParent,
  required String feature,
}) async {
  String q = "";

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = allAccess.where((a) {
            if (q.trim().isEmpty) return true;
            final s = q.toLowerCase().trim();
            final name = a.userName.toLowerCase();
            final site = a.siteName.toLowerCase();
            final role = a.userRole.toLowerCase();
            return name.contains(s) || site.contains(s) || role.contains(s);
          }).toList();

          return ResultExcelAccessBottomSheet(
            q: q,
            onChangedQuery: (val) => setModalState(() => q = val),
            filtered: filtered,
            itemWidgets: filtered.map((a) {
              return ResultExcelAccessBottomSheetItem(
                access: a,
                onDelete: () async {
                  Navigator.pop(context);
                  await confirmDeleteExcelAccess(
                    context: context,
                    access: a,
                    feature: feature,
                    onDeleted: () async {
                      await onDeletedAccess(a);
                    },
                  );
                },
                onChanged: (v) async {
                  setModalState(() => a.canDownload = v);
                  await onToggleAccess(a, v);
                  refreshParent();
                },
              );
            }).toList(),
          );
        },
      );
    },
  );
}

class ResultExcelAccessBottomSheet extends StatelessWidget {
  final String q;
  final ValueChanged<String> onChangedQuery;
  final List<ExcelAccess> filtered;
  final List<Widget> itemWidgets;

  const ResultExcelAccessBottomSheet({
    super.key,
    required this.q,
    required this.onChangedQuery,
    required this.filtered,
    required this.itemWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xff1d63ff),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kelola Akses Download Excel",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${filtered.length} data ditampilkan",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Cari user / site / role...",
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f5f9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.search_rounded, size: 22),
                    ),
                    suffixIcon: q.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => onChangedQuery(""),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  onChanged: onChangedQuery,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: const Color(0xfff1f5f9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 30,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Tidak ada hasil",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Coba gunakan kata kunci lain untuk user, site, atau role.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.52),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: itemWidgets.length,
                      itemBuilder: (context, i) => itemWidgets[i],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultExcelAccessBottomSheetItem extends StatelessWidget {
  final ExcelAccess access;
  final VoidCallback onDelete;
  final ValueChanged<bool> onChanged;

  const ResultExcelAccessBottomSheetItem({
    super.key,
    required this.access,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final a = access;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xffe0e7ff), Color(0xffdbeafe)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      a.userName.isNotEmpty ? a.userName[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xff1e293b),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    a.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: Color(0xff111827),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8fafc),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 14,
                              color: Color(0xff475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a.siteName,
                              style: const TextStyle(
                                fontSize: 11.8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffeef2ff),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: Color(0xff4f46e5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a.userRole,
                              style: const TextStyle(
                                fontSize: 11.8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff4338ca),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: a.canDownload
                              ? const Color(0xffecfdf5)
                              : const Color(0xfffff7ed),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              a.canDownload
                                  ? Icons.check_circle_rounded
                                  : Icons.block_rounded,
                              size: 14,
                              color: a.canDownload
                                  ? const Color(0xff059669)
                                  : const Color(0xffea580c),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a.canDownload ? "Akses Aktif" : "Akses Nonaktif",
                              style: TextStyle(
                                fontSize: 11.8,
                                fontWeight: FontWeight.w800,
                                color: a.canDownload
                                    ? const Color(0xff047857)
                                    : const Color(0xffc2410c),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: "Hapus",
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Switch(value: a.canDownload, onChanged: onChanged),
                    const SizedBox(height: 4),
                    Text(
                      a.canDownload ? "Aktif" : "Tidak Aktif",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: a.canDownload
                            ? const Color(0xff16a34a)
                            : const Color(0xffef4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
