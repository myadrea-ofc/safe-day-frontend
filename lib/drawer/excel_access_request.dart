import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safety_apps/network/api_client.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/session/permission_refresh.dart';
import 'package:safety_apps/widgets/app_bottom_nav.dart';

class ExcelAccessRequestPage extends StatefulWidget {
  final String? feature;

  const ExcelAccessRequestPage({super.key, this.feature});

  @override
  State<ExcelAccessRequestPage> createState() => _ExcelAccessRequestPageState();
}

class _ExcelAccessRequestPageState extends State<ExcelAccessRequestPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool loading = true;
  bool acting = false;

  List<Map<String, dynamic>> all = [];
  List<Map<String, dynamic>> filtered = [];

  String status = "pending";

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final feature = (widget.feature ?? "").trim();

      final url = feature.isEmpty
          ? "/excel-access-requests?status=$status"
          : "/excel-access-requests?status=$status&feature=$feature";

      final res = await ApiClient.get(url);

      if (res.statusCode != 200) {
        throw Exception("Gagal load: ${res.statusCode}");
      }

      final List data = jsonDecode(res.body);

      all = data.map((e) => Map<String, dynamic>.from(e)).toList();
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal load request: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        filtered = List<Map<String, dynamic>>.from(all);
      } else {
        filtered = all.where((r) {
          final name = (r["requester_name"] ?? "").toString().toLowerCase();
          final site = (r["site_name"] ?? "").toString().toLowerCase();
          final dept = (r["department_name"] ?? "").toString().toLowerCase();
          final feature = (r["feature"] ?? "").toString().toLowerCase();

          return name.contains(q) ||
              site.contains(q) ||
              dept.contains(q) ||
              feature.contains(q);
        }).toList();
      }

      filtered.sort((a, b) {
        final ad =
            DateTime.tryParse((a["requested_at"] ?? "").toString()) ??
            DateTime(2000);
        final bd =
            DateTime.tryParse((b["requested_at"] ?? "").toString()) ??
            DateTime(2000);
        return bd.compareTo(ad);
      });
    });
  }

  Future<void> _approve(int requestId) async {
    if (acting) return;
    setState(() => acting = true);
    try {
      final res = await ApiClient.post(
        "/excel-access-requests/$requestId/approve",
      );
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw Exception(data["message"] ?? "Approve gagal");
      }

      PermissionRefresh.notifyExcelAccessChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil approve & grant akses")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Approve gagal: $e")));
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _reject(int requestId) async {
    if (acting) return;

    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xffef4444), Color(0xfff97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33EF4444),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Tolak permintaan?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tambahkan catatan bila diperlukan agar alasan penolakan lebih jelas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xff64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: TextField(
                    controller: noteCtrl,
                    maxLines: 4,
                    minLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: "Tulis catatan penolakan di sini...",
                      hintStyle: const TextStyle(
                        color: Color(0xff94a3b8),
                        fontWeight: FontWeight.w500,
                      ),
                      labelText: "Catatan (opsional)",
                      labelStyle: const TextStyle(
                        color: Color(0xff475569),
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 52),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xfff8fafc),
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
                        borderSide: const BorderSide(
                          color: Color(0xffef4444),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xffe2e8f0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: const Color(0xff334155),
                            backgroundColor: const Color(0xfff8fafc),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffef4444), Color(0xfff97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33EF4444),
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Tolak",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok != true) {
      noteCtrl.dispose();
      return;
    }

    setState(() => acting = true);
    try {
      final res = await ApiClient.post(
        "/excel-access-requests/$requestId/reject",
        body: {"reject_reason": noteCtrl.text.trim()},
      );

      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw Exception(data["message"] ?? "Reject gagal");
      }

      PermissionRefresh.notifyExcelAccessChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Permintaan ditolak")));

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Reject gagal: $e")));
    } finally {
      noteCtrl.dispose();
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = (AuthSession.role ?? "").toLowerCase().trim();
    if (!(role == "admin" || role == "superadmin")) {
      return const Scaffold(
        body: Center(child: Text("Halaman ini khusus Admin/Superadmin.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _ExcelAccessHeaderDelegate(
                  minHeight: 180,
                  maxHeight: 180,
                  child: _modernHeader(totalCount: filtered.length),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ExcelAccessControlsDelegate(
                  minHeight: 160,
                  maxHeight: 160,
                  child: _topControls(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 0)),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        child: filtered.isEmpty
                            ? _emptyState()
                            : Column(
                                children: filtered
                                    .map((r) => _requestCard(r))
                                    .toList(),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        role: role,
        site: AuthSession.siteName ?? "-",
        department: AuthSession.departmentName ?? "-",
        name: AuthSession.name ?? "-",
      ),
    );
  }

  Widget _modernHeader({required int totalCount}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Access Requested",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$totalCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _adminInfoCard(),
        ],
      ),
    );
  }

  Widget _adminInfoCard() {
    final role = (AuthSession.role ?? "").toUpperCase().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "List Permintaan Akses Excel",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status == "pending"
                      ? "Tinjau dan proses permintaan yang belum diputuskan"
                      : status == "approved"
                      ? "Lihat daftar permintaan yang sudah disetujui"
                      : "Lihat daftar permintaan yang sudah ditolak",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topControls() {
    return Container(
      color: const Color(0xffeef2f7),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Cari user / site / department…",
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.black.withOpacity(0.55),
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          _searchCtrl.clear();
                          _applySearch();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _segChip("Pending", "pending")),
                const SizedBox(width: 6),
                Expanded(child: _segChip("Approved", "approved")),
                const SizedBox(width: 6),
                Expanded(child: _segChip("Rejected", "rejected")),
                if (acting) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segChip(String label, String value) {
    final selected = status == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (selected) return;
        setState(() => status = value);
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? _statusColor(value) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    String text;
    if (status == "pending") {
      text = "Belum ada permintaan pending.";
    } else if (status == "approved") {
      text = "Belum ada permintaan yang disetujui.";
    } else {
      text = "Belum ada permintaan yang ditolak.";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xffeef2f7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: const Icon(Icons.inbox_rounded, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final id = int.tryParse((r["id"] ?? "").toString()) ?? 0;
    final name = (r["requester_name"] ?? "-").toString();
    final site = (r["site_name"] ?? "Site ID: ${r["site_id"] ?? "-"}")
        .toString();
    final dept = (r["department_name"] ?? "-").toString();
    final feature = (r["feature"] ?? "-").toString();
    final createdAt = _formatDate((r["requested_at"] ?? "").toString());
    final rowStatus = (r["status"] ?? "-").toString();
    final decidedByName = (r["decided_by_name"] ?? "").toString();
    final decidedByRole = (r["decided_by_role"] ?? "").toString();

    final Color accent = _statusColor(rowStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.10)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _statusBadge(rowStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.location_on_outlined, "Site", site),
                const SizedBox(height: 10),
                _infoRow(Icons.apartment_rounded, "Dept", dept),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.table_chart_rounded,
                  "Fitur",
                  _prettyFeature(feature),
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.schedule_rounded, "Dibuat", createdAt),
                if (rowStatus == "approved" && decidedByName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.verified_user_rounded,
                    "Approved",
                    "$decidedByName (${_prettyRole(decidedByRole)})",
                  ),
                ],
                if (rowStatus == "rejected" && decidedByName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.cancel_rounded,
                    "Rejected",
                    "$decidedByName (${_prettyRole(decidedByRole)})",
                  ),
                  _infoRow(
                    Icons.table_chart_rounded,
                    "Fitur",
                    _prettyFeature(feature),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (rowStatus == "pending")
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(
                        color: const Color(0xffef4444).withOpacity(0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundColor: const Color(0xffdc2626),
                    ),
                    onPressed: acting ? null : () => _reject(id),
                    child: const Text(
                      "Tolak",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: acting ? null : () => _approve(id),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2CB06D), Color(0xFF4AC488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Approve",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(rowStatus), size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Status: $rowStatus",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Icon(icon, size: 14, color: Colors.black.withOpacity(0.58)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.48),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ":",
              style: TextStyle(
                color: Colors.black.withOpacity(0.30),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String rowStatus) {
    final color = _statusColor(rowStatus);
    final icon = _statusIcon(rowStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            rowStatus.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case "approved":
        return const Color(0xff22c55e);
      case "rejected":
        return const Color(0xffef4444);
      case "pending":
      default:
        return const Color(0xfff59e0b);
    }
  }

  IconData _statusIcon(String value) {
    switch (value.toLowerCase()) {
      case "approved":
        return Icons.check_circle_rounded;
      case "rejected":
        return Icons.cancel_rounded;
      case "pending":
      default:
        return Icons.schedule_rounded;
    }
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return "-";

    try {
      final dt = DateTime.parse(raw).toLocal();

      const bulan = [
        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember",
      ];

      return "${dt.day} ${bulan[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  String _prettyRole(String role) {
    switch (role.toLowerCase().trim()) {
      case "superadmin":
        return "Superadmin";
      case "admin":
        return "Admin";
      default:
        return role.isEmpty ? "-" : role;
    }
  }

  String _prettyFeature(String feature) {
    switch (feature.toLowerCase().trim()) {
      case "p5m":
        return "Export Excel P5M";
      case "lpi":
        return "Export Excel LPI";
      case "hazard":
        return "Export Excel Hazard";
      case "inspeksi_chp":
        return "Export Excel Inspeksi CHP";
      case "inspeksi_fasilitas_bbm":
        return "Export Excel Inspeksi Fasilitas BBM";
      case "inspeksi_jalan_tambang":
        return "Export Excel Inspeksi Jalan Tambang";
      case "inspeksi_kantor":
        return "Export Excel Inspeksi Kantor";
      case "inspeksi_mtd":
        return "Export Excel Inspeksi Mess, Toilet, dan Dapur";
      case "inspeksi plant":
        return "Export Excel Inspeksi Plant";
      case "p2h_bus":
        return "Export Excel P2H Bus";
      case "p2h_dt":
        return "Export Excel P2H Dump Truck";
      case "p2h_exca":
        return "Export Excel P2H Excavator";
      case "p2h_grader":
        return "Export Excel P2H Grader";
      case "p2h_towerlamp":
        return "Export Excel P2H Tower Lamp";
      case "p2h_crane":
        return "Export Excel P2H Crane";
      case "p2h_compactor":
        return "Export Excel P2H Compactor";
      case "p2h_dozer":
        return "Export Excel P2H Dozer";
      case "p2h_forklift":
        return "Export Excel P2H Forklift";
      case "p2h_fuel_truck":
        return "Export Excel P2H Fuel Truck";
      case "p2h_lv":
        return "Export Excel P2H LV";
      case "p2h_service_truck":
        return "Export Excel P2H Service Truck";
      case "p2h_truck":
        return "Export Excel P2H Truck";
      case "p2h_water_truck":
        return "Export Excel P2H Water Truck";
      case "p2h_water_pump":
        return "Export Excel P2H Water Pump";
      case "p2h_wheelloader":
        return "Export Excel P2H Wheel Loader";
      case "daily_plan":
        return "Export Excel Daily Plan";
      case "buletin":
        return "Export Excel Buletin";
      default:
        return feature.isEmpty ? "-" : feature;
    }
  }
}

class _ExcelAccessHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _ExcelAccessHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: Colors.transparent, child: child);
  }

  @override
  bool shouldRebuild(covariant _ExcelAccessHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}

class _ExcelAccessControlsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _ExcelAccessControlsDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: const Color(0xffeef2f7), child: child);
  }

  @override
  bool shouldRebuild(covariant _ExcelAccessControlsDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}
