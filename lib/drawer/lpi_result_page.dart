import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/models/lpi.dart';
import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/pages/excel_access.dart';
import 'package:safety_apps/service/export_excel/export_type.dart';
import 'package:safety_apps/service/lpi_service.dart';
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
import 'package:safety_apps/widgets/result/file/lpi_file_preview_dialog.dart';
import 'package:safety_apps/widgets/result/load_excel_access.dart';
import 'package:safety_apps/widgets/result/mark_excel_access_seen.dart';
import 'package:safety_apps/widgets/result/no_excel_access_dialog.dart';
import 'package:safety_apps/widgets/result/page_style.dart';
import 'package:safety_apps/widgets/result/pagination.dart';
import 'package:safety_apps/widgets/result/photo/lpi_foto_gallery_dialog.dart';
import 'package:safety_apps/widgets/result/pick_custom_range.dart';
import 'package:safety_apps/widgets/result/result_table.dart';
import 'package:safety_apps/widgets/result/search_box.dart';
import 'package:safety_apps/widgets/result/status_pill.dart';
import 'package:safety_apps/widgets/result/table_helpers.dart';
import 'package:safety_apps/widgets/result/toggle_excel_access.dart';

class LPIResultPage extends StatefulWidget {
  final int? openDetailId;
  const LPIResultPage({super.key, this.openDetailId});

  @override
  State<LPIResultPage> createState() => _LPIResultPageState();
}

class _LPIResultPageState extends State<LPIResultPage>
    with SingleTickerProviderStateMixin {
  List<LPIModel> allData = [];
  List<LPIModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  bool _openedFromNotif = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _exporting = false;

  DatePreset _datePreset = DatePreset.all;
  DateTimeRange? _customRange;

  String get _role => AuthSession.role ?? "member";
  int get _currentSiteId => AuthSession.siteId ?? 0;
  bool get _isAdminOrSuperadmin => _role == 'admin' || _role == 'superadmin';

  List<ExcelAccess> _accessList = [];
  bool _loadingAccess = false;
  int _unseenAddedBySuperadmin = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    loadData();
    _loadExcelAccess().then(
      (_) => markExcelAccessSeen(
        role: _role,
        feature: "lpi",
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

  Future<void> loadData() async {
    try {
      final data = await LPIService.fetchLPI();
      if (!mounted) return;

      setState(() {
        allData = data;
        filtered = _applySearchAndDate();
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });

      if (widget.openDetailId != null && !_openedFromNotif) {
        LPIModel? target;
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

  Future<void> _loadExcelAccess() async {
    setState(() => _loadingAccess = true);
    try {
      final result = await loadExcelAccess(
        role: _role,
        currentSiteId: _currentSiteId,
        feature: "lpi",
      );

      setState(() {
        _accessList = result.accessList;
        _unseenAddedBySuperadmin = result.unseenAddedBySuperadmin;
      });
    } finally {
      if (mounted) setState(() => _loadingAccess = false);
    }
  }

  List<ExcelAccess> get _sortedAccessNewest {
    final list = List<ExcelAccess>.from(
      _accessList.where((a) => a.feature == "lpi"),
    );
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _toggleAccess(ExcelAccess a, bool v) async {
    await toggleExcelAccess(
      context: context,
      feature: "lpi",
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
          a.feature == "lpi" &&
          a.canDownload == true,
    );
  }

  List<LPIModel> _applySearchAndDate() {
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

  List<LPIModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<LPIModel>.from(allData);

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

    int rankRow(LPIModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);

      final rn = rankText(n);
      final rp = rankText(p);
      final rd = rankText(d);

      return [rn, rp, rd].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(LPIModel e) {
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

  void _refreshFiltered() {
    setState(() {
      filtered = _applySearchAndDate();
      currentPage = 0;
      _ensurePageValid();
    });
  }

  void onSearch(String v) {
    setState(() {
      filtered = _applySearchAndDate();
      currentPage = 0;
      _ensurePageValid();
    });
  }

  int get _totalPage =>
      (filtered.length / rowsPerPage).ceil().clamp(1, 1 << 30);

  void _ensurePageValid() {
    final tp = _totalPage;
    if (currentPage >= tp) currentPage = tp - 1;
    if (currentPage < 0) currentPage = 0;
  }

  List<LPIModel> get pageData {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultPageStyle.bg,
      appBar: ResultAppBar(
        title: "LPI Results",
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
                                  type: ExportType.lpi,
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
                                ;
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
                                    .where((a) => a.feature == "lpi")
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
                                              feature: "lpi",
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
                                        currentRole:
                                            AuthSession.role ?? "member",
                                        currentSiteId: AuthSession.siteId,
                                        currentUserId: AuthSession.userId!,
                                        feature: "lpi",
                                        onGranted: () async {
                                          await _loadExcelAccess();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onTapShowMore: () => showExcelAccessBottomSheet(
                                  context: context,
                                  feature: "lpi",
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
      DataColumn2(label: Center(child: Text("Nama")), fixedWidth: 280),
      DataColumn2(label: Center(child: Text("Perusahaan")), fixedWidth: 220),
      DataColumn2(label: Center(child: Text("Department")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Tanggal")), fixedWidth: 160),
      DataColumn2(label: Center(child: Text("Klasifikasi")), fixedWidth: 250),
      DataColumn2(label: Center(child: Text("Status")), fixedWidth: 140),
      DataColumn2(label: Center(child: Text("Foto")), fixedWidth: 120),
      DataColumn2(label: Center(child: Text("File")), fixedWidth: 120),
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

  DataRow _rowPremium(LPIModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;
    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: WidgetStateProperty.all(bg),
      cells: [
        DataCell(buildResultCell(no.toString(), weight: FontWeight.w900)),
        DataCell(buildResultCell(e.nama)),
        DataCell(buildResultCellWrap(e.perusahaan)),
        DataCell(buildResultCellWrap(e.department)),
        DataCell(Center(child: buildResultCell(formatTanggal(e.tanggal)))),
        DataCell(buildResultCellWrap(e.klasifikasi)),
        DataCell(Center(child: ResultStatusPill(value: e.statusLokasi))),
        DataCell(
          Center(
            child: e.fotoPaths.isEmpty
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => LpiFotoGalleryDialogHelper(
                      context: context,
                    ).showFotoGallery(e),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ResultPageStyle.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ResultPageStyle.primary.withOpacity(0.14),
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => ResultPageStyle
                            .primaryGradient
                            .createShader(bounds),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        DataCell(
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                LpiFilePreviewDialogHelper(
                  context: context,
                ).showFilePreviewDialog(
                  context: context,
                  fileUrl: "http://safety.borneo.co.id/uploads/${e.filePath}",
                  fileName: e.filePath,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ResultPageStyle.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ResultPageStyle.primary.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: Colors.black54,
                ),
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

  void showDetail(LPIModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ResultDetailBottomSheet(
          title: "Detail Laporan LPI",
          onClose: () => Navigator.pop(context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildResultSectionTitle("Informasi Pelapor"),
              buildResultFlatBox("Nama Lengkap", e.nama),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Perusahaan", e.perusahaan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox("Department", e.department),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildResultFlatBox(
                "Waktu Kejadian",
                "${formatTanggal(e.tanggal)} | ${e.waktu}",
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),
              buildResultSectionTitle("Korban & Supervisor"),
              buildResultFlatBox("Nama Korban", e.namaKorban),
              const SizedBox(height: 12),
              buildResultFlatBox("Jabatan", e.jabatanKorban),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: buildResultFlatBox("Supervisor", e.namaSpv)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox(
                      "Dept. Supervisor",
                      e.departmentSpv,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),
              buildResultSectionTitle("Detail Insiden"),
              buildResultFlatBox("Klasifikasi", e.klasifikasi),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildResultFlatBox("Jenis Aset", e.jenisAset),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildResultFlatBox(
                      "Status Lokasi",
                      e.statusLokasi,
                      isStatus: true,
                      statusValue: e.statusLokasi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildResultFlatBox(
                "Kronologi Kejadian",
                e.kronologi,
                isLongText: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  String formatTanggal(String value) {
    if (value.isEmpty) return "-";

    try {
      final date = DateTime.parse(value);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (e) {
      return value;
    }
  }
}
