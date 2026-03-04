import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_apps/models/inspeksi/inspeksi_plant.dart';
import 'package:safety_apps/service/inspeksi/inspeksi_plant_service.dart';

class InspeksiPlantResultPage extends StatefulWidget {
  @override
  State<InspeksiPlantResultPage> createState() =>
      _InspeksiPlantResultPageState();
}

class _InspeksiPlantResultPageState extends State<InspeksiPlantResultPage> {
  List<InspeksiPlantModel> allData = [];
  List<InspeksiPlantModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  // ====== THEME (PERSIS CHP PREMIUM) ======
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  static const int _columnCount = 12;

  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  final LinearGradient primaryGradient = const LinearGradient(
    colors: [_primary, _secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      final data = await InspeksiPlantService.fetchInspeksiPlant();
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
        SnackBar(content: Text("Gagal memuat data inspeksi plant: $e")),
      );
    }
  }

  // ====== SEARCH (PERSIS CHP PREMIUM) ======
  List<InspeksiPlantModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<InspeksiPlantModel>.from(allData);

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

    int rankRow(InspeksiPlantModel e) {
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

    int firstIndexRow(InspeksiPlantModel e) {
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

  void onSearch(String v) {
    setState(() {
      filtered = _searchResults(v);
      currentPage = 0;
      _ensurePageValid();
    });
  }

  List<InspeksiPlantModel> get pageData {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPage =>
      (filtered.length / rowsPerPage).ceil().clamp(1, 1 << 30);

  void _ensurePageValid() {
    final tp = _totalPage;
    if (currentPage >= tp) currentPage = tp - 1;
    if (currentPage < 0) currentPage = 0;
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

  // ====== APPBAR (PERSIS CHP PREMIUM) ======
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
                    "Inspeksi Plant Results",
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

  // ====== SEARCHBOX (PERSIS CHP PREMIUM) ======
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
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: "Cari nama / nrp / perusahaan / department …",
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

  // ====== TABLE (PERSIS CHP PREMIUM) ======
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
              minWidth: 4200,
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
                  fixedWidth: 280,
                ),
                DataColumn2(label: Center(child: Text("NRP")), fixedWidth: 140),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Perusahaan")),
                  fixedWidth: 220,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal Inspeksi")),
                  fixedWidth: 160,
                ),
                DataColumn2(
                  label: Center(child: Text("Jml Inspektor")),
                  fixedWidth: 170,
                ),
                DataColumn2(
                  label: Center(child: Text("Temuan 1")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Temuan 2")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Temuan 3")),
                  fixedWidth: 130,
                ),
                DataColumn2(
                  label: Center(child: Text("Temuan 4")),
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

  DataRow _rowPremium(InspeksiPlantModel e, int index) {
    final no = currentPage * rowsPerPage + index + 1;

    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    Widget fotoBtn(String? fileName, String title) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showFoto(fileName, title),
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
      );
    }

    return DataRow(
      color: MaterialStateProperty.all(bg),
      cells: [
        DataCell(cell(no.toString(), weight: FontWeight.w900)),
        DataCell(cellWrap(e.nama)),
        DataCell(cell(e.nrp)),
        DataCell(cellWrap(e.department)),
        DataCell(cellWrap(e.perusahaan)),
        DataCell(Center(child: cell(formatTanggal(e.tanggal)))),
        DataCell(Center(child: cell(e.jumlahInspektor.toString()))),
        DataCell(Center(child: fotoBtn(e.foto1, "Foto 1"))),
        DataCell(Center(child: fotoBtn(e.foto2, "Foto 2"))),
        DataCell(Center(child: fotoBtn(e.foto3, "Foto 3"))),
        DataCell(Center(child: fotoBtn(e.foto4, "Foto 4"))),
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

  // ====== PAGINATION (PERSIS CHP PREMIUM) ======
  Widget _pagination() {
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

  // ====== FOTO (LOGIC SAMA, STYLE PERSIS CHP PREMIUM) ======
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

          dir = Directory("/storage/emulated/0/Pictures/Safe Day");
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (!await dir.exists()) await dir.create(recursive: true);

        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw "Download gagal";

        final name = fileName.split('/').last;
        final file = File("${dir.path}/$name");

        await file.writeAsBytes(response.bodyBytes);
        savedPath = file.path;

        if (Platform.isAndroid) {
          await MediaScanner.loadMedia(path: savedPath);
          await MediaScanner.loadMedia(path: dir.path);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();

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

      Navigator.of(context, rootNavigator: true).pop();

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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

  // ====== DETAIL (STYLE PERSIS CHP PREMIUM, ISI PLANT PUNYA KAMU) ======
  void showDetail(InspeksiPlantModel e) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: primaryGradient,
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
                        "Detail Laporan Inspeksi Plant",
                        softWrap: true,
                        overflow: TextOverflow.visible,
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
                      Row(
                        children: [
                          Expanded(child: _flatBox("Nama Lengkap", e.nama)),
                          const SizedBox(width: 12),
                          Expanded(child: _flatBox("NRP", e.nrp)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _flatBox("Department", e.department)),
                          const SizedBox(width: 12),
                          Expanded(child: _flatBox("Perusahaan", e.perusahaan)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _flatBox(
                              "Jumlah Inspektor",
                              e.jumlahInspektor.toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox(
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

                      _sectionTitle("Kondisi Plant"),
                      _flatBox(
                        "Praktek penumpukan & penyimpangan tertata dengan baik",
                        e.opsi1,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Furnitur Kantor & Ergonomi dalam kondisi baik",
                        e.opsi2,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Struktur : Atap, dinding, pintu, jendela, lantai, dll dalam kondisi baik",
                        e.opsi3,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Daerah berjalan / daerah bekerja tersedia demarkasi",
                        e.opsi4,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Toilet & kamar ganti bersih dan dilakukan perawatan",
                        e.opsi5,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Penerangan / ventilasi / Sistem Ekstraksi memadai dan cukup",
                        e.opsi6,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Housekeeping dilakukan dengan baik & kebersihan umum dilakukan secara rutin",
                        e.opsi7,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Rambu-rambu tanda & kode warna tersedia dan dipasang diarea kerja",
                        e.opsi8,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Jalan dan parkir mencukupi / kondisi baik dan rapi (Parkir Mundur)",
                        e.opsi9,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Pengamanan mesin dan penutup dilaksanakan",
                        e.opsi10,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Alat-alat lock out / Danger Tag tersedia dan karyawan melakukan LOTO setiap servis",
                        e.opsi11,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Pengaturan peralatan listrik termasuk Grounding sistem tersedia",
                        e.opsi12,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Pipa, Keran dan katup (Tidak ada kebocoran)",
                        e.opsi13,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Stairs / Platforms / Elevated Walkways / Handrails tersedia dan dilakukan pemeriksaan",
                        e.opsi14,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Overhead Cranes / Slings / Alat Angkat tersedia dan telah tersedia",
                        e.opsi15,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Penyimpanan silinder gas terkompresi / peralatan obor",
                        e.opsi16,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Penyimpanan dan Pengendalian bahan kimia berbahaya & beracun",
                        e.opsi17,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Perkakas tangan dan peralatan telah tersedia",
                        e.opsi18,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Inspeksi P2H & kondisi kendaraan dilaksanakan",
                        e.opsi19,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Alat Pelindung Diri digunakan ditempat kerja",
                        e.opsi20,
                      ),
                      const SizedBox(height: 12),
                      _flatBox("Tabir Las dipakai", e.opsi21),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Tempat sampah mencukupi / dikosongkan secara berkala",
                        e.opsi22,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Sistem peringatan pergerakan (klakson / alarm) digunakan",
                        e.opsi23,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Perlindungan dan pencegahan kebakaran tersedia (APAR, Hydrant)",
                        e.opsi24,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Tempat berkumpul darurat dan alarm tersedia dan berfungsi",
                        e.opsi25,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Peralatan pertolongan pertama tersedia dan tercukupi",
                        e.opsi26,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),

                      _sectionTitle("Analisa & Tindak Lanjut"),
                      _flatBox(
                        "Keterangan Hasil Temuan",
                        e.ketHasil,
                        isLongText: true,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Saran masuk terkait perbaikan temuan",
                        e.saranMasuk,
                        isLongText: true,
                      ),
                      const SizedBox(height: 12),
                      _flatBox(
                        "Apakah inspeksi yang telah dilakukan sudah sesuai dapat dipertanggung jawabkan?",
                        e.statusInspeksi,
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

  // ====== HELPERS (PERSIS CHP PREMIUM) ======
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

  bool _isYesNoValue(String? v) {
    if (v == null) return false;
    final t = v.toLowerCase().trim();
    return t == "iya" ||
        t == "tidak" ||
        t == "n/a" ||
        t == "na" ||
        t == "yes" ||
        t == "ya" ||
        t == "no";
  }

  Color _statusBg(String? v) {
    final t = (v ?? "").toLowerCase().trim();

    if (t == "ya" || t == "yes") {
      return Colors.green.withOpacity(0.12);
    } else if (t == "iya" || t == "yes") {
      return Colors.green.withOpacity(0.12);
    } else if (t == "tidak" || t == "no") {
      return Colors.red.withOpacity(0.12);
    } else if (t == "n/a" || t == "na") {
      return Colors.amber.withOpacity(0.18);
    }

    return const Color(0xfff5f7fb); // default biru muda lama
  }

  Color _statusBorder(String? v) {
    final t = (v ?? "").toLowerCase().trim();

    if (t == "ya" || t == "yes") {
      return Colors.green.withOpacity(0.35);
    } else if (t == "iya" || t == "yes") {
      return Colors.green.withOpacity(0.35);
    } else if (t == "tidak" || t == "no") {
      return Colors.red.withOpacity(0.35);
    } else if (t == "n/a" || t == "na") {
      return Colors.amber.withOpacity(0.45);
    }

    return const Color(0xffe8ecf3);
  }

  Color _statusText(String? v) {
    final t = (v ?? "").toLowerCase().trim();

    if (t == "ya" || t == "yes") {
      return Colors.green.shade800;
    } else if (t == "iya" || t == "yes") {
      return Colors.green.shade800;
    } else if (t == "tidak" || t == "no") {
      return Colors.red.shade800;
    } else if (t == "n/a" || t == "na") {
      return Colors.amber.shade900;
    }

    return Colors.black;
  }

  IconData _statusIcon(String? v) {
    final t = (v ?? "").toLowerCase().trim();
    if (t == "ya" || t == "yes") return Icons.check_circle_rounded;
    if (t == "iya" || t == "yes") return Icons.check_circle_rounded;
    if (t == "tidak" || t == "no") return Icons.cancel_rounded;
    if (t == "n/a" || t == "na") return Icons.warning_amber_rounded;
    return Icons.info_outline;
  }

  Widget _flatBox(String label, String? value, {bool isLongText = false}) {
    final safeValue = (value ?? "-").trim();
    final isStatusValue = _isYesNoValue(value);

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
            color: isStatusValue ? _statusBg(value) : const Color(0xfff5f7fb),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isStatusValue
                  ? _statusBorder(value)
                  : const Color(0xffe8ecf3),
            ),
          ),
          child: isStatusValue
              ? Row(
                  children: [
                    // TEXT (kiri)
                    Expanded(
                      child: Text(
                        safeValue.isEmpty ? "-" : safeValue,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _statusText(value),
                          height: 1.25,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ICON BULAT (kanan)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _statusBorder(value).withOpacity(0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _statusBorder(value),
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        _statusIcon(value),
                        size: 18,
                        color: _statusText(value),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget cellWrap(String? text) {
    final safeText = text ?? "-";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          safeText.isEmpty ? "-" : safeText,
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

  String formatTanggal(String? value) {
    if (value == null || value.isEmpty) return "-";
    try {
      final date = DateTime.parse(value);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (_) {
      return value;
    }
  }

  Widget cell(String? text, {FontWeight? weight}) {
    final safeText = text ?? "-";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: safeText,
          child: Text(
            safeText.isEmpty ? "-" : safeText,
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
}
