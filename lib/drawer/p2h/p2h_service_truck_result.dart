import 'dart:ui';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p2h/p2h_service_truck_result.dart';
import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/pages/excel_access.dart';
import 'package:safety_apps/service/export_excel/export_type.dart';
import 'package:safety_apps/service/p2h/p2h_service_truck_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/result/app_bar.dart';
import 'package:safety_apps/widgets/result/confirm_delete_excel_access.dart';
import 'package:safety_apps/widgets/result/date_filter_bar.dart';
import 'package:safety_apps/widgets/result/date_filter_modal.dart';
import 'package:safety_apps/widgets/result/date_preset.dart';
import 'package:safety_apps/widgets/result/detail_dialog.dart';
import 'package:safety_apps/widgets/result/detail_helpers.dart';
import 'package:safety_apps/widgets/result/empty_row.dart';
import 'package:safety_apps/widgets/result/excel_access_bottom_sheet.dart';
import 'package:safety_apps/widgets/result/excel_access_panel.dart';
import 'package:safety_apps/widgets/result/excel_access_row.dart';
import 'package:safety_apps/widgets/result/export/export_excel_helper.dart';
import 'package:safety_apps/widgets/result/inspeksi/inspeksi_flat_box.dart';
import 'package:safety_apps/widgets/result/load_excel_access.dart';
import 'package:safety_apps/widgets/result/mark_excel_access_seen.dart';
import 'package:safety_apps/widgets/result/no_excel_access_dialog.dart';
import 'package:safety_apps/widgets/result/p2h/detail_helpers.dart';
import 'package:safety_apps/widgets/result/p2h/p2h_helpers.dart';
import 'package:safety_apps/widgets/result/page_style.dart';
import 'package:safety_apps/widgets/result/pagination.dart';
import 'package:safety_apps/widgets/result/pick_custom_range.dart';
import 'package:safety_apps/widgets/result/result_table.dart';
import 'package:safety_apps/widgets/result/search_box.dart';
import 'package:safety_apps/widgets/result/table_helpers.dart';
import 'package:safety_apps/widgets/result/toggle_excel_access.dart';

class P2HServiceTruckResultPage extends StatefulWidget {
  final int? openDetailId;
  const P2HServiceTruckResultPage({super.key, this.openDetailId});
  @override
  State<P2HServiceTruckResultPage> createState() =>
      _P2HServiceTruckResultPageState();
}

class _P2HServiceTruckResultPageState extends State<P2HServiceTruckResultPage>
    with SingleTickerProviderStateMixin {
  List<P2HServiceTruckModel> allData = [];
  List<P2HServiceTruckModel> filtered = [];
  List<ExcelAccess> _accessList = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int rowsPerPage = 10;
  int currentPage = 0;
  int _unseenAddedBySuperadmin = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  bool loading = true;
  bool _openedFromNotif = false;
  bool _exporting = false;
  bool _loadingAccess = false;

  String get _role => AuthSession.role ?? "member";
  int get _currentSiteId => AuthSession.siteId ?? 0;
  bool get _isAdminOrSuperadmin => _role == 'admin' || _role == 'superadmin';

  bool isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp') ||
        p.endsWith('.heic');
  }

  DatePreset _datePreset = DatePreset.all;
  DateTimeRange? _customRange;

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
      final end = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(start: start, end: end);
    }

    return _customRange;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    loadData();
    _loadExcelAccess().then(
      (_) => markExcelAccessSeen(
        role: _role,
        feature: "p2h_service_truck",
        onReloadAccess: _loadExcelAccess,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await P2HServiceTruckService.fetchP2HServiceTruck();
      if (!mounted) return;

      setState(() {
        allData = data;
        filtered = _applySearchAndDate();
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });

      if (widget.openDetailId != null && !_openedFromNotif) {
        P2HServiceTruckModel? target;
        try {
          target = allData.firstWhere((e) => e.id == widget.openDetailId);
        } catch (_) {
          target = null;
        }

        if (target != null) {
          _openedFromNotif = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDetail(target!);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    }
  }

  List<P2HServiceTruckModel> _applySearchAndDate() {
    final searched = _searchResults(_searchCtrl.text);
    final range = _presetRange(_datePreset);
    if (range == null) return searched;

    return searched.where((e) {
      if (e.tanggal.isEmpty) return false;

      try {
        final dt = DateTime.parse(e.tanggal);
        return !dt.isBefore(range.start) && dt.isBefore(range.end);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<ExcelAccess> get _sortedAccessNewest {
    final list = List<ExcelAccess>.from(
      _accessList.where((a) => a.feature == "p2h_service_truck"),
    );
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<P2HServiceTruckModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<P2HServiceTruckModel>.from(allData);

    final results = allData.where((e) {
      final nama = safeLower(e.nama);
      final perusahaan = safeLower(e.perusahaan);
      final dept = safeLower(e.department);

      return nama.contains(q) || perusahaan.contains(q) || dept.contains(q);
    }).toList();

    int rankText(String text) {
      if (text.startsWith(q)) return 0;

      final wholeWord = RegExp(
        r'(^|[\s\W])' + RegExp.escape(q) + r'([\s\W]|$)',
      );
      if (wholeWord.hasMatch(text)) return 1;

      if (text.contains(q)) return 2;
      return 3;
    }

    int rankRow(P2HServiceTruckModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);
      return [
        rankText(n),
        rankText(p),
        rankText(d),
      ].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(P2HServiceTruckModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);

      int idx(String s) => s.indexOf(q);

      final inN = idx(n);
      final inP = idx(p);
      final inD = idx(d);

      int best = 1 << 30;
      if (inN >= 0) best = inN < best ? inN : best;
      if (inP >= 0) best = inP < best ? inP : best;
      if (inD >= 0) best = inD < best ? inD : best;

      return best == (1 << 30) ? (1 << 29) : best;
    }

    results.sort((a, b) {
      final ra = rankRow(a);
      final rb = rankRow(b);
      if (ra != rb) return ra.compareTo(rb);

      final ia = firstIndexRow(a);
      final ib = firstIndexRow(b);
      if (ia != ib) return ia.compareTo(ib);

      return safeLower(a.nama).compareTo(safeLower(b.nama));
    });

    return results;
  }

  List<P2HServiceTruckModel> get pageData {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void onSearch(String v) {
    setState(() {
      filtered = _applySearchAndDate();
      currentPage = 0;
      _ensurePageValid();
    });
  }

  void _refreshFiltered() {
    setState(() {
      filtered = _applySearchAndDate();
      currentPage = 0;
      _ensurePageValid();
    });
  }

  void _ensurePageValid() {
    final tp = _totalPage;
    if (currentPage >= tp) currentPage = tp - 1;
    if (currentPage < 0) currentPage = 0;
  }

  int get _totalPage =>
      (filtered.length / rowsPerPage).ceil().clamp(1, 1 << 30);

  Future<void> _loadExcelAccess() async {
    setState(() => _loadingAccess = true);
    try {
      final result = await loadExcelAccess(
        role: _role,
        currentSiteId: _currentSiteId,
        feature: "p2h_service_truck",
      );

      setState(() {
        _accessList = result.accessList;
        _unseenAddedBySuperadmin = result.unseenAddedBySuperadmin;
      });
    } finally {
      if (mounted) setState(() => _loadingAccess = false);
    }
  }

  Future<void> _toggleAccess(ExcelAccess a, bool v) async {
    await toggleExcelAccess(
      context: context,
      feature: "p2h_service_truck",
      role: _role,
      currentSiteId: _currentSiteId,
      access: a,
      value: v,
      onOptimisticChange: () {
        setState(() => a.canDownload = v);
      },
      onRollback: () {
        setState(() => a.canDownload = !v);
      },
      onRoleChanged: logoutAndRedirect,
    );
  }

  Future<void> logoutAndRedirect() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: "jwt_token");

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }

  bool get _canCurrentUserDownloadExcel {
    if (AuthSession.role == "superadmin") return true;
    if (AuthSession.role == "admin") return true;

    return _accessList.any(
      (a) =>
          a.userId == AuthSession.userId &&
          a.siteId == AuthSession.siteId &&
          a.feature == "p2h_service_truck" &&
          a.canDownload == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultPageStyle.bg,
      appBar: ResultAppBar(
        title: "P2H Service Truck Results",
        total: filtered.length,
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
                                onSearch("");
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),

                            ResultDateFilterBar(
                              datePreset: _datePreset,
                              range: _presetRange(_datePreset),
                              exporting: _exporting,
                              filteredLength: filtered.length,
                              canCurrentUserDownloadExcel:
                                  _canCurrentUserDownloadExcel,
                              onOpenDateFilterModal: () => openDateFilterModal(
                                context: context,
                                selectedPreset: _datePreset,
                                onSelectAll: () {
                                  setState(() => _datePreset = DatePreset.all);
                                  _refreshFiltered();
                                  Navigator.pop(context);
                                },
                                onSelectToday: () {
                                  setState(
                                    () => _datePreset = DatePreset.today,
                                  );
                                  _refreshFiltered();
                                  Navigator.pop(context);
                                },
                                onSelectWeek: () {
                                  setState(() => _datePreset = DatePreset.week);
                                  _refreshFiltered();
                                  Navigator.pop(context);
                                },
                                onSelectMonth: () {
                                  setState(
                                    () => _datePreset = DatePreset.month,
                                  );
                                  _refreshFiltered();
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
                                  });
                                  _refreshFiltered();
                                },
                              ),
                              onExportExcel: () async {
                                if (_exporting) return;

                                await exportExcelCurrentFilter(
                                  context: context,
                                  canCurrentUserDownloadExcel:
                                      _canCurrentUserDownloadExcel,
                                  type: ExportType.p2h_service_truck,
                                  range: _presetRange(_datePreset),
                                  onNoAccess: () =>
                                      showNoExcelAccessDialog(context),
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
                              onNoExcelAccess: () =>
                                  showNoExcelAccessDialog(context),
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
                                  });
                                  _refreshFiltered();
                                  return;
                                }

                                setState(() {
                                  _datePreset = p;
                                });
                                _refreshFiltered();
                              },
                            ),

                            const SizedBox(height: 12),

                            if (_isAdminOrSuperadmin) ...[
                              ResultExcelAccessPanel(
                                role: _role,
                                unseenAddedBySuperadmin:
                                    _unseenAddedBySuperadmin,
                                loadingAccess: _loadingAccess,
                                isEmpty: _accessList
                                    .where(
                                      (a) => a.feature == "p2h_service_truck",
                                    )
                                    .isEmpty,
                                totalCount: _sortedAccessNewest.length,
                                previewChildren: _sortedAccessNewest
                                    .take(3)
                                    .map(
                                      (a) => ResultExcelAccessRow(
                                        access: a,
                                        onChanged: (v) => _toggleAccess(a, v),
                                        onDelete: () =>
                                            confirmDeleteExcelAccess(
                                              context: context,
                                              feature: "p2h_service_truck",
                                              access: a,
                                              onDeleted: () {
                                                setState(() {
                                                  _accessList.removeWhere(
                                                    (x) =>
                                                        x.userId == a.userId &&
                                                        x.siteId == a.siteId,
                                                  );
                                                });
                                              },
                                            ),
                                      ),
                                    )
                                    .toList(),
                                onTapTambah: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GrantExcelAccessPage(
                                        currentUserId: AuthSession.userId!,
                                        currentRole:
                                            AuthSession.role ?? "member",
                                        currentSiteId: AuthSession.siteId,
                                        feature: "p2h_service_truck",
                                        onGranted: () async {
                                          await _loadExcelAccess();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onTapShowMore: () => showExcelAccessBottomSheet(
                                  context: context,
                                  feature: "p2h_service_truck",
                                  allAccess: _sortedAccessNewest,
                                  onToggleAccess: (access, value) =>
                                      _toggleAccess(access, value),
                                  onDeletedAccess: (access) async {
                                    setState(() {
                                      _accessList.removeWhere(
                                        (x) =>
                                            x.userId == access.userId &&
                                            x.siteId == access.siteId,
                                      );
                                    });
                                  },
                                  refreshParent: () => setState(() {}),
                                ),
                                unseenBadge: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFFDBA74),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (_, child) {
                                              return Transform.scale(
                                                scale: _pulseAnimation.value,
                                                child: child,
                                              );
                                            },
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF97316),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _unseenAddedBySuperadmin == 1
                                                ? "New Access"
                                                : "$_unseenAddedBySuperadmin New",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                              color: Color(0xFF9A3412),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            SizedBox(height: tableHeight, child: _table()),
                            const SizedBox(height: 12),

                            ResultPagination(
                              filteredLength: filtered.length,
                              currentPage: currentPage,
                              rowsPerPage: rowsPerPage,
                              pageDataLength: pageData.length,
                              onRowsPerPageChanged: (v) {
                                setState(() {
                                  rowsPerPage = v;
                                  currentPage = 0;
                                  _ensurePageValid();
                                });
                                FocusScope.of(context).unfocus();
                              },
                              onPrevPage: () => setState(() {
                                currentPage--;
                                _ensurePageValid();
                              }),
                              onNextPage: () => setState(() {
                                currentPage++;
                                _ensurePageValid();
                              }),
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

  Widget _table() {
    const tableHeadingHeight = 60.0;
    const tableRowHeight = 66.0;

    final columns = const [
      DataColumn2(label: Center(child: Text("No")), fixedWidth: 90),
      DataColumn2(label: Center(child: Text("Nama")), fixedWidth: 300),
      DataColumn2(label: Center(child: Text("Jabatan")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Department")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Perusahaan")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Tanggal")), fixedWidth: 150),
      DataColumn2(
        label: Center(child: Text("No Lambung Service Truck")),
        fixedWidth: 220,
      ),
      DataColumn2(
        label: Center(child: Text("HM Service Truck Saat ini")),
        fixedWidth: 220,
      ),
      DataColumn2(label: Center(child: Text("Shift Kerja")), fixedWidth: 150),
      DataColumn2(label: Center(child: Text("Siap Kerja")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Dokumen")), fixedWidth: 130),
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

  DataRow _rowPremium(P2HServiceTruckModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;
    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: WidgetStateProperty.all(bg),
      cells: [
        DataCell(buildResultCell(no.toString(), weight: FontWeight.w900)),
        DataCell(buildResultCellWrap(e.nama)),
        DataCell(buildResultCellWrap(e.jabatan)),
        DataCell(buildResultCellWrap(e.department)),
        DataCell(buildResultCellWrap(e.perusahaan)),
        DataCell(Center(child: buildResultCell(formatTanggal(e.tanggal)))),
        DataCell(buildResultCellWrap(e.noLambungUnit)),
        DataCell(buildResultCellWrap(e.hmUnit)),
        DataCell(buildResultCellWrap(e.shiftKerja)),
        DataCell(
          Center(
            child: statusChip<StatusKind>(
              v: e.unitAman,
              kind: (value) => kindStatus(value),
              norm: (value) => normStatus(value),
              iconOf: (kindValue) => kIcon(kindValue),
              noneKind: StatusKind.none,
              yesKind: StatusKind.yes,
              okKind: StatusKind.ok,
              warnKind: StatusKind.warn,
            ),
          ),
        ),
        DataCell(
          Center(
            child: docBtn(
              files: e.files,
              onShowFiles: () => showFilesDialogP2H(
                context: context,
                files: e.files,
                isImageFile: isImageFile,
              ),
            ),
          ),
        ),
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

  void showDetail(P2HServiceTruckModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ResultDetailBottomSheet(
          title: "Detail Laporan P2H Bus",
          onClose: () => Navigator.pop(context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildResultSectionTitle("Informasi Pelapor"),
              pairP2H(
                context,
                flatBoxP2H("Nama Lengkap", e.nama),
                flatBoxP2H("Perusahaan", e.perusahaan),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Department", e.department),
                flatBoxP2H("Jabatan", e.jabatan),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("No Lambung Service Truck", e.noLambungUnit),
                flatBoxP2H("HM Service Truck saat ini", e.hmUnit),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H(
                  "Tanggal dan Waktu Kejadian",
                  "${formatTanggal(e.tanggal)} | ${e.waktu}",
                ),
                flatBoxP2H("Shift Kerja", e.shiftKerja),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),
              buildResultSectionTitle("Item Pemeriksaan"),
              pairP2H(
                context,
                flatBoxP2H("Level Oil Mesin", e.opsiItem1),
                flatBoxP2H("Level Air Radiator", e.opsiItem2),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Bocor Air Radiator", e.opsiItem3),
                flatBoxP2H("Level Minyak Rem", e.opsiItem4),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Oli Mesin", e.opsiItem5),
                flatBoxP2H("Bahan Bakar", e.opsiItem6),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Kondisi Wiper", e.opsiItem7),
                flatBoxP2H(
                  "Kondisi Ban (Kondisi Fisik, Kelurusan, Tekanan & Sekrup)",
                  e.opsiItem8,
                ),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H(
                  "Kondisi Rem (Kaki, Parkir, & Emergency)",
                  e.opsiItem9,
                ),
                flatBoxP2H(
                  "Kondisi Lampu Rotary, Sen Kanan, Sen Kiri dan Bahaya",
                  e.opsiItem10,
                ),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Alarm Mundur", e.opsiItem11),
                flatBoxP2H(
                  "Kondisi Kaca Depan, Belakang, Jendela & Spion",
                  e.opsiItem12,
                ),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Cermin Pandang Belakang & Sisi", e.opsiItem13),
                flatBoxP2H(
                  "Keadaan Body, Kabin dan Kursi Operator & Penumpang",
                  e.opsiItem14,
                ),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Suhu Mesin", e.opsiItem15),
                flatBoxP2H("Klakson", e.opsiItem16),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Uji Rem Fisik", e.opsiItem17),
                flatBoxP2H("Alat Pelambat / Retrader Control", e.opsiItem18),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H(
                  "Pedal Rem Servis dan Modulasi Transmisi",
                  e.opsiItem19,
                ),
                flatBoxP2H("Reaksi Kemudi", e.opsiItem20),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Kemudi Darurat", e.opsiItem21),
                flatBoxP2H("Mesin", e.opsiItem22),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Sistem Elektrik", e.opsiItem23),
                flatBoxP2H("Load Indicator", e.opsiItem24),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Instrumen Panel", e.opsiItem25),
                flatBoxP2H("Alat Pemadam Api", e.opsiItem26),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Kotak PK3", e.opsiItem27),
                flatBoxP2H("Sabuk Keselamatan", e.opsiItem28),
              ),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H("Radio Komunikasi", e.opsiItem29),
                flatBoxP2H("SIMPER tersedia & aktif", e.opsiItem30),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),
              buildResultSectionTitle(
                "Standard Keselamatan - Alat Keselamatan",
              ),
              flatBoxP2H("Safety Cone / Segitiga", e.opsiKeselamatan1),
              const SizedBox(height: 12),
              pairP2H(
                context,
                flatBoxP2H(
                  "APAR (alat pemadam api ringan)",
                  e.opsiKeselamatan2,
                ),
                flatBoxP2H("Kotak P3K", e.opsiKeselamatan2),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              flatBoxP2H(
                "Penjelasan kondisi Unit (Apabila ada kendala)",
                e.penjelasanKondisiUnit,
              ),
              const SizedBox(height: 12),
              flatBoxP2H("Jam Anda sebelum mengoperasikan unit", e.jamOperasi),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),
              buildResultSectionTitle("Kondisi Pelapor"),
              flatBoxP2H(
                "Apakah Anda sedang mengkonsumsi obat yang menyebabkan mengantuk",
                e.statusKeadaan1,
              ),
              const SizedBox(height: 12),
              flatBoxP2H(
                "Apakah jam tidur anda cukup hari ini minimal 6 jam",
                e.statusKeadaan2,
              ),
              const SizedBox(height: 12),
              flatBoxP2H(
                "Apakah Anda tidak ada permasalahan dengan keluarga yang mengganggu konsentrasi Anda",
                e.statusKeadaan3,
              ),
              const SizedBox(height: 12),
              flatBoxP2H(
                "Apakah Anda memiliki masalah dengan atasan Anda",
                e.statusKeadaan4,
              ),
              const SizedBox(height: 12),
              flatBoxP2H(
                "Apakah Anda merasa kurang konsentrasi hari ini",
                e.statusKeadaan5,
              ),
              const SizedBox(height: 12),
              flatBoxP2H(
                "Apakah Anda merasa pandangan mata Anda letih",
                e.statusKeadaan6,
              ),
              const SizedBox(height: 20),
              flatBoxP2H(
                "Apakah Anda sudah siap untuk bekerja & telah menggunakan APD serta memiliki KIMPER sesuai unit yang Anda operasikan",
                e.unitAman,
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
