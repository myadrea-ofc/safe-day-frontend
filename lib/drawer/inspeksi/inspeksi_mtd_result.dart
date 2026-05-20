import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/inspeksi/inspeksi_mtd.dart';
import 'package:safety_apps/models/result/excel_access.dart';
import 'package:safety_apps/pages/excel_access.dart';
import 'package:safety_apps/service/export_excel/export_type.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_mtd.service.dart';
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
import 'package:safety_apps/widgets/result/page_style.dart';
import 'package:safety_apps/widgets/result/pagination.dart';
import 'package:safety_apps/widgets/result/photo/foto_button.dart';
import 'package:safety_apps/widgets/result/photo/foto_preview_dialog_helper.dart';
import 'package:safety_apps/widgets/result/pick_custom_range.dart';
import 'package:safety_apps/widgets/result/result_table.dart';
import 'package:safety_apps/widgets/result/search_box.dart';
import 'package:safety_apps/widgets/result/table_helpers.dart';
import 'package:safety_apps/widgets/result/toggle_excel_access.dart';

class InspeksiMTDResultPage extends StatefulWidget {
  final int? openDetailId;
  const InspeksiMTDResultPage({super.key, this.openDetailId});
  @override
  State<InspeksiMTDResultPage> createState() => _InspeksiMTDResultPageState();
}

class _InspeksiMTDResultPageState extends State<InspeksiMTDResultPage>
    with SingleTickerProviderStateMixin {
  List<InspeksiMTDModel> allData = [];
  List<InspeksiMTDModel> filtered = [];
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
        feature: "inspeksi_mtd",
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
      final data = await InspeksiMTDService.fetchInspeksiMTD();
      if (!mounted) return;

      setState(() {
        allData = data;
        filtered = _applySearchAndDate();
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });

      if (widget.openDetailId != null && !_openedFromNotif) {
        InspeksiMTDModel? target;
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

  List<InspeksiMTDModel> _applySearchAndDate() {
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
      _accessList.where((a) => a.feature == "inspeksi_mtd"),
    );
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<InspeksiMTDModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<InspeksiMTDModel>.from(allData);

    final results = allData.where((e) {
      final nama = safeLower(e.nama);
      final perusahaan = safeLower(e.perusahaan);
      final dept = safeLower(e.department);
      final nrp = safeLower(e.nrp);

      return nama.contains(q) ||
          perusahaan.contains(q) ||
          dept.contains(q) ||
          nrp.contains(q);
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

    int rankRow(InspeksiMTDModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);
      final r = safeLower(e.nrp);
      return [
        rankText(n),
        rankText(p),
        rankText(d),
        rankText(r),
      ].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(InspeksiMTDModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);
      final r = safeLower(e.nrp);

      int idx(String s) => s.indexOf(q);

      final inN = idx(n);
      final inP = idx(p);
      final inD = idx(d);
      final inR = idx(r);

      int best = 1 << 30;
      if (inN >= 0) best = inN < best ? inN : best;
      if (inP >= 0) best = inP < best ? inP : best;
      if (inD >= 0) best = inD < best ? inD : best;
      if (inR >= 0) best = inR < best ? inR : best;

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

  List<InspeksiMTDModel> get pageData {
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
        feature: "inspeksi_mtd",
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
      feature: "inspeksi_mtd",
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
          a.feature == "inspeksi_mtd" &&
          a.canDownload == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultPageStyle.bg,
      appBar: ResultAppBar(
        title: "Inspeksi Mess, Toilet dan Dapur Results",
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
                                  type: ExportType.inspeksi_mtd,
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
                                    .where((a) => a.feature == "inspeksi_chp")
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
                                              feature: "inspeksi_chp",
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
                                        feature: "inspeksi_chp",
                                        onGranted: () async {
                                          await _loadExcelAccess();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onTapShowMore: () => showExcelAccessBottomSheet(
                                  context: context,
                                  feature: "inspeksi_chp",
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
      DataColumn2(label: Center(child: Text("NRP")), fixedWidth: 140),
      DataColumn2(label: Center(child: Text("Department")), fixedWidth: 200),
      DataColumn2(label: Center(child: Text("Perusahaan")), fixedWidth: 220),
      DataColumn2(
        label: Center(child: Text("Tanggal Inspeksi")),
        fixedWidth: 160,
      ),
      DataColumn2(
        label: Center(child: Text("Jumlah Inspektor")),
        fixedWidth: 200,
      ),
      DataColumn2(label: Center(child: Text("Temuan 1")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Temuan 2")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Temuan 3")), fixedWidth: 130),
      DataColumn2(label: Center(child: Text("Temuan 4")), fixedWidth: 130),
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

  DataRow _rowPremium(InspeksiMTDModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;

    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: WidgetStateProperty.all(bg),
      cells: [
        DataCell(buildResultCell(no.toString(), weight: FontWeight.w900)),
        DataCell(buildResultCellWrap(e.nama)),
        DataCell(buildResultCell(e.nrp)),
        DataCell(buildResultCellWrap(e.department)),
        DataCell(buildResultCellWrap(e.perusahaan)),
        DataCell(Center(child: buildResultCell(formatTanggal(e.tanggal)))),
        DataCell(Center(child: buildResultCell(e.jumlahInspektor.toString()))),
        DataCell(
          Center(
            child: FotoButton(
              enabled: e.foto1.isNotEmpty && e.foto1 != "null",
              onTap: () {
                FotoPreviewDialogHelper(
                  context: context,
                ).showFoto(e.foto1, "Foto 1");
              },
            ),
          ),
        ),
        DataCell(
          Center(
            child: FotoButton(
              enabled: e.foto2.isNotEmpty && e.foto2 != "null",
              onTap: () {
                FotoPreviewDialogHelper(
                  context: context,
                ).showFoto(e.foto2, "Foto 2");
              },
            ),
          ),
        ),
        DataCell(
          Center(
            child: FotoButton(
              enabled: e.foto3.isNotEmpty && e.foto3 != "null",
              onTap: () {
                FotoPreviewDialogHelper(
                  context: context,
                ).showFoto(e.foto3, "Foto 3");
              },
            ),
          ),
        ),
        DataCell(
          Center(
            child: FotoButton(
              enabled: e.foto4.isNotEmpty && e.foto4 != "null",
              onTap: () {
                FotoPreviewDialogHelper(
                  context: context,
                ).showFoto(e.foto4, "Foto 4");
              },
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

  void showDetail(InspeksiMTDModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ResultDetailBottomSheet(
          title: "Detail Laporan Inspeksi CHP",
          onClose: () => Navigator.pop(context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildResultSectionTitle("Informasi Pelapor"),
              Row(
                children: [
                  Expanded(child: inspeksiFlatBox("Nama Lengkap", e.nama)),
                  const SizedBox(width: 12),
                  Expanded(child: inspeksiFlatBox("NRP", e.nrp)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: inspeksiFlatBox("Department", e.department)),
                  const SizedBox(width: 12),
                  Expanded(child: inspeksiFlatBox("Perusahaan", e.perusahaan)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: inspeksiFlatBox(
                      "Jumlah Inspektor",
                      e.jumlahInspektor.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: inspeksiFlatBox(
                      "Tanggal Kejadian",
                      formatTanggal(e.tanggal),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),

              buildResultSectionTitle("Kondisi Mess, Toilet dan Dapur"),
              inspeksiFlatBox(
                "Saluran Drainase Bersih / Tidak Tersumbat & Didisinfeksi",
                e.opsi1,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Lantai bersih dan didisinfeksi", e.opsi2),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Tidak ada lantai atau sambungan yang pecah",
                e.opsi3,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Dinding dan atap dalam kondisi bersih", e.opsi4),
              const SizedBox(height: 12),
              inspeksiFlatBox("Penerangan memadai", e.opsi5),
              const SizedBox(height: 12),
              inspeksiFlatBox("Ventilasi / Ekstraksi memadai", e.opsi6),
              const SizedBox(height: 12),
              inspeksiFlatBox("Kebersihan & Housekeeping yang baik", e.opsi7),
              const SizedBox(height: 12),
              inspeksiFlatBox("Cermin bersih & tidak pecah", e.opsi8),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Sabun mencukupi & disediakan disinfektan",
                e.opsi9,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Toilet bersih & didisinfeksi", e.opsi10),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Lembar Pemantauan Daerah Basah Up-to-Date",
                e.opsi11,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Tempat tidur / kamar bersih / rapih", e.opsi12),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Fans / Bagian bergerak lain diamankan",
                e.opsi13,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Lemari pendingin / kompor / tempat air minum / peralatan lain bersih & kondisi baik",
                e.opsi14,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Kotak listrik / saklar penggerak / sambungan kabel",
                e.opsi15,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Pentanahan disediakan", e.opsi16),
              const SizedBox(height: 12),
              inspeksiFlatBox("Instalasi gas terkompresi aman", e.opsi17),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Tempat penyiapan makanan yang mencukupi disediakan",
                e.opsi18,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Area penyiapan makanan bersih / didisifeksi & bebas serangga",
                e.opsi19,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Daerah penyimpanan makanan (Bersih / Bebas serangga)",
                e.opsi20,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Alat pelindung diri untuk Staf Dapur & pembersih",
                e.opsi21,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox("Bak cuci (wastafe) bersih", e.opsi22),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Pencegahan dan perlindungan kebakaran",
                e.opsi23,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 0.5),
              ),

              buildResultSectionTitle("Analisa & Tindak Lanjut"),
              inspeksiFlatBox(
                "Keterangan Hasil Temuan",
                e.ketHasil,
                isLongText: true,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Saran masuk terkait perbaikan temuan",
                e.saranMasuk,
                isLongText: true,
              ),
              const SizedBox(height: 12),
              inspeksiFlatBox(
                "Apakah inspeksi yang telah dilakukan sudah sesuai dapat dipertanggung jawabkan?",
                e.statusInspeksi,
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
