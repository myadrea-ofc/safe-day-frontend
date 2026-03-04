import 'dart:io';
import 'dart:ui';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:safety_apps/models/p2h/p2h_compactor.dart';
import 'package:safety_apps/service/p2h/p2h_compactor_service.dart';

// ====== STATUS HELPER (konsisten) ======
String _norm(String? v) => (v ?? '').trim().toLowerCase();

enum _StatusKind { yes, no, ok, bad, warn, none }

_StatusKind _kind(String? v) {
  final t = _norm(v);

  if (t == "iya" || t == "ya" || t == "yes") return _StatusKind.yes;
  if (t == "tidak" || t == "no") return _StatusKind.no;

  if (t == "layak" || t == "baik" || t == "ok") return _StatusKind.ok;

  if (t == "ada & layak" || t == "ada dan layak") return _StatusKind.ok;
  if (t == "tidak berfungsi" || t == "rusak") return _StatusKind.warn;
  if (t == "tidak ada") return _StatusKind.bad;

  if (t == "n/a" || t == "na") return _StatusKind.warn;

  return _StatusKind.none;
}

Color _kBg(_StatusKind k) {
  switch (k) {
    case _StatusKind.yes:
    case _StatusKind.ok:
      return Colors.green.withOpacity(0.12);
    case _StatusKind.no:
    case _StatusKind.bad:
      return Colors.red.withOpacity(0.12);
    case _StatusKind.warn:
      return Colors.amber.withOpacity(0.18);
    case _StatusKind.none:
      return const Color(0xfff5f7fb);
  }
}

Color _kBorder(_StatusKind k) {
  switch (k) {
    case _StatusKind.yes:
    case _StatusKind.ok:
      return Colors.green.withOpacity(0.35);
    case _StatusKind.no:
    case _StatusKind.bad:
      return Colors.red.withOpacity(0.35);
    case _StatusKind.warn:
      return Colors.amber.withOpacity(0.45);
    case _StatusKind.none:
      return const Color(0xffe8ecf3);
  }
}

Color _kText(_StatusKind k) {
  switch (k) {
    case _StatusKind.yes:
    case _StatusKind.ok:
      return Colors.green.shade800;
    case _StatusKind.no:
    case _StatusKind.bad:
      return Colors.red.shade800;
    case _StatusKind.warn:
      return Colors.amber.shade900;
    case _StatusKind.none:
      return Colors.black;
  }
}

IconData _kIcon(_StatusKind k) {
  switch (k) {
    case _StatusKind.yes:
    case _StatusKind.ok:
      return Icons.check_circle_rounded;
    case _StatusKind.no:
    case _StatusKind.bad:
      return Icons.cancel_rounded;
    case _StatusKind.warn:
      return Icons.warning_amber_rounded;
    case _StatusKind.none:
      return Icons.info_outline;
  }
}

class P2HCompactorResultPage extends StatefulWidget {
  @override
  State<P2HCompactorResultPage> createState() => _P2HCompactorResultPageState();
}

class _P2HCompactorResultPageState extends State<P2HCompactorResultPage> {
  List<P2HCompactorModel> allData = [];
  List<P2HCompactorModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  final LinearGradient primaryGradient = const LinearGradient(
    colors: [_primary, _secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // kolom compactor: 13
  static const int _columnCount = 13;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  bool isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp') ||
        p.endsWith('.heic');
  }

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
    try {
      final data = await P2HCompactorService.fetchP2HCompactor();
      setState(() {
        allData = data;
        filtered = _searchResults(_searchCtrl.text);
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat data P2H Compactor: $e")),
      );
    }
  }

  // ===== SEARCH (contains + ranking) =====
  List<P2HCompactorModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();
    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<P2HCompactorModel>.from(allData);

    final results = allData.where((e) {
      final nama = safeLower(e.nama);
      final perusahaan = safeLower(e.perusahaan);
      final dept = safeLower(e.department);
      final jabatan = safeLower(e.jabatan);
      final nrp = safeLower(e.nrp);
      final unit = safeLower(e.noLambungUnit);
      final hm = safeLower(e.hmUnit);
      final lokasi = safeLower(e.lokasiKerja);

      return nama.contains(q) ||
          perusahaan.contains(q) ||
          dept.contains(q) ||
          jabatan.contains(q) ||
          nrp.contains(q) ||
          unit.contains(q) ||
          hm.contains(q) ||
          lokasi.contains(q);
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

    int rankRow(P2HCompactorModel e) {
      final fields = [
        safeLower(e.nama),
        safeLower(e.perusahaan),
        safeLower(e.department),
        safeLower(e.jabatan),
        safeLower(e.nrp),
        safeLower(e.noLambungUnit),
        safeLower(e.hmUnit),
        safeLower(e.lokasiKerja),
      ];
      return fields.map(rankText).reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(P2HCompactorModel e) {
      final fields = [
        safeLower(e.nama),
        safeLower(e.perusahaan),
        safeLower(e.department),
        safeLower(e.jabatan),
        safeLower(e.nrp),
        safeLower(e.noLambungUnit),
        safeLower(e.hmUnit),
        safeLower(e.lokasiKerja),
      ];
      int best = 1 << 30;
      for (final f in fields) {
        final i = f.indexOf(q);
        if (i >= 0 && i < best) best = i;
      }
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

  List<P2HCompactorModel> get pageData {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBarPremium(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _searchBoxPremium(),
                  const SizedBox(height: 16),
                  Expanded(child: _tablePremium()),
                  _paginationPremium(),
                ],
              ),
            ),
    );
  }

  // ===== APPBAR PREMIUM =====
  PreferredSizeWidget _appBarPremium() {
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
                    "P2H Compactor Results",
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

  // ===== SEARCH PREMIUM =====
  Widget _searchBoxPremium() {
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
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText:
                "Cari nama / perusahaan / department / jabatan / nrp / unit / lokasi …",
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
                      onSearch("");
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

  // ===== TABLE PREMIUM =====
  Widget _tablePremium() {
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
              minWidth: 5000,
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
                DataColumn2(label: Center(child: Text("NRP")), fixedWidth: 180),
                DataColumn2(
                  label: Center(child: Text("Jabatan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Perusahaan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("No Lambung Compactor")),
                  fixedWidth: 220,
                ),
                DataColumn2(
                  label: Center(child: Text("KM Compactor Saat ini")),
                  fixedWidth: 220,
                ),
                DataColumn2(
                  label: Center(child: Text("Shift Kerja")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("Siap Kerja")),
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

  DataRow _rowPremium(P2HCompactorModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;
    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    Widget docBtn() {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (e.files.isEmpty) return;
          _showFilesDialog(e.files);
        },
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
              Icons.attach_file_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    Widget _chip(Color base, IconData icon, String v) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: base.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: base.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: base),
            const SizedBox(width: 6),
            Text(
              v,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: base,
              ),
            ),
          ],
        ),
      );
    }

    // NOTE: tabel compactor pakai field statusSiap (bukan unitAman)
    Widget statusChip(String v) {
      if (_norm(v) == "open") {
        return _chip(Colors.orange, Icons.timelapse_rounded, v);
      }

      final k = _kind(v);
      if (k == _StatusKind.none) {
        return _chip(Colors.blueGrey, Icons.info_outline, v);
      }

      final base = (k == _StatusKind.yes || k == _StatusKind.ok)
          ? Colors.green
          : (k == _StatusKind.warn ? Colors.amber : Colors.red);

      return _chip(base, _kIcon(k), v);
    }

    return DataRow(
      color: MaterialStateProperty.all(bg),
      cells: [
        DataCell(cell(no.toString(), weight: FontWeight.w900)),
        DataCell(cellWrap(e.nama)),
        DataCell(cell(e.nrp)),
        DataCell(cellWrap(e.jabatan)),
        DataCell(cellWrap(e.department)),
        DataCell(cellWrap(e.perusahaan)),
        DataCell(Center(child: cell(formatTanggal(e.tanggal)))),
        DataCell(cellWrap(e.noLambungUnit)),
        DataCell(cellWrap(e.hmUnit)),
        // kolom label di table: "Shift Kerja", tapi data kamu memang e.lokasiKerja (jangan diubah)
        DataCell(cellWrap(e.lokasiKerja)),
        DataCell(Center(child: statusChip(e.statusSiap))),
        DataCell(Center(child: docBtn())),
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

  DataRow _emptyRow() {
    return DataRow(
      cells: List.generate(_columnCount, (_) => const DataCell(SizedBox())),
    );
  }

  // ===== PAGINATION PREMIUM =====
  Widget _paginationPremium() {
    final totalPage = _totalPage;
    final start = filtered.isEmpty ? 0 : (currentPage * rowsPerPage + 1);
    final end = (currentPage * rowsPerPage + pageData.length).clamp(
      0,
      filtered.length,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;

        final String topLeft = compact
            ? "Menampilkan $start–$end"
            : "Menampilkan data $start–$end";

        final String topRight = compact
            ? "Total: ${filtered.length}"
            : "Total data: ${filtered.length} • Halaman: ${currentPage + 1}/$totalPage";

        return Container(
          width: double.infinity,
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
              Row(
                children: [
                  _rowsPerPageControl(
                    compact: compact,
                    value: rowsPerPage,
                    onChanged: (v) {
                      setState(() {
                        rowsPerPage = v;
                        currentPage = 0;
                        _ensurePageValid();
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
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
              const SizedBox(height: 10),
              Text(
                compact
                    ? "Tip: gunakan pencarian untuk cepat menemukan data."
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

  // ===== helper responsive pair (detail) =====
  Widget _pair(
    BuildContext context,
    Widget a,
    Widget b, {
    double breakpoint = 520,
    double gap = 12,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final oneColumn = c.maxWidth < breakpoint;
        if (oneColumn) {
          return Column(
            children: [
              a,
              SizedBox(height: gap),
              b,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: a),
            SizedBox(width: gap),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  // ====== DETAIL (JANGAN UBAH LABEL & DATA) ======
  void showDetail(P2HCompactorModel e) {
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
                          colors: [_primary, _secondary],
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        "Detail Laporan P2H Compactor",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                      _pair(
                        context,
                        _flatBox("Nama Lengkap", e.nama),
                        _flatBox("NRP", e.nrp),
                      ),
                      const SizedBox(height: 12),
                      _flatBox("Perusahaan", e.perusahaan),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Department", e.department),
                        _flatBox("Jabatan", e.jabatan),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("No Lambung Compactor", e.noLambungUnit),
                        _flatBox("HM Unit", e.hmUnit),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox(
                          "Tanggal dan Waktu Kejadian",
                          formatTanggal(e.tanggal),
                        ),
                        _flatBox("Lokasi Kerja", e.lokasiKerja),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),
                      _sectionTitle("Item Pemeriksaan"),
                      _pair(
                        context,
                        _flatBox(
                          "Level Air Radiator, Minyak Rem dan Air Aki",
                          e.opsiItem1,
                        ),
                        _flatBox("Bocor Radiator atau Pipa Air", e.opsiItem2),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Level Minyak Rem", e.opsiItem3),
                        _flatBox("Level Air Aki", e.opsiItem4),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Oli Mesin", e.opsiItem5),
                        _flatBox("Bahan Bakar", e.opsiItem6),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Kondisi Wiper", e.opsiItem7),
                        _flatBox(
                          "Kondisi Rem (Kaki, Parkir & Emergency)",
                          e.opsiItem8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox(
                          "Kondisi Lampu Rotary, Stop, Depan, Belakang",
                          e.opsiItem9,
                        ),
                        _flatBox(
                          "Kondisi Lampu Body, Sen Kanan, Sen Kiri dan Bahaya",
                          e.opsiItem10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Alarm Mundur", e.opsiItem11),
                        _flatBox(
                          "Kondisi Kaca Depan, Belakang, Jendela & Spion",
                          e.opsiItem12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox(
                          "Cermin Pandang Belakang & Sisi",
                          e.opsiItem13,
                        ),
                        _flatBox(
                          "Keadaan Body, Kabin dan Kursi Operator",
                          e.opsiItem14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Suhu Mesin", e.opsiItem15),
                        _flatBox("Klakson", e.opsiItem16),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Uji rem Fisik", e.opsiItem17),
                        _flatBox("Reaksi Kemudi", e.opsiItem18),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Tuas Kemudi", e.opsiItem19),
                        _flatBox("Sistem Hidrolik", e.opsiItem20),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Mesin", e.opsiItem21),
                        _flatBox("Kondisi Vibrator", e.opsiItem22),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Sistem Elektrik", e.opsiItem23),
                        _flatBox("Instrumen Panel", e.opsiItem24),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Alat Pemadam Api", e.opsiItem25),
                        _flatBox("Kotak P3K", e.opsiItem26),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox("Sabuk Keselamatan", e.opsiItem27),
                        _flatBox("Radio Komunikasi", e.opsiItem28),
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox(
                          "No Lambung (Depan, Belakang, Kiri & Kanan Unit)",
                          e.opsiItem29,
                        ),
                        _flatBox("SIMPER", e.opsiItem30),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),
                      _sectionTitle("Standard Keselamatan - Alat Keselamatan"),
                      _flatBox(
                        "Safety Cone / Segitiga",
                        e.opsiStandarKeselamatan1,
                      ),
                      const SizedBox(height: 12),
                      _pair(
                        context,
                        _flatBox(
                          "APAR (Alat Pemadam Api Ringan)",
                          e.opsiStandarKeselamatan2,
                        ),
                        _flatBox("Kotak PK3", e.opsiStandarKeselamatan3),
                      ),
                      const SizedBox(height: 20),
                      _flatBox(
                        "Apakah anda memiliki Kimper yang masih berlaku",
                        e.kimperBerlaku,
                      ),
                      const SizedBox(height: 12),
                      _flatBox("Jam Tidur Anda", e.jamTidur),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),
                      _sectionTitle("Kondisi Pelapor"),
                      _flatBox(
                        "Apakah Anda sedang mengkonsumsi obat yang menyebabkan mengantuk",
                        e.statusKeadaan1,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah jam tidur anda cukup hari ini minimal 6 jam",
                        e.statusKeadaan2,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah Anda tidak ada permasalahan dengan keluarga yang mengganggu konsentrasi Anda",
                        e.statusKeadaan3,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah Anda memiliki masalah dengan atasan Anda",
                        e.statusKeadaan4,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah Anda merasa kurang konsentrasi hari ini",
                        e.statusKeadaan5,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah Anda merasa pandangan mata Anda letih",
                        e.statusKeadaan6,
                      ),
                      const SizedBox(height: 20),
                      _flatBox(
                        "Apakah Anda sudah siap untuk bekerja & telah menggunakan APD serta memiliki KIMPER sesuai unit yang Anda operasikan",
                        e.statusSiap,
                      ),
                      const SizedBox(height: 12),
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
                    gradient: primaryGradient,
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
        shaderCallback: (bounds) => primaryGradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
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

  // ===== flatBox (status-aware, tapi label/data tetap) =====
  Widget _flatBox(String label, String? value, {bool isLongText = false}) {
    final safeValue = (value ?? "-").trim();
    final k = _kind(value);
    final isStatusValue = k != _StatusKind.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isStatusValue ? _kBg(k) : const Color(0xfff5f7fb),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isStatusValue ? _kBorder(k) : const Color(0xffe8ecf3),
            ),
          ),
          child: isStatusValue
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        safeValue.isEmpty ? "-" : safeValue,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kText(k),
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kBorder(k).withOpacity(0.20),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder(k), width: 1.4),
                      ),
                      child: Icon(_kIcon(k), size: 18, color: _kText(k)),
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

  // ===== cells =====
  Widget cellWrap(String text) {
    final t = text.trim().isEmpty ? "-" : text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          t,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            height: 1.35,
            color: Colors.black.withOpacity(0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String formatTanggal(String value) {
    if (value.isEmpty) return "-";
    try {
      final date = DateTime.parse(value);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (_) {
      return value;
    }
  }

  Widget cell(String text, {FontWeight? weight}) {
    final t = text.trim().isEmpty ? "-" : text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: t,
          child: Text(
            t,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: weight ?? FontWeight.w700,
              color: Colors.black.withOpacity(0.72),
            ),
          ),
        ),
      ),
    );
  }

  // ===== FILES DIALOG (konsisten) =====
  void _showFilesDialog(List<String> files) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff9fafc),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.folder_open_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Dokumen Terlampir",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...files.map((file) {
                final isImg = isImageFile(file);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isImg
                              ? Colors.blue.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isImg
                              ? Icons.image_outlined
                              : Icons.picture_as_pdf_outlined,
                          color: isImg
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          file,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xff333333),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        tooltip: "Preview",
                        onPressed: () async {
                          Navigator.pop(context);
                          if (isImg) {
                            _previewImage(file);
                          } else {
                            await downloadAndOpenFile(
                              "http://safety.borneo.co.id/uploads/$file",
                              file,
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download_outlined,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        tooltip: "Download",
                        onPressed: () {
                          Navigator.pop(context);
                          downloadWithPopup(
                            context: context,
                            url: "http://safety.borneo.co.id/uploads/$file",
                            fileName: file,
                            isImage: isImg,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Tutup",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== preview (tetap) + guard =====
  void _previewImage(String file) {
    final controller = TransformationController();
    TapDownDetails? doubleTapDetails;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) {
        double dragOffset = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onVerticalDragUpdate: (details) {
                dragOffset += details.delta.dy;
                setState(() {});
              },
              onVerticalDragEnd: (_) {
                if (dragOffset.abs() > 120) {
                  Navigator.pop(context);
                } else {
                  setState(() => dragOffset = 0);
                }
              },
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                  Transform.translate(
                    offset: Offset(0, dragOffset),
                    child: Center(
                      child: Hero(
                        tag: file,
                        child: GestureDetector(
                          onDoubleTapDown: (details) =>
                              doubleTapDetails = details,
                          onDoubleTap: () {
                            if (doubleTapDetails == null) return;
                            final position = doubleTapDetails!.localPosition;

                            if (controller.value != Matrix4.identity()) {
                              controller.value = Matrix4.identity();
                            } else {
                              controller.value = Matrix4.identity()
                                ..translate(-position.dx * 2, -position.dy * 2)
                                ..scale(3.0);
                            }
                          },
                          child: InteractiveViewer(
                            transformationController: controller,
                            minScale: 1,
                            maxScale: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                "http://safety.borneo.co.id/uploads/$file",
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    height: 300,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Text(
                                      "Gagal memuat gambar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      Directory dir;

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw "Izin penyimpanan ditolak";
        dir = Directory("/storage/emulated/0/Download");
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) await dir.create(recursive: true);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw "Gagal mengunduh file";

      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(response.bodyBytes);

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) throw result.message;
    } catch (e) {
      if (!mounted) return;
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

  void _showDownloadProgressDialog(
    BuildContext context,
    ValueNotifier<String> text,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 16),
                ValueListenableBuilder<String>(
                  valueListenable: text,
                  builder: (_, value, __) =>
                      Text(value, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDownloadSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Download Berhasil",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  filePath,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> downloadWithPopup({
    required BuildContext context,
    required String url,
    required String fileName,
    bool isImage = false,
  }) async {
    final progressText = ValueNotifier("Menyiapkan unduhan...");
    _showDownloadProgressDialog(context, progressText);

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Navigator.pop(context);
          return;
        }
      }

      progressText.value = "Mengunduh file...";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw "Gagal download";

      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory(
          isImage
              ? "/storage/emulated/0/Pictures/Safe Day"
              : "/storage/emulated/0/Download",
        );
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) await dir.create(recursive: true);

      final safeName = fileName.split('/').last;
      final filePath = "${dir.path}/$safeName";
      final file = File(filePath);

      progressText.value = "Menyimpan file...";
      await file.writeAsBytes(response.bodyBytes);

      if (Platform.isAndroid && isImage) {
        await MediaScanner.loadMedia(path: filePath);
        await MediaScanner.loadMedia(path: dir.path);
      }

      Navigator.pop(context);
      _showDownloadSuccessDialog(context, filePath);
    } catch (e) {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download gagal: $e")));
    }
  }
}
