import 'dart:io';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_apps/models/p5m.dart';
import 'package:safety_apps/service/excel_access_service.dart';
import 'package:safety_apps/service/export_excel/p5m_export_service.dart';
import 'package:safety_apps/service/p5m_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class P5MResultPage extends StatefulWidget {
  @override
  State<P5MResultPage> createState() => _P5MResultPageState();
}

enum DatePreset { all, today, week, month, custom }

class ExcelAccess {
  final int userId;
  final String userName;
  final String userRole; // role user yang diberi akses (member/admin)
  final int siteId;
  final String siteName;
  bool canDownload;
  final int grantedBy; // userId admin/superadmin pemberi akses
  DateTime createdAt;
  bool seenByAdmin; // untuk badge "baru" di admin site

  ExcelAccess({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.siteId,
    required this.siteName,
    required this.canDownload,
    required this.grantedBy,
    required this.createdAt,
    required this.seenByAdmin,
  });
}

class _P5MResultPageState extends State<P5MResultPage> {
  List<P5MModel> allData = [];
  List<P5MModel> filtered = [];
  int rowsPerPage = 10;
  int currentPage = 0;
  bool loading = true;

  bool _exporting = false;

  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  static const int _columnCount = 11;

  final TextEditingController _searchCtrl = TextEditingController();

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
      final start = today.subtract(Duration(days: today.weekday - 1)); // Monday
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

  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  // ==== AUTH / CONTEXT (sementara hardcode, nanti ambil dari session/login) ====
  String _role = 'member'; // 'member' | 'admin' | 'superadmin'
  int _currentUserId = 101; // id user login
  int _currentSiteId = 1; // site aktif user (admin dikunci di site ini)
  String _currentSiteName = "Site A";

  bool get _isAdminOrSuperadmin => _role == 'admin' || _role == 'superadmin';

  // data akses
  List<ExcelAccess> _accessList = [];
  bool _loadingAccess = false;

  // untuk badge unseen
  int _unseenAddedBySuperadmin = 0;

  // keep your gradient (biar theme konsisten)
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
    _loadExcelAccess();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await P5MService.fetchP5M();
      setState(() {
        allData = data;
        filtered = _applySearchAndDate();
        loading = false;
        currentPage = 0;
        _ensurePageValid();
      });
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    }
  }

  Future<void> _loadExcelAccess() async {
    setState(() => _loadingAccess = true);
    try {
      final response = await ExcelAccessService.fetchAccess();

      final list = response
          .map(
            (e) => ExcelAccess(
              userId: e["user_id"],
              userName: e["user_name"],
              userRole: e["role_name"],
              siteId: e["site_id"],
              siteName: e["site_name"],
              canDownload: e["can_download"],
              grantedBy: 0,
              createdAt: DateTime.now(),
              seenByAdmin: e["seen_by_admin"],
            ),
          )
          .toList();

      // filter sesuai role admin (dikunci site sendiri)
      final filteredByRole = (_role == 'admin')
          ? list.where((e) => e.siteId == _currentSiteId).toList()
          : list;

      setState(() {
        _accessList = filteredByRole;

        // badge unseen untuk admin site
        if (_role == 'admin') {
          _unseenAddedBySuperadmin = _accessList
              .where((e) => e.seenByAdmin == false)
              .length;
        } else {
          _unseenAddedBySuperadmin = 0;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingAccess = false);
    }
  }

  Future<void> _toggleAccess(ExcelAccess a, bool v) async {
    if (_role == 'admin' && a.siteId != _currentSiteId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin hanya bisa mengatur akses di site sendiri."),
        ),
      );
      return;
    }

    setState(() => a.canDownload = v);

    try {
      if (v) {
        await ExcelAccessService.grant(userId: a.userId, siteId: a.siteId);
      } else {
        await ExcelAccessService.revoke(userId: a.userId, siteId: a.siteId);
      }
    } catch (e) {
      if (e.toString().contains("role_changed")) {
        await logoutAndRedirect();
        return;
      }

      // rollback UI kalau gagal
      setState(() => a.canDownload = !v);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal update akses: $e")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          v ? "Akses download diaktifkan" : "Akses download dimatikan",
        ),
      ),
    );
  }

  Future<void> logoutAndRedirect() async {
    // contoh: hapus token + ke halaman login
    const storage = FlutterSecureStorage();
    await storage.delete(key: "jwt_token");

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }

  Future<void> _openGrantAccessDialog() async {
    final nameCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    String selectedRole = "member";

    // site picker hanya untuk superadmin
    int selectedSiteId = _currentSiteId;
    String selectedSiteName = _currentSiteName;

    // contoh site list (mock)
    final sites = const [
      {"id": 1, "name": "Site A"},
      {"id": 2, "name": "Site B"},
      {"id": 3, "name": "Site C"},
    ];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Akses Download"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "User ID"),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama User"),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "member", child: Text("member")),
                  DropdownMenuItem(value: "admin", child: Text("admin")),
                ],
                onChanged: (v) => selectedRole = v ?? "member",
                decoration: const InputDecoration(labelText: "Role user"),
              ),

              const SizedBox(height: 12),

              if (_role == 'superadmin')
                DropdownButtonFormField<int>(
                  value: selectedSiteId,
                  items: sites
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s["id"] as int,
                          child: Text(s["name"] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    selectedSiteId = v;
                    selectedSiteName =
                        sites.firstWhere((e) => e["id"] == v)["name"] as String;
                  },
                  decoration: const InputDecoration(labelText: "Site"),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Site: $_currentSiteName (admin hanya bisa site sendiri)",
                    style: TextStyle(color: Colors.black.withOpacity(0.55)),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final uid = int.tryParse(userIdCtrl.text.trim());
              final uname = nameCtrl.text.trim();

              if (uid == null || uname.isEmpty) return;

              // Rule: admin hanya boleh grant site sendiri
              if (_role == 'admin') {
                selectedSiteId = _currentSiteId;
                selectedSiteName = _currentSiteName;
              }

              setState(() {
                _accessList.insert(
                  0,
                  ExcelAccess(
                    userId: uid,
                    userName: uname,
                    userRole: selectedRole,
                    siteId: selectedSiteId,
                    siteName: selectedSiteName,
                    canDownload: true,
                    grantedBy: _currentUserId,
                    createdAt: DateTime.now(),
                    // kalau superadmin yg grant, admin site harus lihat "baru"
                    seenByAdmin: _role == 'superadmin' ? false : true,
                  ),
                );

                if (_role == 'admin') {
                  // admin grant sendiri -> bukan "baru dari superadmin"
                  _unseenAddedBySuperadmin = _accessList
                      .where((e) => e.seenByAdmin == false)
                      .length;
                }
              });

              // TODO: call API grant access
              Navigator.pop(context);
            },
            child: const Text("Grant"),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    userIdCtrl.dispose();
  }

  bool get _canCurrentUserDownloadExcel {
    // Admin & Superadmin selalu boleh (sesuai requirement kamu)
    if (_role == 'admin' || _role == 'superadmin') return true;

    // Member harus punya akses yang aktif untuk site saat ini
    return _accessList.any(
      (a) =>
          a.userId == _currentUserId &&
          a.siteId == _currentSiteId &&
          a.canDownload == true,
    );
  }

  List<P5MModel> _applySearchAndDate() {
    final searched = _searchResults(_searchCtrl.text);
    final range = _presetRange(_datePreset);
    if (range == null) return searched;

    return searched.where((e) {
      final dt = e.createdAt;
      if (dt == null) return false;
      return !dt.isBefore(range.start) &&
          dt.isBefore(range.end); // end eksklusif
    }).toList();
  }

  void _refreshFiltered() {
    setState(() {
      filtered = _applySearchAndDate();
      currentPage = 0;
      _ensurePageValid();
    });
  }

  List<P5MModel> _searchResults(String v) {
    final q = v.toLowerCase().trim();

    String safeLower(String? s) => (s ?? "").toLowerCase().trim();

    // kalau kosong -> semua data (tanpa ranking)
    if (q.isEmpty) return List<P5MModel>.from(allData);

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

    int rankRow(P5MModel e) {
      final n = safeLower(e.nama);
      final p = safeLower(e.perusahaan);
      final d = safeLower(e.department);

      final rn = rankText(n);
      final rp = rankText(p);
      final rd = rankText(d);

      return [rn, rp, rd].reduce((a, b) => a < b ? a : b);
    }

    int firstIndexRow(P5MModel e) {
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
      filtered = _applySearchAndDate(); // gabungan search+date
      currentPage = 0;
      _ensurePageValid();
    });
  }

  List<P5MModel> get pageData {
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
          : LayoutBuilder(
              builder: (context, c) {
                final tableHeight = (c.maxHeight * 0.58).clamp(320.0, 520.0);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _searchBox(),
                            const SizedBox(height: 12),
                            _dateFilterBar(),
                            const SizedBox(height: 12),

                            // ✅ panel akses (hanya admin/superadmin)
                            if (_isAdminOrSuperadmin) ...[
                              _excelAccessPanel(),
                              const SizedBox(height: 14),
                            ],

                            SizedBox(height: tableHeight, child: _table()),
                            const SizedBox(height: 12),
                            _pagination(),
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
                    "P5M Results",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // pill info count (premium)
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
        // Radius untuk shadow dan border luar
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
      // Menggunakan ClipRRect agar isi TextField (termasuk splash effect)
      // tetap berada di dalam radius yang kita buat
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: TextField(
          controller: _searchCtrl,
          onChanged: onSearch,
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
            // Pastikan border internal TextField dihilangkan
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

  Widget _excelAccessPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Akses Download Excel",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),

              // badge "baru" untuk admin site
              if (_role == 'admin' && _unseenAddedBySuperadmin > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.withOpacity(0.35)),
                  ),
                  child: Text(
                    "Baru: $_unseenAddedBySuperadmin",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),

              const SizedBox(width: 8),

              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _openGrantAccessDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Tambah",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_loadingAccess)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_accessList.isEmpty)
            Text(
              "Belum ada user yang diberi akses download.",
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Column(
              children: _accessList.take(5).map((a) => _accessRow(a)).toList(),
            ),

          if (_accessList.length > 5) ...[
            const SizedBox(height: 6),
            Text(
              "Menampilkan 5 dari ${_accessList.length} user",
              style: TextStyle(
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accessRow(ExcelAccess a) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff5f7fb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.userName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  "Site: ${a.siteName} • Role: ${a.userRole}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: a.canDownload, onChanged: (v) => _toggleAccess(a, v)),
        ],
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
            // premium header glow
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

              // transparent heading row (biar gradient kelihatan)
              headingRowColor: MaterialStateProperty.all(
                const Color.fromRGBO(0, 0, 0, 0),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
                letterSpacing: 0.2,
              ),

              // divider halus
              dividerThickness: 0.6,

              // zebra rows (premium readability)
              dataRowColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _primary.withOpacity(0.10);
                }
                // alternating
                // NOTE: DataTable2 pakai state row index internal, tapi zebra tetap terasa karena container putih + divider
                return Colors.transparent;
              }),

              columns: const [
                DataColumn2(label: Center(child: Text("No")), fixedWidth: 90),
                DataColumn2(
                  label: Center(child: Text("Nama")),
                  fixedWidth: 300,
                ),
                DataColumn2(
                  label: Center(child: Text("Perusahaan")),
                  fixedWidth: 250,
                ),
                DataColumn2(
                  label: Center(child: Text("Department")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Nama Pembicara")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Topik")),
                  fixedWidth: 250,
                ),
                DataColumn2(
                  label: Center(child: Text("Jabatan")),
                  fixedWidth: 200,
                ),
                DataColumn2(
                  label: Center(child: Text("Tanggal")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("Status Kerja")),
                  fixedWidth: 150,
                ),
                DataColumn2(
                  label: Center(child: Text("Foto")),
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

  DataRow _rowPremium(P5MModel e, int index) {
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
        DataCell(cellWrap(e.namaPembicara)),
        DataCell(cellWrap(e.topik)),
        DataCell(cellWrap(e.jabatan)),
        DataCell(Center(child: cell(formatTanggal(e.createdAt)))),

        // status jadi pill premium
        DataCell(Center(child: _statusPill(e.siapKerja))),

        // foto icon jadi lebih “buttony”
        DataCell(
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showFoto(e.fotoPath, "foto"),
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
                    Icons.image_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        // detail button premium (tanpa ubah logic)
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

  Widget _statusPill(String status) {
    final s = status.toLowerCase().trim();

    Color c;

    if (s == "iya") {
      c = const Color(0xff16a34a); // emerald modern
    } else if (s == "tidak") {
      c = const Color(0xffef4444); // red modern
    } else {
      // fallback kalau null / kosong / value aneh
      c = Colors.grey;
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

  Widget _dateFilterBar() {
    final range = _presetRange(_datePreset);

    String rangeLabel() {
      if (_datePreset == DatePreset.all) return "Semua tanggal";
      if (_datePreset == DatePreset.today) return "Hari ini";
      if (_datePreset == DatePreset.week) return "Minggu ini";
      if (_datePreset == DatePreset.month) return "Bulan ini";
      if (range == null) return "Pilih range";
      final f = DateFormat("dd MMM yyyy");
      return "${f.format(range.start)} - ${f.format(range.end.subtract(const Duration(days: 1)))}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter Tanggal",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 14),

          // ===== Chips: horizontal scroll + animasi (Implicit) =====
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                        _presetChipAnimated("Semua", DatePreset.all),
                        _presetChipAnimated("Hari ini", DatePreset.today),
                        _presetChipAnimated("Minggu ini", DatePreset.week),
                        _presetChipAnimated("Bulan ini", DatePreset.month),
                        _presetChipAnimated("Custom", DatePreset.custom),
                      ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: e,
                        ),
                      )
                      .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ===== date + excel (responsif) =====
          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 420; // hp kecil
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openDateFilterModal(),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: Colors.black.withOpacity(0.65),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rangeLabel(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: (filtered.isEmpty || _exporting)
                          ? null
                          : () {
                              if (!_canCurrentUserDownloadExcel) {
                                _showNoExcelAccessDialog();
                                return;
                              }
                              _exportExcelCurrentFilter();
                            },
                      child: Opacity(
                        opacity: (filtered.isEmpty || _exporting) ? 0.55 : 1,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            // ✅ anti overflow: FittedBox
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _exporting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.download_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                    const SizedBox(width: 8),
                                    Text(
                                      compact ? "Excel" : "Download Excel",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _presetChipAnimated(String label, DatePreset p) {
    final selected = _datePreset == p;

    return GestureDetector(
      onTap: () async {
        if (_datePreset == p) return;

        setState(() => _datePreset = p);

        if (p == DatePreset.custom) {
          await _pickCustomRange();
        }

        _refreshFiltered();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 12, // 🔥 lebih kecil dari 16
          vertical: 7, // 🔥 lebih pendek
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected ? primaryGradient : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.25), // 🔥 lebih soft
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 14, // 🔥 lebih kecil
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5, // 🔥 lebih kecil
                color: selected ? Colors.white : Colors.black.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDateFilterModal() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.tune_rounded),
                  const SizedBox(width: 10),
                  const Text(
                    "Pilih Filter Tanggal",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _modalItem("Semua tanggal", DatePreset.all),
              _modalItem("Hari ini", DatePreset.today),
              _modalItem("Minggu ini", DatePreset.week),
              _modalItem("Bulan ini", DatePreset.month),
              _modalItem(
                "Custom range…",
                DatePreset.custom,
                onTap: () async {
                  Navigator.pop(context);
                  await _pickCustomRange();
                  setState(() => _datePreset = DatePreset.custom);
                  _refreshFiltered();
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _modalItem(String text, DatePreset preset, {VoidCallback? onTap}) {
    final selected = _datePreset == preset;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap:
          onTap ??
          () {
            setState(() => _datePreset = preset);
            _refreshFiltered();
            Navigator.pop(context);
          },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _primary.withOpacity(0.08)
              : const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _primary : Colors.black.withOpacity(0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange,
    );
    if (picked == null) return;

    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final endExclusive = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    ).add(const Duration(days: 1));

    setState(() {
      _customRange = DateTimeRange(start: start, end: endExclusive);
    });
  }

  Future<void> _exportExcelCurrentFilter() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      if (!_canCurrentUserDownloadExcel) {
        if (!mounted) return;
        _showNoExcelAccessDialog();
        return; // ✅ finally tetap jalan, exporting balik false
      }

      final range = _presetRange(_datePreset);

      final file = await P5MExportService.downloadExportXlsx(
        start: range?.start,
        end: range?.end,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("File export siap: ${file.path}")));

      await Share.shareXFiles([XFile(file.path)], text: "Export P5M");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export gagal: $e")));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showNoExcelAccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Akses Download Ditolak"),
        content: const Text(
          "Akun kamu belum diberi akses untuk mendownload Excel.\n"
          "Silakan hubungi Admin/Superadmin untuk memberikan akses.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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

          dir = Directory("/storage/emulated/0/Pictures");
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw "Download gagal";
        }

        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(response.bodyBytes);
        savedPath = file.path;
      } catch (e) {
        Navigator.pop(context);

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

      Navigator.pop(context);

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
                    gradient: LinearGradient(
                      colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
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

  void showDetail(P5MModel e) {
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
                      "Detail Laporan P5M",
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),

                      _sectionTitle("Profil Pembicara P5M"),
                      Row(
                        children: [
                          Expanded(
                            child: _flatBox("Nama Pembicara", e.namaPembicara),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox("Jabatan Pembicara", e.jabatan),
                          ),
                        ],
                      ),
                      _flatBox("Topik P5M", e.topik),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 0.5),
                      ),

                      _sectionTitle("Detail Pendengar"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _flatBox(
                              "Kondisi Kesehatan",
                              e.kondisiKesehatan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _flatBox("Jam Tidur", e.jamTidur)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _flatBox("Kesiapan Kerja", e.siapKerja),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _flatBox(
                              "Status Hari Kerja Kemarin",
                              e.statusHariKerja,
                              isStatus: true,
                              statusValue: e.statusHariKerja,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _flatBox("Umpan Balik", e.umpanBalik, isLongText: true),

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

  // Widget Judul Section dengan Gradien (Sesuai Permintaan)
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
            color: Colors.white, // Warna ini akan ditimpa oleh gradient shader
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Widget Box Jawaban dengan Background (Flat Style)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          text.isEmpty ? "-" : text,
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

  String formatTanggal(DateTime? dt) {
    if (dt == null) return "-";
    return DateFormat("dd/MM/yyyy").format(dt);
  }

  Widget cell(String text, {FontWeight? weight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Tooltip(
          message: text,
          child: Text(
            text.isEmpty ? "-" : text,
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

  Future<void> downloadFoto(P5MModel e) async {
    final url = "http://safety.borneo.co.id/uploads/${e.fotoPath}";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
