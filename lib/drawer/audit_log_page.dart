import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:safety_apps/models/audit_log.dart';
import 'package:safety_apps/models/result/site_item.dart';
import 'package:safety_apps/service/audit_log_service.dart';
import 'package:safety_apps/service/site_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/result/app_bar.dart';
import 'package:safety_apps/widgets/result/date_filter_bar.dart';
import 'package:safety_apps/widgets/result/date_filter_modal.dart';
import 'package:safety_apps/widgets/result/date_preset.dart';
import 'package:safety_apps/widgets/result/detail_dialog.dart';
import 'package:safety_apps/widgets/result/detail_helpers.dart';
import 'package:safety_apps/widgets/result/empty_row.dart';
import 'package:safety_apps/widgets/result/page_style.dart';
import 'package:safety_apps/widgets/result/pagination.dart';
import 'package:safety_apps/widgets/result/pick_custom_range.dart';
import 'package:safety_apps/widgets/result/result_table.dart';
import 'package:safety_apps/widgets/result/search_box.dart';
import 'package:safety_apps/widgets/result/table_helpers.dart';
import 'package:safety_apps/service/export_excel/export_type.dart';
import 'package:safety_apps/widgets/result/export/export_excel_helper.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<AuditLogModel> pageData = [];
  List<SiteItem> sites = [];

  bool loading = true;
  bool loadingSites = false;
  bool _exporting = false;

  int rowsPerPage = 10;
  int currentPage = 0;
  int totalRows = 0;
  int totalPageFromServer = 1;

  String _yyyyMmDd(DateTime dt) {
    return "${dt.year.toString().padLeft(4, "0")}-"
        "${dt.month.toString().padLeft(2, "0")}-"
        "${dt.day.toString().padLeft(2, "0")}";
  }

  String? get _dateFromQuery {
    final range = _presetRange(_datePreset);
    if (range == null) return null;
    return _yyyyMmDd(range.start);
  }

  String? get _dateToQuery {
    final range = _presetRange(_datePreset);
    if (range == null) return null;
    return _yyyyMmDd(range.end);
  }

  final TextEditingController _searchCtrl = TextEditingController();

  DatePreset _datePreset = DatePreset.all;
  DateTimeRange? _customRange;

  int? _selectedSiteId;

  String get _role => AuthSession.role ?? "member";
  bool get _isSuperadmin => _role.toLowerCase() == "superadmin";

  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  List<Map<String, dynamic>> get _siteOptions {
    final list = sites.map((e) => {"id": e.id, "name": e.name}).toList();

    list.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

    return list;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
    loadData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void onSearch(String value) {
    currentPage = 0;
    loadData();
  }

  Future<void> loadData() async {
    try {
      if (!mounted) return;

      setState(() {
        loading = true;
      });

      debugPrint("AUDIT LOG: mulai fetch audit logs page ${currentPage + 1}");

      final res = await AuditLogService.fetchAuditLogs(
        page: currentPage + 1,
        limit: rowsPerPage,
        siteId: _isSuperadmin ? _selectedSiteId : null,
        search: _searchCtrl.text.trim(),
        dateFrom: _dateFromQuery,
        dateTo: _dateToQuery,
      );

      if (!mounted) return;

      setState(() {
        pageData = res.data;
        totalRows = res.total;
        totalPageFromServer = res.totalPage <= 0 ? 1 : res.totalPage;
        loading = false;
      });

      if (_isSuperadmin && sites.isEmpty) {
        fetchSitesForFilter();
      }
    } catch (e) {
      debugPrint("AUDIT LOG ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat audit log: $e")));
    }
  }

  Future<void> fetchSitesForFilter() async {
    if (!mounted) return;

    setState(() {
      loadingSites = true;
    });

    try {
      debugPrint("AUDIT LOG: mulai fetch sites");

      final siteData = await SiteService.fetchSites();

      if (!mounted) return;

      debugPrint("AUDIT LOG: sites selesai: ${siteData.length}");

      setState(() {
        sites = siteData;
        loadingSites = false;
      });
    } catch (e) {
      debugPrint("AUDIT LOG SITE ERROR: $e");

      if (!mounted) return;

      setState(() {
        loadingSites = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat site: $e")));
    }
  }

  DateTimeRange? _presetRange(DatePreset p) {
    final now = DateTime.now();

    DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

    if (p == DatePreset.all) return null;

    if (p == DatePreset.today) {
      final start = startOfDay(now);
      final end = start.add(const Duration(days: 1));
      return DateTimeRange(start: start, end: end);
    }

    if (p == DatePreset.week) {
      final today = startOfDay(now);
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return DateTimeRange(start: start, end: end);
    }

    if (p == DatePreset.month) {
      final start = DateTime(now.year, now.month, 1);
      final end = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(start: start, end: end);
    }

    return _customRange;
  }

  Color _actionColor(String value) {
    final action = value.toUpperCase();

    if (action.contains("FAILED")) return const Color(0xFFDC2626);
    if (action.contains("DELETE")) return const Color(0xFFDC2626);
    if (action.contains("LOGIN")) return const Color(0xFF16A34A);
    if (action.contains("LOGOUT")) return const Color(0xFF64748B);
    if (action.contains("POST")) return const Color(0xFF16A34A);
    if (action.contains("PUT")) return const Color(0xFFF97316);
    if (action.contains("EXPORT")) return const Color(0xFF7C3AED);
    if (action.contains("GET")) return ResultPageStyle.primary;

    return const Color(0xFF475569);
  }

  IconData _actionIcon(String value) {
    final action = value.toUpperCase();

    if (action.contains("LOGIN")) return Icons.login_rounded;
    if (action.contains("LOGOUT")) return Icons.logout_rounded;
    if (action.contains("POST")) return Icons.add_circle_outline_rounded;
    if (action.contains("PUT")) return Icons.edit_note_rounded;
    if (action.contains("DELETE")) return Icons.delete_outline_rounded;
    if (action.contains("EXPORT")) return Icons.download_rounded;
    if (action.contains("GET")) return Icons.visibility_outlined;

    return Icons.history_rounded;
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "-";

    return "${dt.day.toString().padLeft(2, "0")}/"
        "${dt.month.toString().padLeft(2, "0")}/"
        "${dt.year}";
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "-";

    return "${dt.day.toString().padLeft(2, "0")}/"
        "${dt.month.toString().padLeft(2, "0")}/"
        "${dt.year} "
        "${dt.hour.toString().padLeft(2, "0")}:"
        "${dt.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultPageStyle.bg,
      appBar: ResultAppBar(
        title: "Audit Log",
        total: totalRows,
        onBack: () => Navigator.maybePop(context),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, c) {
                const tableHeadingHeight = 60.0;
                const tableRowHeight = 66.0;

                final tableHeight =
                    tableHeadingHeight + (rowsPerPage * tableRowHeight);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            ResultSearchBox(
                              controller: _searchCtrl,
                              onChanged: onSearch,
                              hasQuery: _hasQuery,
                              onClear: () {
                                _searchCtrl.clear();

                                setState(() {
                                  currentPage = 0;
                                });

                                loadData();
                              },
                            ),
                            const SizedBox(height: 12),

                            if (_isSuperadmin) ...[
                              _siteFilter(),
                              const SizedBox(height: 12),
                            ],

                            ResultDateFilterBar(
                              datePreset: _datePreset,
                              range: _presetRange(_datePreset),
                              exporting: _exporting,
                              filteredLength: totalRows,
                              canCurrentUserDownloadExcel: true,
                              onNoExcelAccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Anda tidak memiliki akses export Audit Log.",
                                    ),
                                  ),
                                );
                              },
                              onExportExcel: () async {
                                if (_exporting) return;

                                await exportExcelCurrentFilter(
                                  context: context,
                                  canCurrentUserDownloadExcel: true,
                                  type: ExportType.audit_logs,
                                  range: _presetRange(_datePreset),
                                  extraQuery: {
                                    "search": _searchCtrl.text.trim(),
                                    "site_id":
                                        _isSuperadmin && _selectedSiteId != null
                                        ? _selectedSiteId.toString()
                                        : null,
                                  },
                                  onNoAccess: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Anda tidak memiliki akses export Audit Log.",
                                        ),
                                      ),
                                    );
                                  },
                                  onStartExporting: () {
                                    if (!mounted) return;
                                    setState(() => _exporting = true);
                                  },
                                  onFinishExporting: () {
                                    if (!mounted) return;
                                    setState(() => _exporting = false);
                                  },
                                );
                              },
                              onOpenDateFilterModal: () => openDateFilterModal(
                                context: context,
                                selectedPreset: _datePreset,
                                onSelectAll: () {
                                  setState(() {
                                    _datePreset = DatePreset.all;
                                    currentPage = 0;
                                  });

                                  loadData();
                                  Navigator.pop(context);
                                },
                                onSelectToday: () {
                                  setState(() {
                                    _datePreset = DatePreset.today;
                                    currentPage = 0;
                                  });

                                  loadData();
                                  Navigator.pop(context);
                                },
                                onSelectWeek: () {
                                  setState(() {
                                    _datePreset = DatePreset.week;
                                    currentPage = 0;
                                  });

                                  loadData();
                                  Navigator.pop(context);
                                },
                                onSelectMonth: () {
                                  setState(() {
                                    _datePreset = DatePreset.month;
                                    currentPage = 0;
                                  });

                                  loadData();
                                  Navigator.pop(context);
                                },
                                onSelectCustom: () async {
                                  Navigator.pop(context);

                                  final picked = await pickCustomRange(
                                    context: context,
                                    initialDateRange: _customRange,
                                  );

                                  if (picked == null) return;

                                  setState(() {
                                    _customRange = picked;
                                    _datePreset = DatePreset.custom;
                                    currentPage = 0;
                                  });

                                  loadData();
                                },
                              ),
                              onTapPreset: (p) async {
                                if (_datePreset == p) return;

                                if (p == DatePreset.custom) {
                                  final picked = await pickCustomRange(
                                    context: context,
                                    initialDateRange: _customRange,
                                  );

                                  if (picked == null) return;

                                  setState(() {
                                    _customRange = picked;
                                    _datePreset = DatePreset.custom;
                                    currentPage = 0;
                                  });

                                  loadData();
                                  return;
                                }

                                setState(() {
                                  _datePreset = p;
                                  currentPage = 0;
                                });

                                loadData();
                              },
                            ),
                            const SizedBox(height: 14),

                            SizedBox(height: tableHeight, child: _table()),
                            const SizedBox(height: 12),

                            ResultPagination(
                              filteredLength: totalRows,
                              currentPage: currentPage,
                              rowsPerPage: rowsPerPage,
                              pageDataLength: pageData.length,
                              onRowsPerPageChanged: (v) {
                                setState(() {
                                  rowsPerPage = v;
                                  currentPage = 0;
                                });

                                FocusScope.of(context).unfocus();
                                loadData();
                              },
                              onPrevPage: () {
                                if (currentPage <= 0) return;

                                setState(() {
                                  currentPage--;
                                });

                                loadData();
                              },
                              onNextPage: () {
                                if (currentPage + 1 >= totalPageFromServer)
                                  return;

                                setState(() {
                                  currentPage++;
                                });

                                loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _siteFilter() {
    return Container(
      decoration: BoxDecoration(
        color: ResultPageStyle.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: loadingSites
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Memuat Site...",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<int?>(
              value: _selectedSiteId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: "Semua Site",
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: ResultPageStyle.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: ResultPageStyle.primary.withOpacity(0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 64),
                suffixIcon: _selectedSiteId == null
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.black.withOpacity(0.55),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedSiteId = null;
                            currentPage = 0;
                          });

                          loadData();
                        },
                      ),
                filled: true,
                fillColor: ResultPageStyle.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    "Semua Site",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                ..._siteOptions.map((site) {
                  return DropdownMenuItem<int?>(
                    value: site["id"] as int,
                    child: Text(
                      site["name"].toString(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSiteId = value;
                  currentPage = 0;
                });

                loadData();
              },
            ),
    );
  }

  Widget _table() {
    const tableHeadingHeight = 60.0;
    const tableRowHeight = 66.0;

    final columns = const [
      DataColumn2(label: Center(child: Text("No")), fixedWidth: 80),
      DataColumn2(
        label: Center(child: Text("Tanggal dan Waktu")),
        fixedWidth: 250,
      ),
      DataColumn2(label: Center(child: Text("User")), fixedWidth: 220),
      DataColumn2(label: Center(child: Text("Role")), fixedWidth: 180),
      DataColumn2(label: Center(child: Text("Site")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Department")), fixedWidth: 220),
      DataColumn2(label: Center(child: Text("Action")), fixedWidth: 170),
      DataColumn2(label: Center(child: Text("Akses")), fixedWidth: 190),
      DataColumn2(label: Center(child: Text("Method")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Status")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Detail")), fixedWidth: 130),
    ];

    return ResultTable(
      headingRowHeight: tableHeadingHeight,
      dataRowHeight: tableRowHeight,
      minWidth: 5000,
      columns: columns,
      rows: [
        ...List.generate(pageData.length, (i) => _rowPremium(pageData[i], i)),
        ...List.generate(
          rowsPerPage - pageData.length,
          (_) => buildEmptyRow(columns.length),
        ),
      ],
    );
  }

  DataRow _rowPremium(AuditLogModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;
    final zebra = index.isEven;
    final bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: WidgetStateProperty.all(bg),
      cells: [
        DataCell(buildResultCell(no.toString(), weight: FontWeight.w900)),
        DataCell(Center(child: buildResultCell(_formatDateTime(e.createdAt)))),
        DataCell(buildResultCellWrap(e.userName ?? "-")),
        DataCell(Center(child: _roleChip(e.userRole ?? "-"))),
        DataCell(buildResultCellWrap(e.siteName ?? "-")),
        DataCell(buildResultCellWrap(e.departmentName ?? "-")),
        DataCell(Center(child: _actionChip(e.action))),
        DataCell(buildResultCellWrap(e.module ?? "-")),
        DataCell(Center(child: buildResultCell(e.method ?? "-"))),
        DataCell(Center(child: _statusChip(e.responseStatus))),
        DataCell(
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showDetail(e),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: ResultPageStyle.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ResultPageStyle.primary.withOpacity(0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  "Detail",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(String? actionValue) {
    final action = actionValue ?? "-";
    final color = _actionColor(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_actionIcon(action), size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String roleValue) {
    final role = roleValue.toLowerCase().trim();

    Color color = Colors.blueGrey;

    if (role == "superadmin") {
      color = const Color(0xFF16A34A);
    } else if (role == "admin") {
      color = const Color(0xFFF97316);
    } else if (role == "member") {
      color = ResultPageStyle.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        roleValue,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusChip(int? status) {
    final value = status?.toString() ?? "-";

    Color color = Colors.blueGrey;

    if (status != null) {
      if (status >= 200 && status < 300) {
        color = const Color(0xFF16A34A);
      } else if (status >= 400) {
        color = const Color(0xFFDC2626);
      } else {
        color = const Color(0xFFF97316);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  void showDetail(AuditLogModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ResultDetailBottomSheet(
          title: "Detail Audit Log",
          onClose: () => Navigator.pop(context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildResultSectionTitle("Informasi Aktivitas"),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Action", e.action ?? "-"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox("Module", e.module ?? "-"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Method", e.method ?? "-"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox(
                      "Status",
                      e.responseStatus?.toString() ?? "-",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildResultFlatBox("Endpoint", e.endpoint ?? "-"),
              const SizedBox(height: 12),
              buildResultFlatBox(
                "Tanggal dan Waktu",
                _formatDateTime(e.createdAt),
              ),
              const SizedBox(height: 12),
              buildResultFlatBox(
                "Description",
                e.description ?? "-",
                isLongText: true,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),

              buildResultSectionTitle("Informasi User"),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Nama", e.userName ?? "-"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox("Role", e.userRole ?? "-"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Site", e.siteName ?? "-"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox(
                      "Department",
                      e.departmentName ?? "-",
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),

              buildResultSectionTitle("Informasi Device"),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("IP Address", e.ipAddress ?? "-"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox("Device ID", e.deviceId ?? "-"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildResultFlatBox(
                "User Agent",
                e.userAgent ?? "-",
                isLongText: true,
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
