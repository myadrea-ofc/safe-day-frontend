import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_apps/models/hazard.dart';
import 'package:safety_apps/service/hazard_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HazardResultPage extends StatefulWidget {
  @override
  State<HazardResultPage> createState() => _HazardResultPageState();
}

class _HazardResultPageState extends State<HazardResultPage> {
  List<HazardModel> allData = [];
  List<HazardModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  // === THEME (Hazard - merah/orange) ===
  static const Color _primary = Color(0xffFF5F6D);
  static const Color _secondary = Color(0xffFF7A45);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  static const int _columnCount = 13;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  final LinearGradient primaryGradient = const LinearGradient(
    colors: [_secondary, _primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await HazardService.fetchHazard();
      if (!mounted) return;
      setState(() {
        allData = data;
        filtered = _searchResults(_searchCtrl.text);
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    }
  }

  List<HazardModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    // kalau kosong -> semua data (tanpa ranking)
    if (q.isEmpty) return List<HazardModel>.from(allData);

    // 1) filter contains
    final results = allData.where((e) {
      final nama = safeLower(e.nama);
      final perusahaan = safeLower(e.perusahaan);
      final dept = safeLower(e.department);

      return nama.contains(q) || perusahaan.contains(q) || dept.contains(q);
    }).toList();

    // 2) ranking
    int rankText(String text) {
      if (text.startsWith(q)) return 0;

      final wholeWord = RegExp(
        r'(^|[\s\W])' + RegExp.escape(q) + r'([\s\W]|$)',
      );
      if (wholeWord.hasMatch(text)) return 1;

      if (text.contains(q)) return 2;
      return 3;
    }

    int rankRow(HazardModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);

      final rn = rankText(n);
      final rp = rankText(p);
      final rd = rankText(d);

      return [rn, rp, rd].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(HazardModel e) {
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

  void onSearch(String v) {
    setState(() {
      filtered = _searchResults(v);
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

  List<HazardModel> get pageData {
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
                    "Hazard Results",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
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
                      onSearch(""); // ✅ reset pakai logic yang sama
                      setState(() {});
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
            Container(
              height: 60,
              decoration: BoxDecoration(gradient: primaryGradient),
            ),

            DataTable2(
              columnSpacing: 26,
              horizontalMargin: 16,
              minWidth: 3500,
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
                  label: Center(child: Text("ID Karyawan")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("Perusahaan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Jabatan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Lokasi Temuan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Status")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Dokumentasi 1")),
                  fixedWidth: 140,
                ),
                DataColumn2(
                  label: Center(child: Text("Dokumentasi 2")),
                  fixedWidth: 140,
                ),
                DataColumn2(
                  label: Center(child: Text("Dokumentasi 3")),
                  fixedWidth: 140,
                ),
                DataColumn2(
                  label: Center(child: Text("Detail")),
                  fixedWidth: 140,
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

  DataRow _rowPremium(HazardModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;

    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: MaterialStateProperty.all(bg),
      cells: [
        DataCell(cell(no.toString(), weight: FontWeight.w900)),
        DataCell(cellWrap(e.nama)),
        DataCell(cell(e.idKaryawan)),
        DataCell(cellWrap(e.perusahaan)),
        DataCell(cellWrap(e.jabatan)),
        DataCell(cellWrap(e.department)),
        DataCell(cellWrap(e.lokasiTemuan)),
        DataCell(Center(child: cell(formatTanggal(e.tanggal)))),
        DataCell(Center(child: _statusPill(e.statusSesuai))),

        // foto buttony (logic sama)
        DataCell(
          Center(
            child: _fotoButton(
              enabled:
                  (e.foto1_path ?? "").isNotEmpty && e.foto1_path != "null",
              onTap: () => showFoto(e.foto1_path, "Foto 1"),
            ),
          ),
        ),

        DataCell(
          Center(
            child: _fotoButton(
              enabled:
                  (e.foto2_path ?? "").isNotEmpty && e.foto2_path != "null",
              onTap: () => showFoto(e.foto2_path, "Foto 2"),
            ),
          ),
        ),

        DataCell(
          Center(
            child: _fotoButton(
              enabled:
                  (e.foto3_path ?? "").isNotEmpty && e.foto3_path != "null",
              onTap: () => showFoto(e.foto3_path, "Foto 3"),
            ),
          ),
        ),

        // detail button premium (pakai gradient hazard)
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

  Widget _fotoButton({required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primary.withOpacity(0.14)),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.image_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final s = status.toLowerCase().trim();

    Color c;
    if (s == "open") {
      c = const Color(0xfff59e0b); // amber
    } else if (s.isEmpty) {
      c = Colors.grey;
    } else {
      c = const Color(0xff16a34a); // green
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

  void showFoto(String? fileName, String title) {
    if (fileName == null || fileName.isEmpty || fileName == "null") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Foto $title tidak tersedia")));
      return;
    }

    Future<void> _downloadWithPopup({
      required String url,
      required String fileName,
    }) async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Mengunduh gambar..."),
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
          if (!status.isGranted) throw "Izin storage ditolak";

          // ✅ sama seperti LPI: masuk album Safe Day
          dir = Directory("/storage/emulated/0/Pictures/Safe Day");
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw "Download gagal";

        // ✅ aman kalau fileName dari server mengandung folder
        final name = fileName.split('/').last;
        final file = File("${dir.path}/$name");

        await file.writeAsBytes(response.bodyBytes);
        savedPath = file.path;

        // ✅ trigger agar muncul di Galeri & album Safe Day kebaca
        if (Platform.isAndroid) {
          await MediaScanner.loadMedia(path: savedPath);
          await MediaScanner.loadMedia(path: dir.path);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop(); // tutup loading

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Download gagal"),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "Download Berhasil",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  savedPath,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader("Preview $title"),
            Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  "http://safety.borneo.co.id/uploads/$fileName",
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      Text("Gagal memuat gambar"),
                    ],
                  ),
                ),
              ),
            ),
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
                    "Download Gambar",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);

                    await _downloadWithPopup(
                      url: "http://safety.borneo.co.id/uploads/$fileName",
                      fileName: fileName,
                    );
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

  void showDetail(HazardModel e) {
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
              // --- HANDLE BAR ---
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
                          colors: [Color(0xffFF7A45), Color(0xffFF5F6D)],
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
                      "Detail Laporan Hazard",
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
                      Row(
                        children: [
                          Expanded(child: _flatBox("Nama Lengkap", e.nama)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox("ID Karyawan", e.idKaryawan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _flatBox("Department", e.department)),
                          const SizedBox(width: 12),
                          Expanded(child: _flatBox("Jabatan", e.jabatan)),
                        ],
                      ),
                      SizedBox(height: 12),
                      _flatBox("Perusahaan", e.perusahaan),
                      SizedBox(height: 12),

                      _flatBox(
                        "Waktu Kejadian",
                        "${formatTanggal(e.tanggal)} | ${e.waktu}",
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),

                      _sectionTitle("Temuan"),
                      _flatBox("Lokasi Temuan", e.lokasiTemuan),
                      SizedBox(height: 12),
                      _flatBox("Jenis Temuan", e.jenisTemuan),
                      SizedBox(height: 12),
                      _flatBox(
                        "Sesuai Kondisi Lapangan",
                        e.statusSesuai,
                        isStatus: true,
                      ),
                      SizedBox(height: 12),
                      _flatBox("Narasi Temuan", e.narasiTemuan),
                      SizedBox(height: 12),
                      _flatBox(
                        "Info Tindak Lanjut Perbaikan ",
                        e.infoPerbaikan,
                      ),
                      SizedBox(height: 30),
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
                      colors: [Color(0xffFF7A45), Color(0xffFF5F6D)],
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
        shaderCallback: (bounds) => primaryGradient.createShader(bounds),
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
    String? value, {
    bool isLongText = false,
    bool isStatus = false,
    String? statusValue,
  }) {
    final safeValue = value ?? "-";

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
                      safeValue.isEmpty ? "-" : safeValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              : Text(
                  safeValue.isEmpty ? "-" : safeValue,
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
          colors: [Color(0xffFF7A45), Color(0xffFF5F6D)],
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

  Widget cellWrap(String? text) {
    final safeText = text ?? "-";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          safeText.isEmpty ? "-" : safeText,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }

  String formatTanggal(String? value) {
    if (value == null || value.isEmpty) return "-";

    try {
      final date = DateTime.parse(value);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (e) {
      return value;
    }
  }

  Widget cell(String? text, {FontWeight? weight}) {
    final safeText = text ?? "-";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: safeText,
          child: Text(
            safeText.isEmpty ? "-" : safeText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: weight),
          ),
        ),
      ),
    );
  }

  Future<void> downloadFoto(HazardModel e) async {
    final url = "http://safety.borneo.co.id/uploads/${e.foto1_path}";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> downloadFoto2(HazardModel e) async {
    final url = "http://safety.borneo.co.id/uploads/${e.foto2_path}";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> downloadFoto3(HazardModel e) async {
    final url = "http://safety.borneo.co.id/uploads/${e.foto3_path}";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
