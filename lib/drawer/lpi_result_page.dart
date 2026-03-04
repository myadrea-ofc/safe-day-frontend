import 'dart:io';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_apps/models/lpi.dart';
import 'package:safety_apps/service/lpi_service.dart';

class LPIResultPage extends StatefulWidget {
  final int? openDetailId;
  const LPIResultPage({super.key, this.openDetailId});

  @override
  State<LPIResultPage> createState() => _LPIResultPageState();
}

class _LPIResultPageState extends State<LPIResultPage> {
  List<LPIModel> allData = [];
  List<LPIModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  int _currentDownload = 0;
  int _totalDownload = 0;

  VoidCallback? _updateProgressDialog;

  // === THEME (samakan dengan P5M) ===
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  static const int _columnCount = 10;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  // keep gradient (biar theme konsisten)
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [_primary, _secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  bool _openedFromNotif = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final data = await LPIService.fetchLPI();
    if (!mounted) return;

    setState(() {
      allData = data;
      loading = false;
      _ensurePageValid();
    });

    if (_hasQuery) {
      onSearch(_searchCtrl.text);
    } else {
      setState(() => filtered = List<LPIModel>.from(allData));
    }

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
  }

  void onSearch(String v) {
    final q = v.toLowerCase().trim();

    String _safeLower(String? v) => (v ?? "").toLowerCase().trim();

    // kalau kosong -> balik ke semua data, reset page
    if (q.isEmpty) {
      setState(() {
        filtered = List<LPIModel>.from(allData);
        currentPage = 0;
      });
      return;
    }

    // 1) filter dulu pakai contains (lebih UX dari startsWith)
    List<LPIModel> results = allData.where((e) {
      final nama = _safeLower(e.nama);
      final perusahaan = _safeLower(e.perusahaan);
      final dept = _safeLower(e.department);

      return nama.contains(q) || perusahaan.contains(q) || dept.contains(q);
    }).toList();

    // 2) ranking persis seperti filteredUsers
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
      final n = e.nama.toLowerCase();
      final p = e.perusahaan.toLowerCase();
      final d = e.department.toLowerCase();

      final rn = rankText(n);
      final rp = rankText(p);
      final rd = rankText(d);

      // ambil rank terbaik dari 3 field
      return [rn, rp, rd].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(LPIModel e) {
      final n = e.nama.toLowerCase();
      final p = e.perusahaan.toLowerCase();
      final d = e.department.toLowerCase();

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

      // tie-breaker terakhir: alfabet by nama
      return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
    });

    setState(() {
      filtered = results;
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
      backgroundColor: _bg,
      appBar: _appBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _searchBox(),
                  const SizedBox(height: 16),
                  Expanded(child: _table()),
                  _pagination(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: Container(
        decoration: BoxDecoration(
          gradient: primaryGradient,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.24),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "LPI Results",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                // pill info count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${filtered.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: TextField(
          controller: _searchCtrl,
          onChanged: onSearch, // ✅ logic tetap
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: "Cari nama / perusahaan / department …",
            hintStyle: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 64),
            suffixIcon: !_hasQuery
                ? null
                : IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      onSearch(""); // ✅ logic tetap (reset)
                      setState(() {}); // UI refresh
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
            filled: true,
            fillColor: _surface,
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
        ),
      ),
    );
  }

  Widget _table() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // header glow
            Container(
              height: 60,
              decoration: BoxDecoration(gradient: primaryGradient),
            ),

            DataTable2(
              columnSpacing: 26,
              horizontalMargin: 16,
              minWidth: 3500, // ✅ sama seperti existing kamu
              fixedTopRows: 1,
              headingRowHeight: 60,
              dataRowHeight: 66,

              headingRowColor: MaterialStateProperty.all(
                const Color.fromRGBO(0, 0, 0, 0),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
                letterSpacing: 0.2,
              ),
              dividerThickness: 0.6,

              columns: const [
                DataColumn2(label: Center(child: Text("No")), fixedWidth: 90),
                DataColumn2(
                  label: Center(child: Text("Nama")),
                  fixedWidth: 300,
                ),
                DataColumn2(
                  label: Center(child: Text("Perusahaan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal")),
                  fixedWidth: 140,
                ),
                DataColumn2(
                  label: Center(child: Text("Klasifikasi")),
                  fixedWidth: 300,
                ),
                DataColumn2(
                  label: Center(child: Text("Status")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Foto")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Dokumen")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Detail")),
                  fixedWidth: 130,
                ),
              ],

              rows: [
                ...List.generate(
                  pageData.length,
                  (i) => _rowPremium(pageData[i], i),
                ),
                ...List.generate(
                  rowsPerPage - pageData.length,
                  (_) => _emptyRow(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataRow _rowPremium(LPIModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;

    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: MaterialStateProperty.all(bg),
      cells: [
        DataCell(cell(no.toString(), weight: FontWeight.w900)),
        DataCell(cell(e.nama)),
        DataCell(cellWrap(e.perusahaan)),
        DataCell(cellWrap(e.department)),
        DataCell(Center(child: cell(formatTanggal(e.tanggal)))),

        DataCell(cellWrap(e.klasifikasi)),

        // status pill premium (UI only)
        DataCell(Center(child: _statusPill(e.statusLokasi))),

        // foto jadi buttony (logic sama)
        DataCell(
          Center(
            child: e.fotoPaths.isEmpty
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => showFotoGallery(e), // ✅ logic sama
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withOpacity(0.14)),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            primaryGradient.createShader(bounds),
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

        // dokumen jadi buttony (logic sama)
        DataCell(
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                showFilePreviewDialog(
                  context: context,
                  fileUrl: "http://safety.borneo.co.id/uploads/${e.filePath}",
                  fileName: e.filePath,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.14)),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ),

        // detail button premium (logic sama)
        DataCell(
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showDetail(e), // ✅ logic sama
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.22),
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

  Widget _statusPill(String status) {
    final s = status.toLowerCase().trim();

    Color c;
    if (s == "open") {
      c = const Color(0xfff59e0b); // amber modern
    } else if (s.isEmpty) {
      c = Colors.grey;
    } else {
      c = const Color(0xff16a34a); // green modern
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status.isEmpty ? "-" : status,
            style: TextStyle(
              color: Colors.black.withOpacity(0.70),
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  DataRow _emptyRow() {
    return DataRow(
      cells: List.generate(_columnCount, (_) => const DataCell(SizedBox())),
    );
  }

  Widget _pagination() {
    final totalPage = (filtered.length / rowsPerPage).ceil().clamp(1, 1 << 30);

    final start = filtered.isEmpty ? 0 : (currentPage * rowsPerPage + 1);
    final end = (currentPage * rowsPerPage + pageData.length).clamp(
      0,
      filtered.length,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;

        // teks dibuat lebih “berisi”
        final String topLeft = compact
            ? "Menampilkan $start–$end"
            : "Menampilkan data $start–$end";

        final String topRight = compact
            ? "Total: ${filtered.length}"
            : "Total data: ${filtered.length} • Halaman: ${currentPage + 1}/$totalPage";

        return Container(
          width: double.infinity, // ✅ full
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Baris 1: Info (kiri & kanan) =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topLeft,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.60),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    topRight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.45),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Baris 2: Controls (kiri rows, kanan pagination) =====
              Row(
                children: [
                  // kiri: rows selector (compact jadi chip kecil)
                  _rowsPerPageControl(
                    compact: compact,
                    value: rowsPerPage,
                    onChanged: (v) {
                      setState(() {
                        rowsPerPage = v;
                        currentPage = 0;
                        _ensurePageValid();
                      });
                      FocusScope.of(context).unfocus(); // opsional
                    },
                  ),

                  const SizedBox(width: 12),

                  // spacer fleksibel biar kanan nempel ujung dan tetap rapi
                  const Spacer(),

                  // kanan: pagination control (wrap biar aman kalau sempit)
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _pageIcon(
                        enabled: currentPage > 0,
                        icon: Icons.chevron_left_rounded,
                        onTap: () => setState(() {
                          currentPage--;
                          _ensurePageValid();
                        }),
                      ),

                      // page pill premium + anti overflow
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: compact ? 150 : 220,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _primary.withOpacity(0.14)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            compact
                                ? "${currentPage + 1} / $totalPage"
                                : "Page ${currentPage + 1} / $totalPage",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withOpacity(0.72),
                            ),
                          ),
                        ),
                      ),

                      _pageIcon(
                        enabled: currentPage + 1 < totalPage,
                        icon: Icons.chevron_right_rounded,
                        onTap: () => setState(() {
                          currentPage++;
                          _ensurePageValid();
                        }),
                      ),
                    ],
                  ),
                ],
              ),

              // ===== Caption kecil biar tidak terlihat kosong =====
              const SizedBox(height: 10),
              Text(
                compact
                    ? "Tip: ubah jumlah baris untuk mempercepat pencarian."
                    : "Tip: atur jumlah baris (10/25/50) agar navigasi lebih nyaman.",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.38),
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rowsPerPageControl({
    required bool compact,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final items = const [10, 25, 50];

    // style chip/pill
    BoxDecoration deco() => BoxDecoration(
      color: _primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _primary.withOpacity(0.14)),
    );

    TextStyle tStyle() => TextStyle(
      fontWeight: FontWeight.w900,
      color: Colors.black.withOpacity(0.70),
    );

    if (compact) {
      // ===== compact: ikon kecil (angka + chevron) =====
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: deco(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isDense: true,
            icon: Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Colors.black.withOpacity(0.55),
            ),
            items: items
                .map(
                  (v) => DropdownMenuItem<int>(
                    value: v,
                    child: Text("$v", style: tStyle()),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
          ),
        ),
      );
    }

    // ===== non-compact: label + dropdown biar jelas =====
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: deco(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Rows",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: Colors.black.withOpacity(0.55),
              ),
              items: items
                  .map(
                    (v) => DropdownMenuItem<int>(
                      value: v,
                      child: Text("$v", style: tStyle()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIcon({
    required bool enabled,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled
                ? _primary.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? _primary.withOpacity(0.14)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Icon(icon, color: Colors.black.withOpacity(0.65)),
        ),
      ),
    );
  }

  void showFotoGallery(LPIModel e) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader("Foto Kejadian (${e.fotoPaths.length})"),

            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: e.fotoPaths.length,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (_, i) {
                  final path = e.fotoPaths[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        "http://safety.borneo.co.id/uploads/$path",
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text("Gagal memuat foto")),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "Download Semua Foto",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await downloadAllFoto(e);
                  },
                ),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void showFilePreviewDialog({
    required BuildContext context,
    required String fileUrl,
    required String fileName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: const Center(
                  child: Text(
                    "Dokumen Lampiran",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text(
                      "Lihat Dokumen",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _downloadAndOpen(fileUrl, fileName);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Download Dokumen"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadWithPopup(
                        url: fileUrl,
                        fileName: fileName,
                        isImage: false,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadAndOpen(String url, String fileName) async {
    try {
      Directory dir;

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw "Izin penyimpanan ditolak";
        }
        dir = Directory("/storage/emulated/0/Download");
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw "Gagal mengunduh file";
      }

      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(response.bodyBytes);

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw result.message;
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Gagal membuka file"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadWithPopup({
    required String url,
    required String fileName,
    bool isImage = false,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Mengunduh..."),
            ],
          ),
        ),
      ),
    );

    String savedPath = "";

    try {
      Directory dir;
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw "Izin penyimpanan ditolak";
        dir = Directory(
          isImage
              ? "/storage/emulated/0/Pictures/Safe Day"
              : "/storage/emulated/0/Documents",
        );
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) await dir.create(recursive: true);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw "Gagal download file";

      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(response.bodyBytes);
      savedPath = file.path;

      if (Platform.isAndroid && isImage) {
        await MediaScanner.loadMedia(path: savedPath);
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // tutup loading

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(); // tutup loading

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Download Berhasil!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                savedPath,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> downloadAllFoto(LPIModel e) async {
    _currentDownload = 0;
    _totalDownload = e.fotoPaths.length;

    if (_totalDownload == 0) return;

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin penyimpanan ditolak")),
        );
        return;
      }
    }

    Directory dir = Directory("/storage/emulated/0/Pictures/Safe Day");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _showProgressDialog();

    try {
      for (int i = 0; i < e.fotoPaths.length; i++) {
        final foto = e.fotoPaths[i];

        final response = await http.get(
          Uri.parse("http://safety.borneo.co.id/uploads/$foto"),
        );

        if (response.statusCode != 200) {
          throw "Gagal download $foto";
        }

        final name = foto.split('/').last; // ✅ pastikan cuma nama file
        final file = File(
          "${dir.path}/$name",
        ); // ✅ jangan pakai path dari server
        await file.writeAsBytes(response.bodyBytes);

        if (Platform.isAndroid) {
          await MediaScanner.loadMedia(path: file.path);
        }

        _currentDownload = i + 1;
        _updateProgressDialog?.call();
      }

      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: dir.path);
      }

      Navigator.of(context).pop();
      _showSuccessDialog(dir.path);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal download: $e")));
    }
  }

  void _showSuccessDialog(String folderPath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Download Berhasil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                folderPath,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _updateProgressDialog = () {
              setStateDialog(() {});
            };

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      "Mengunduh $_currentDownload / $_totalDownload foto",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showDetail(LPIModel e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "Detail Laporan LPI",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Informasi Pelapor"),
                      _flatBox("Nama Lengkap", e.nama),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _flatBox("Perusahaan", e.perusahaan)),
                          const SizedBox(width: 12),
                          Expanded(child: _flatBox("Department", e.department)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Waktu Kejadian",
                        "${formatTanggal(e.tanggal)} | ${e.waktu}",
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),

                      _sectionTitle("Korban & Supervisor"),
                      _flatBox("Nama Korban", e.namaKorban),
                      const SizedBox(height: 12),
                      _flatBox("Jabatan", e.jabatanKorban),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _flatBox("Supervisor", e.namaSpv)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox(
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

                      _sectionTitle("Detail Insiden"),
                      _flatBox("Klasifikasi", e.klasifikasi),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _flatBox("Jenis Aset", e.jenisAset)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox(
                              "Status Lokasi",
                              e.statusLokasi,
                              isStatus: true,
                              statusValue: e.statusLokasi,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Kronologi Kejadian",
                        e.kronologi,
                        isLongText: true,
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Tutup",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _flatBox(
    String label,
    String value, {
    bool isLongText = false,
    bool isStatus = false,
    String? statusValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xfff5f7fb), // Abu-abu kebiruan sangat muda
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe8ecf3)),
          ),
          child: isStatus
              ? Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusValue?.toLowerCase() == "open"
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value.isEmpty ? "-" : value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              : Text(
                  value.isEmpty ? "-" : value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                    height: isLongText ? 1.5 : 1.2,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _dialogHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget cellWrap(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          text.isEmpty ? "-" : text,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(height: 1.5),
        ),
      ),
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

  Widget cell(String text, {FontWeight? weight}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: text,
          child: Text(
            text.isEmpty ? "-" : text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: weight),
          ),
        ),
      ),
    );
  }
}
