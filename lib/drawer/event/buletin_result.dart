import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/models/events/buletin_review.dart';
import 'package:safety_apps/service/event/buletin_service.dart';

class BuletinResultPage extends StatefulWidget {
  @override
  State<BuletinResultPage> createState() => _BuletinResultPageState();
}

class _BuletinResultPageState extends State<BuletinResultPage> {
  List<BuletinReview> allData = [];
  List<BuletinReview> filtered = [];

  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  // ====== THEME (samakan feel seperti HazardResult, tapi pakai warna buletin) ======
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  // (boleh tetap hijau-ungu agar konsisten buletin, tapi style Hazard)
  static const Color _primary = Color(0xffA855F7); // purple-ish
  static const Color _secondary = Color(0xff34D399); // green-ish

  static const int _columnCount = 10;

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
      setState(() => loading = true);

      final data = await HSESBuletinService.fetchAdminTable();
      debugPrint("TOTAL REVIEW: ${data.length}");

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

  // ====== SEARCH (tidak ubah data/label, hanya dibuat setara Hazard: contains + ranking) ======
  List<BuletinReview> _searchResults(String v) {
    final q = v.toLowerCase().trim();
    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    if (q.isEmpty) return List<BuletinReview>.from(allData);

    final results = allData.where((e) {
      final comment = safeLower(e.comment);
      final userName = safeLower(e.userName);
      final departmentName = safeLower(e.departmentName);
      final siteName = safeLower(e.siteName);
      final buletinTitle = safeLower(e.buletinTitle);
      final reviewerRole = safeLower(e.reviewerRole);

      return comment.contains(q) ||
          userName.contains(q) ||
          departmentName.contains(q) ||
          siteName.contains(q) ||
          buletinTitle.contains(q) ||
          reviewerRole.contains(q);
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

    int rankRow(BuletinReview e) {
      final fields = <String>[
        safeLower(e.userName),
        safeLower(e.comment),
        safeLower(e.departmentName),
        safeLower(e.siteName),
        safeLower(e.buletinTitle),
        safeLower(e.reviewerRole),
      ];

      return fields.map(rankText).reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(BuletinReview e) {
      final fields = <String>[
        safeLower(e.userName),
        safeLower(e.comment),
        safeLower(e.departmentName),
        safeLower(e.siteName),
        safeLower(e.buletinTitle),
        safeLower(e.reviewerRole),
      ];

      int best = 1 << 30;
      for (final f in fields) {
        final idx = f.indexOf(q);
        if (idx >= 0) best = idx < best ? idx : best;
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

      return safeLower(a.userName).compareTo(safeLower(b.userName));
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

  List<BuletinReview> get pageData {
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

  // ====== APPBAR (samakan Hazard: custom container + back + title + counter) ======
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
                    "Review Buletin",
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

  // ====== SEARCH BOX (samakan Hazard: card + gradient icon + clear) ======
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
            hintText: "Cari nama / komentar …",
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

  // ====== TABLE (samakan Hazard: header gradient + zebra + emptyRow filler) ======
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
              minWidth: 3000,
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
                  label: Center(child: Text("Reviewer")),
                  fixedWidth: 300,
                ),
                DataColumn2(
                  label: Center(child: Text("Role")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("Site")),
                  fixedWidth: 220,
                ),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 260,
                ),
                DataColumn2(
                  label: Center(child: Text("Buletin")),
                  fixedWidth: 380,
                ),
                DataColumn2(
                  label: Center(child: Text("Creator Role")),
                  fixedWidth: 180,
                ),
                DataColumn2(
                  label: Center(child: Text("Rating")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Komentar")),
                  fixedWidth: 420,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal")),
                  fixedWidth: 180,
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

  DataRow _rowPremium(BuletinReview e, int index) {
    final no = currentPage * rowsPerPage + index + 1;

    final bool zebra = index.isEven;
    final Color bg = zebra ? const Color(0xfff7f9fd) : Colors.white;

    return DataRow(
      color: MaterialStateProperty.all(bg),
      cells: [
        DataCell(Center(child: cell(no.toString(), weight: FontWeight.w900))),
        DataCell(cellWrap(e.userName)),
        DataCell(Center(child: _roleBadgePremium(e.reviewerRole))),
        DataCell(cellWrap(e.siteName)),
        DataCell(cellWrap(e.departmentName)),
        DataCell(cellWrap(e.buletinTitle)),
        DataCell(Center(child: _creatorRoleBadgePremium(e.buletinCreatorRole))),
        DataCell(_ratingCell(e.rating)),
        DataCell(cellWrap(e.comment)),
        DataCell(Center(child: cell(formatTanggal(e.createdAt)))),
      ],
    );
  }

  DataRow _emptyRow() {
    return DataRow(
      cells: List.generate(_columnCount, (_) => const DataCell(SizedBox())),
    );
  }

  // ====== Rating: tetap sama (produksi), hanya wrap rapi ======
  Widget _ratingCell(int rating) {
    return Center(
      child: Wrap(
        spacing: 2,
        children: List.generate(
          5,
          (i) => Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 18,
          ),
        ),
      ),
    );
  }

  // ====== Badge premium feel (tetap role value & teks sama) ======
  Widget _roleBadgePremium(String role) {
    final isAdmin = role == "admin";
    final Color c = isAdmin ? Colors.orange : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: Colors.black.withOpacity(0.70),
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _creatorRoleBadgePremium(String role) {
    final Color c = role == "superadmin" ? Colors.redAccent : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: Colors.black.withOpacity(0.70),
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }

  // ====== PAGINATION (samakan Hazard: info kiri-kanan + rows selector + chevron pill) ======
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
}

// ===== helpers (dipertahankan dari versi kamu, style hazard-friendly) =====
Widget cellWrap(String? text) {
  final safeText = text ?? "-";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Align(
      alignment: Alignment.center,
      child: Text(
        safeText.isEmpty ? "-" : safeText,
        textAlign: TextAlign.center,
        softWrap: true,
        style: const TextStyle(height: 1.5),
      ),
    ),
  );
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
          style: TextStyle(fontWeight: weight),
        ),
      ),
    ),
  );
}

String formatTanggal(DateTime? dt) {
  if (dt == null) return "-";
  return DateFormat("dd/MM/yyyy").format(dt);
}
