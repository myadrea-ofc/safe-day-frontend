import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/access_permission.dart';
import 'package:safety_apps/drawer/excel_access_request.dart';
import 'package:safety_apps/network/api_client.dart';
import 'package:safety_apps/main.dart';
import 'package:safety_apps/pages/profile_page.dart';

class NotificationsPage extends StatefulWidget {
  final String name;
  final String site;
  final String department;
  final String role;
  final String email;
  final String employeeId;

  const NotificationsPage({
    super.key,
    required this.name,
    required this.site,
    required this.department,
    required this.role,
    this.email = "",
    this.employeeId = "",
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  int _tabIndex = 0; // 0 = unread, 1 = read

  // ===== FILTER STATE (UI-only, tidak ubah logic production) =====
  String _filterType = "all"; // all | daily_plan | buletin | lpi
  String _filterGroup =
      "all"; // all | today | yesterday | this_week | last_week | two_weeks_ago | this_month | last_month | older
  String _filterQuery = ""; // cari title/body + groupTitle

  bool get _hasActiveFilter =>
      _filterType != "all" ||
      _filterGroup != "all" ||
      _filterQuery.trim().isNotEmpty;

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> input) {
    final q = _filterQuery.trim().toLowerCase();

    return input.where((n) {
      // type
      if (_filterType != "all") {
        final data = (n["data"] is Map<String, dynamic>)
            ? (n["data"] as Map<String, dynamic>)
            : <String, dynamic>{};
        final t = (data["type"] ?? "").toString();
        if (t != _filterType) return false;
      }

      // group (berdasarkan waktu)
      if (_filterGroup != "all") {
        final dt = _parseCreatedAt(n["created_at"]);
        final key = dt == null ? "older" : _groupKeyFor(dt);
        if (key != _filterGroup) return false;
      }

      // query (cari di title/body dan juga groupTitle)
      if (q.isNotEmpty) {
        final title = (n["title"] ?? "").toString().toLowerCase();
        final body = (n["body"] ?? "").toString().toLowerCase();

        final dt = _parseCreatedAt(n["created_at"]);
        final key = dt == null ? "older" : _groupKeyFor(dt);
        final groupTitle = _groupTitle(key).toLowerCase();

        final match =
            title.contains(q) || body.contains(q) || groupTitle.contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);

    try {
      final res = await ApiClient.get("/notifications");
      if (res.statusCode != 200) {
        throw Exception("Gagal memuat notifikasi (${res.statusCode})");
      }

      final List rawList = jsonDecode(res.body) as List;

      final parsed = rawList.map<Map<String, dynamic>>((e) {
        final m = (e as Map).cast<String, dynamic>();

        Map<String, dynamic> parsedData = {};
        final rawData = m["data"];
        if (rawData != null) {
          try {
            if (rawData is String) {
              parsedData = (jsonDecode(rawData) as Map).cast<String, dynamic>();
            } else if (rawData is Map) {
              parsedData = rawData.cast<String, dynamic>();
            }
          } catch (_) {}
        }

        return {
          "id": m["id"],
          "title": m["title"] ?? "Notifikasi",
          "body": m["body"] ?? "",
          "created_at": m["created_at"] ?? "",
          "is_read": m["is_read"] == true,
          "data": parsedData,
        };
      }).toList();

      if (!mounted) return;
      setState(() => _items = parsed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(dynamic id) async {
    try {
      final res = await ApiClient.put("/notifications/$id/read");
      if (res.statusCode != 200) return;

      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((x) => x["id"] == id);
        if (idx != -1) {
          _items[idx]["is_read"] = true;
          // pindahin ke bawah biar masuk tab "Sudah dibaca" saat rebuild
          final item = _items.removeAt(idx);
          _items.add(item);
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _items.any((x) => x["is_read"] == false);

    if (!hasUnread) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua notifikasi sudah dibaca.")),
      );
      return;
    }

    try {
      final res = await ApiClient.put("/notifications/read-all");
      if (res.statusCode != 200) {
        throw Exception("Gagal menandai semua notifikasi sebagai dibaca");
      }

      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          item["is_read"] = true;
        }

        final unread = _items.where((x) => x["is_read"] == false).toList();
        final read = _items.where((x) => x["is_read"] == true).toList();
        _items = [...unread, ...read];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua notifikasi ditandai sudah dibaca."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _navigateByNotifData(Map<String, dynamic> data) {
    final type = (data["type"] ?? "").toString();

    // ===== existing types =====
    if (type == "daily_plan") {
      final planId = int.tryParse((data["daily_plan_id"] ?? "").toString());
      if (planId == null) return;

      navigatorKey.currentState?.pushNamed(
        "/daily-plan",
        arguments: {"open_detail_id": planId},
      );
      return;
    }

    if (type == "buletin") {
      final buletinId = int.tryParse((data["buletin_id"] ?? "").toString());
      if (buletinId == null) return;

      navigatorKey.currentState?.pushNamed(
        "/buletin",
        arguments: {"open_detail_id": buletinId},
      );
      return;
    }

    if (type == "lpi") {
      final lpiId = int.tryParse((data["lpi_id"] ?? "").toString());
      if (lpiId == null) return;

      navigatorKey.currentState?.pushNamed(
        "/lpi-results",
        arguments: {"open_detail_id": lpiId},
      );
      return;
    }

    if (type == "role_changed") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            site: widget.site,
            department: widget.department,
            name: widget.name,
            email: widget.email,
            employeeId: widget.employeeId,
          ),
        ),
      );
      return;
    }

    if (type == "excel_access_request") {
      final role = widget.role.toLowerCase().trim();
      if (!(role == "admin" || role == "superadmin")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notifikasi ini untuk Admin/Superadmin."),
          ),
        );
        return;
      }

      final feature = (data["feature"] ?? "").toString().trim();

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ExcelAccessRequestPage(feature: feature),
        ),
      );
      return;
    }

    if (type == "excel_access_decision") {
      final role = widget.role.toLowerCase().trim();
      if (role != "member") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi ini untuk Member.")),
        );
        return;
      }

      final feature = (data["feature"] ?? "").toString().trim();

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AccessPermissionPage(feature: feature),
        ),
      );
      return;
    }

    if (type == "excel_access_revoked") {
      final role = widget.role.toLowerCase().trim();
      if (role != "member") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi ini untuk Member.")),
        );
        return;
      }

      final feature = (data["feature"] ?? "").toString().trim();

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AccessPermissionPage(feature: feature),
        ),
      );
      return;
    }

    if (type == "excel_access_granted") {
      final role = widget.role.toLowerCase().trim();
      if (role != "member") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi ini untuk Member.")),
        );
        return;
      }

      final feature = (data["feature"] ?? "").toString().trim();

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AccessPermissionPage(feature: feature),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tipe notifikasi tidak dikenali: $type")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => e["is_read"] == false).toList();
    final read = _items.where((e) => e["is_read"] == true).toList();

    final baseList = _tabIndex == 0 ? unread : read; // tab logic tetap
    final list = _applyFilters(baseList); // <— filter tampilan saja
    final rows = _buildGroupedRows(list);

    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _modernHeader(unreadCount: unread.length),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _segmentedTabs(unread.length, read.length),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),
              SliverToBoxAdapter(child: _filterBar()),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                        child: list.isEmpty
                            ? _emptyStateInline(
                                _tabIndex == 0
                                    ? "Belum ada notifikasi baru."
                                    : "Belum ada notifikasi yang terbaca.",
                              )
                            : Column(
                                children: [
                                  // list grouped rows
                                  ...rows.map((row) {
                                    if (row["_kind"] == "header") {
                                      return _groupHeaderChip(
                                        row["title"]?.toString() ?? "",
                                      );
                                    }
                                    final n =
                                        row["data"] as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _notifTileModern(
                                        n,
                                        unread: _tabIndex == 0,
                                      ),
                                    );
                                  }).toList(),
                                ],
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

  Widget _filterBar() {
    final border = Colors.black.withOpacity(0.06);

    String typeLabel() {
      switch (_filterType) {
        case "daily_plan":
          return "Daily Plan";
        case "buletin":
          return "Buletin";
        case "lpi":
          return "LPI";
        case "role_changed":
          return "Change Role";
        case "excel_access_request":
          return "Excel Request";
        case "excel_access_decision":
          return "Excel Decision";
        case "excel_access_revoked":
          return "Excel Revoked";
        case "excel_access_granted":
          return "Excel Granted";
        default:
          return "Semua";
      }
    }

    String groupLabel() {
      if (_filterGroup == "all") return "Semua waktu";
      return _groupTitle(_filterGroup);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _openFilterSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Filter",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${typeLabel()} • ${groupLabel()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasActiveFilter)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff1d63ff).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xff1d63ff).withOpacity(0.22),
                          ),
                        ),
                        child: const Text(
                          "AKTIF",
                          style: TextStyle(
                            color: Color(0xff1d63ff),
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // quick: fokus ke search di sheet
              _openFilterSheet(focusSearch: true);
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),
          if (_hasActiveFilter) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() {
                _filterType = "all";
                _filterGroup = "all";
                _filterQuery = "";
              }),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xff1d63ff),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFilterSheet({bool focusSearch = false}) {
    final ctrl = TextEditingController(text: _filterQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Widget chip({
              required bool selected,
              required String label,
              required VoidCallback onTap,
            }) {
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected
                        ? const Color(0xff1d63ff).withOpacity(0.12)
                        : Colors.black.withOpacity(0.04),
                    border: Border.all(
                      color: selected
                          ? const Color(0xff1d63ff).withOpacity(0.35)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: selected
                          ? const Color(0xff1d63ff)
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffeef2f7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // handle + title
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Filter Notifikasi",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setSheet(() {
                                  ctrl.text = "";
                                });
                                setState(() {
                                  _filterType = "all";
                                  _filterGroup = "all";
                                  _filterQuery = "";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: const Text(
                                  "Reset",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // search field (title/body + groupTitle)
                        TextField(
                          controller: ctrl,
                          autofocus: focusSearch,
                          onChanged: (v) {
                            setState(() => _filterQuery = v);
                            setSheet(() {});
                          },
                          decoration: InputDecoration(
                            hintText:
                                "Cari: judul, isi, atau grup (mis. “Minggu ini”)",
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xffeef2f7),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xff1d63ff),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // type chips
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Tipe",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withOpacity(0.70),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            chip(
                              selected: _filterType == "all",
                              label: "Semua",
                              onTap: () {
                                setState(() => _filterType = "all");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "daily_plan",
                              label: "Daily Plan",
                              onTap: () {
                                setState(() => _filterType = "daily_plan");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "buletin",
                              label: "Buletin",
                              onTap: () {
                                setState(() => _filterType = "buletin");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "lpi",
                              label: "LPI",
                              onTap: () {
                                setState(() => _filterType = "lpi");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "role_changed",
                              label: "Change Role",
                              onTap: () {
                                setState(() => _filterType = "role_changed");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "excel_access_request",
                              label: "Excel Request",
                              onTap: () {
                                setState(
                                  () => _filterType = "excel_access_request",
                                );
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "excel_access_decision",
                              label: "Excel Decision",
                              onTap: () {
                                setState(
                                  () => _filterType = "excel_access_decision",
                                );
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "excel_access_revoked",
                              label: "Excel Revoked",
                              onTap: () {
                                setState(
                                  () => _filterType = "excel_access_revoked",
                                );
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterType == "excel_access_granted",
                              label: "Excel Granted",
                              onTap: () {
                                setState(
                                  () => _filterType = "excel_access_granted",
                                );
                                setSheet(() {});
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // group chips (berdasarkan _groupTitle kamu)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Waktu (Group)",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withOpacity(0.70),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            chip(
                              selected: _filterGroup == "all",
                              label: "Semua waktu",
                              onTap: () {
                                setState(() => _filterGroup = "all");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "today",
                              label: "Hari ini",
                              onTap: () {
                                setState(() => _filterGroup = "today");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "yesterday",
                              label: "Kemarin",
                              onTap: () {
                                setState(() => _filterGroup = "yesterday");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "this_week",
                              label: "Minggu ini",
                              onTap: () {
                                setState(() => _filterGroup = "this_week");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "last_week",
                              label: "Minggu lalu",
                              onTap: () {
                                setState(() => _filterGroup = "last_week");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "two_weeks_ago",
                              label: "2 minggu lalu",
                              onTap: () {
                                setState(() => _filterGroup = "two_weeks_ago");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "this_month",
                              label: "Bulan ini",
                              onTap: () {
                                setState(() => _filterGroup = "this_month");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "last_month",
                              label: "Bulan lalu",
                              onTap: () {
                                setState(() => _filterGroup = "last_month");
                                setSheet(() {});
                              },
                            ),
                            chip(
                              selected: _filterGroup == "older",
                              label: "Lebih lama",
                              onTap: () {
                                setState(() => _filterGroup = "older");
                                setSheet(() {});
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // apply button
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff1d63ff),
                                        Color(0xff4fa9ff),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 14,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Terapkan",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
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
          },
        );
      },
    );
  }

  Widget _emptyStateInline(String text) {
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
                child: const Icon(
                  Icons.notifications_off_rounded,
                  color: Colors.black54,
                ),
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

  Widget _groupHeaderChip(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xffeef2f7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.black54,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: Colors.black.withOpacity(0.06)),
          ),
        ],
      ),
    );
  }

  Widget _modernHeader({required int unreadCount}) {
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
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Notifications",
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
                      Icons.mark_email_unread,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "read_all") {
                    await _markAllAsRead();
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: Colors.white,
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: "read_all",
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18),
                        SizedBox(width: 10),
                        Text("Baca semua"),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _userCard(),
        ],
      ),
    );
  }

  Widget _userCard() {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${widget.site} • ${widget.department}",
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
              widget.role.toUpperCase(),
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

  Widget _segmentedTabs(int unreadCount, int readCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Expanded(
              child: _segBtn(
                selected: _tabIndex == 0,
                label: "Belum dibaca",
                count: unreadCount,
                onTap: () => setState(() => _tabIndex = 0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _segBtn(
                selected: _tabIndex == 1,
                label: "Sudah dibaca",
                count: readCount,
                onTap: () => setState(() => _tabIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segBtn({
    required bool selected,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1d63ff) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.22)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTileModern(Map<String, dynamic> n, {required bool unread}) {
    final data = (n["data"] is Map<String, dynamic>)
        ? (n["data"] as Map<String, dynamic>)
        : <String, dynamic>{};

    final type = (data["type"] ?? "").toString();
    final icon = _iconByType(type);
    final chip = _chipByType(type);

    final readBorder = Colors.black.withOpacity(0.06);
    final readShadow = const [
      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
    ];

    final unreadBorder = const Color(0xff1d63ff).withOpacity(0.45);
    final unreadShadow = const [
      BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, 8)),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (unread) await _markAsRead(n["id"]);
            _navigateByNotifData(data);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: unread ? unreadBorder : readBorder),
              boxShadow: unread ? unreadShadow : readShadow,

              gradient: unread
                  ? LinearGradient(
                      colors: [
                        Colors.blueAccent.shade100,
                        Colors.white.withOpacity(1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: unread ? null : Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),

                        // Icon box unread lebih “alive”
                        gradient: unread
                            ? LinearGradient(
                                colors: [
                                  Colors.blueAccent.shade100,
                                  const Color(0xff4fa9ff).withOpacity(0.18),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: unread ? null : Colors.grey.withOpacity(0.10),

                        border: Border.all(
                          color: unread
                              ? const Color(0xff1d63ff).withOpacity(0.28)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: unread ? Colors.white : Colors.grey.shade700,
                        size: 26,
                      ),
                    ),

                    // dot unread
                    if (unread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xff1d63ff),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Title row =====
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (n["title"] ?? "Notifikasi").toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                                fontSize: 14.8,
                                color: unread ? Colors.black : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Badge "BARU" bikin inviting
                          if (unread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff1d63ff),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "BARU",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            )
                          else if (chip != null)
                            // read tetap seperti kamu suka
                            Opacity(opacity: 0.75, child: chip),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ===== Body =====
                      if ((n["body"] ?? "").toString().isNotEmpty)
                        Text(
                          (n["body"] ?? "").toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread ? Colors.black87 : Colors.black45,
                            height: 1.28,
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ===== Time =====
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: unread ? Colors.grey : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCreatedAt(n["created_at"]),
                            style: TextStyle(
                              color: unread ? Colors.grey : Colors.black54,
                              fontSize: 10,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: unread
                      ? const Color(0xff1d63ff).withOpacity(0.75)
                      : Colors.black.withOpacity(0.30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconByType(String type) {
    switch (type) {
      case "daily_plan":
        return Icons.event_note_rounded;
      case "buletin":
        return Icons.article_rounded;
      case "lpi":
        return Icons.report_gmailerrorred_rounded;
      case "role_changed":
        return Icons.manage_accounts_rounded;
      case "excel_access_request":
        return Icons.request_page_rounded;
      case "excel_access_decision":
        return Icons.rule_rounded;
      case "excel_access_revoked":
        return Icons.block_rounded;
      case "excel_access_granted":
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget? _chipByType(String type) {
    String? text;
    if (type == "daily_plan") text = "Daily Plan";
    if (type == "buletin") text = "Buletin";
    if (type == "lpi") text = "LPI";
    if (type == "role_changed") text = "Change Role";
    if (type == "excel_access_request") text = "Excel Request";
    if (type == "excel_access_decision") text = "Excel Decision";
    if (type == "excel_access_revoked") text = "Excel Revoked";
    if (type == "excel_access_granted") text = "Excel Granted";
    if (text == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _formatCreatedAt(dynamic raw) {
    final s = (raw ?? "").toString();
    if (s.isEmpty) return "-";

    try {
      final dt = DateTime.parse(s).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return "Baru saja";
      if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam lalu";
      if (diff.inDays == 1) return "Kemarin";
      if (diff.inDays < 7) return "${diff.inDays} hari lalu";

      String two(int v) => v.toString().padLeft(2, "0");
      return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return s; // fallback
    }
  }

  DateTime? _parseCreatedAt(dynamic raw) {
    final s = (raw ?? "").toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  String _groupKeyFor(DateTime dt) {
    final now = DateTime.now();
    final today = _startOfDay(now);
    final date = _startOfDay(dt);

    // Hari ini / Kemarin
    if (date == today) return "today";
    if (date == today.subtract(const Duration(days: 1))) return "yesterday";

    // Minggu ini (Senin - Minggu)
    final startOfThisWeek = today.subtract(
      Duration(days: today.weekday - 1),
    ); // Senin
    if (!date.isBefore(startOfThisWeek)) return "this_week";

    // Minggu lalu (minggu sebelumnya, Senin - Minggu)
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    if (!date.isBefore(startOfLastWeek) && date.isBefore(startOfThisWeek)) {
      return "last_week";
    }

    // 2 minggu lalu (minggu sebelum minggu lalu)
    final startOfTwoWeeksAgo = startOfThisWeek.subtract(
      const Duration(days: 14),
    );
    if (!date.isBefore(startOfTwoWeeksAgo) && date.isBefore(startOfLastWeek)) {
      return "two_weeks_ago";
    }

    // Bulan ini / Bulan lalu
    final startThisMonth = _startOfMonth(today);
    if (!date.isBefore(startThisMonth)) return "this_month";

    final startLastMonth = DateTime(
      startThisMonth.year,
      startThisMonth.month - 1,
      1,
    );
    if (!date.isBefore(startLastMonth) && date.isBefore(startThisMonth)) {
      return "last_month";
    }

    return "older";
  }

  String _groupTitle(String key) {
    switch (key) {
      case "today":
        return "Hari ini";
      case "yesterday":
        return "Kemarin";
      case "this_week":
        return "Minggu ini";
      case "last_week":
        return "Minggu lalu";
      case "two_weeks_ago":
        return "2 minggu lalu";
      case "this_month":
        return "Bulan ini";
      case "last_month":
        return "Bulan lalu";
      default:
        return "Lebih lama";
    }
  }

  int _groupOrder(String key) {
    switch (key) {
      case "today":
        return 0;
      case "yesterday":
        return 1;
      case "this_week":
        return 2;
      case "last_week":
        return 3;
      case "two_weeks_ago":
        return 4;
      case "this_month":
        return 5;
      case "last_month":
        return 6;
      default:
        return 7; // older
    }
  }

  List<Map<String, dynamic>> _buildGroupedRows(
    List<Map<String, dynamic>> list,
  ) {
    final items = List<Map<String, dynamic>>.from(list);

    // newest first
    items.sort((a, b) {
      final da =
          _parseCreatedAt(a["created_at"]) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          _parseCreatedAt(b["created_at"]) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    // group -> list
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final n in items) {
      final dt = _parseCreatedAt(n["created_at"]);
      final key = dt == null ? "older" : _groupKeyFor(dt);
      (groups[key] ??= []).add(n);
    }

    // build rows with fixed order (yang kosong dilewati)
    final keys = groups.keys.toList()
      ..sort((a, b) => _groupOrder(a).compareTo(_groupOrder(b)));

    final rows = <Map<String, dynamic>>[];
    for (final key in keys) {
      final groupItems = groups[key]!;
      rows.add({"_kind": "header", "title": _groupTitle(key)});
      for (final n in groupItems) {
        rows.add({"_kind": "item", "data": n});
      }
    }

    return rows;
  }
}
