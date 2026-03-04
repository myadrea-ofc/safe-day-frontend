import 'dart:async';

import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/about_page.dart';
import 'package:safety_apps/drawer/change_password.dart';
import 'package:safety_apps/drawer/event_result.dart';
import 'package:safety_apps/drawer/hazard_result_page.dart';
import 'package:safety_apps/drawer/inspection_result_page.dart';
import 'package:safety_apps/drawer/lpi_result_page.dart';
import 'package:safety_apps/drawer/p2h_result.dart';
import 'package:safety_apps/drawer/p5m_result_page.dart';
import 'package:safety_apps/drawer/user_management.dart';
import 'package:safety_apps/network/api_client.dart';
import 'package:safety_apps/pages/home/form_p5m.dart';
import 'package:safety_apps/pages/home/hses_event.dart';
import 'package:safety_apps/pages/home/inspeksi.dart';
import 'package:safety_apps/pages/home/notification_page.dart';
import 'package:safety_apps/pages/login_page.dart';
import 'package:safety_apps/pages/profile_page.dart';
import 'package:safety_apps/pages/home/p2h.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'home/form_hazard_page.dart';
import 'home/form_lpi_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  final String site;
  final String department;
  final String name;
  final String role;

  const HomePage({
    super.key,
    required this.site,
    required this.department,
    required this.name,
    required this.role,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoggingOut = false;
  Timer? _sessionTimer;

  final List<Map<String, dynamic>> menuItems = [
    {
      "title": "LPI Accident",
      "subtitle": "Laporan Awal Kecelakaan Kerja",
      "icon": Icons.report_gmailerrorred,
      "page": FormLPIPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "Hazard Report",
      "subtitle": "Pelaporan Bahaya",
      "icon": Icons.warning_amber_rounded,
      "page": FormHazardPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "Inspection",
      "subtitle": "Pencegahan Resiko Melalui Inspeksi",
      "icon": Icons.search_rounded,
      "page": InspeksiPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "P2H",
      "subtitle": "Pemeriksaan dan Pemeliharaan Harian",
      "icon": Icons.fact_check_rounded,
      "page": P2HPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "P5M",
      "subtitle": "Formulir Absensi",
      "icon": Icons.table_chart_rounded,
      "page": FormP5MPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "HSES Event",
      "subtitle": "Pemberitahuan dan Monitoring",
      "icon": Icons.event_available_rounded,
      "page": HsesEventPage(),
      "roles": ["admin", "member"],
    },
    {
      "title": "Call Center",
      "subtitle": "Radio HT melalui Channel HSE — WhatsApp",
      "icon": Icons.phone_in_talk_rounded,
      "whatsapp": "6281145589558",
    },
  ];

  List<Map<String, dynamic>> drawerMenus = [];

  List<Map<String, dynamic>> filteredMenu = [];

  final TextEditingController searchController = TextEditingController();

  void _startSessionPolling() {
    _sessionTimer?.cancel();

    _sessionTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        await ApiClient.get("/profile");
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    print("ROLE DARI LOGIN => '${widget.role}'");
    filterMenuByRole();
    buildDrawerMenu();
    _loadUnreadCount();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkRoleStillValid();
    // });

    WidgetsBinding.instance.addObserver(this);

    _startSessionPolling();
  }

  void filterMenuByRole() {
    final role = widget.role.toLowerCase().trim();

    if (role == "superadmin") {
      filteredMenu = List.from(menuItems);
      return;
    }

    filteredMenu = menuItems.where((item) {
      if (!item.containsKey("roles")) return true;
      return (item["roles"] as List).map((r) => r.toLowerCase()).contains(role);
    }).toList();
  }

  void filterSearch(String query) {
    final role = widget.role.toLowerCase().trim();
    final input = query.toLowerCase().trim();

    bool roleAllowed(Map item) {
      if (role != "superadmin" && item.containsKey("roles")) {
        final roles = (item["roles"] as List)
            .map((r) => r.toLowerCase())
            .toList();
        return roles.contains(role);
      }
      return true;
    }

    setState(() {
      if (input.isEmpty) {
        filteredMenu = menuItems.where((item) => roleAllowed(item)).toList();
        return;
      }

      filteredMenu = menuItems.where((item) {
        if (!roleAllowed(item)) return false;

        final title = item["title"].toString().toLowerCase();
        final subtitle = item["subtitle"].toString().toLowerCase();

        return title.startsWith(input) || subtitle.startsWith(input);
      }).toList();
    });
  }

  // ===================== DRAWER MENU BUILDER =====================
  void buildDrawerMenu() {
    drawerMenus = [
      {
        "icon": Icons.home_rounded,
        "label": "Home",
        "roles": ["superadmin", "admin", "member"],
        "onTap": () => Navigator.pop(context),
      },
      {
        "icon": Icons.info_outline,
        "label": "About",
        "roles": ["superadmin", "admin", "member"],
        "page": AboutPage(),
      },

      {
        "icon": Icons.person_add,
        "label": "User Management",
        "roles": ["admin", "superadmin"],
        "page": UserManagementPage(),
      },

      {
        "icon": Icons.lock_outline,
        "label": "Change Password",
        "roles": ["superadmin", "admin", "member"],
        "page": ChangePasswordPage(),
      },
      {
        "icon": Icons.report_gmailerrorred,
        "label": "LPI Results",
        "roles": ["admin", "superadmin"],
        "page": LPIResultPage(),
      },
      {
        "icon": Icons.warning_amber,
        "label": "Hazard Results",
        "roles": ["admin", "superadmin"],
        "page": HazardResultPage(),
      },
      {
        "icon": Icons.search_rounded,
        "label": "Inspection Results",
        "roles": ["admin", "superadmin"],
        "page": InspectionResultPage(),
      },
      {
        "icon": Icons.fact_check_rounded,
        "label": "P2H Results",
        "roles": ["admin", "superadmin"],
        "page": P2HResultPage(),
      },
      {
        "icon": Icons.table_chart_rounded,
        "label": "P5M Results",
        "roles": ["admin", "superadmin"],
        "page": P5MResultPage(),
      },
      {
        "icon": Icons.event_sharp,
        "label": "Events",
        "roles": ["admin", "superadmin"],
        "page": EventPage(),
      },
    ];
  }

  List<Map<String, dynamic>> get filteredDrawerMenus {
    final role = widget.role.toLowerCase().trim();

    if (role == "superadmin") return drawerMenus;

    return drawerMenus.where((menu) {
      final roles = (menu["roles"] as List)
          .map((r) => r.toLowerCase())
          .toList();
      return roles.contains(role);
    }).toList();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    _sessionTimer?.cancel();

    try {
      final res = await ApiClient.post("/logout");
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw Exception(data["message"] ?? "Logout gagal");
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _storage.deleteAll();
      AuthSession.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 18),

                // ===== TITLE =====
                const Text(
                  "Keluar dari Akun?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                // ===== SUBTITLE =====
                const Text(
                  "Kamu akan keluar dari akun ini dan perlu login kembali untuk mengakses aplikasi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 26),

                // ===== BUTTONS =====
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        onPressed: _isLoggingOut ? null : handleLogout,
                        child: _isLoggingOut
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Logout",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _unreadCount = 0;

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiClient.get("/notifications/unread-count");
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final unread = (data["unread"] ?? 0) as int;

      if (mounted) setState(() => _unreadCount = unread);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sessionTimer?.cancel();
    }

    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
      Future.microtask(() async {
        try {
          await ApiClient.get("/profile");
        } catch (_) {}
      });

      _startSessionPolling();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),

                ...filteredMenu.map((item) {
                  return menuCardPremium(
                    context,
                    title: item["title"],
                    subtitle: item["subtitle"],
                    icon: item["icon"],
                    onTap: () {
                      if (item.containsKey("page")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item["page"]),
                        );
                      } else if (item.containsKey("whatsapp")) {
                        openWhatsApp(item["whatsapp"]);
                      }
                    },
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(75),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SAFE DAY",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.site.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsPage(
                      name: widget.name,
                      site: widget.site,
                      department: widget.department,
                      role: widget.role,
                    ),
                  ),
                );

                // setelah balik dari notif page, refresh badge
                _loadUnreadCount();
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _unreadCount > 99 ? "99+" : "$_unreadCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      width: 310,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: Material(
        // penting: ini yang bikin background luar drawer jadi clean (no ungu soft)
        color: Colors.white,
        surfaceTintColor: Colors.transparent, // Material 3 tint
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(context),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  children: [
                    ...filteredDrawerMenus.map((menu) {
                      return drawerItemPremium(
                        icon: menu["icon"],
                        label: menu["label"],
                        isActive: menu["label"] == "Home",
                        onTap: () {
                          if (menu.containsKey("page")) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => menu["page"]),
                            );
                          } else if (menu.containsKey("onTap")) {
                            menu["onTap"]();
                          }
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ===== LOGOUT (FIXED BOTTOM) =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD6D6)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _logout,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "© 2025 HSES Management • v1.0",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final role = widget.role.toLowerCase().trim();

    Color roleColor() {
      switch (role) {
        case "superadmin":
          return const Color(0xFFFFC107);
        case "admin":
          return const Color(0xFF00D1B2);
        default:
          return const Color(0xFFB3E5FC);
      }
    }

    String roleLabel() {
      if (role == "superadmin") return "SUPERADMIN";
      if (role == "admin") return "ADMIN";
      return "MEMBER";
    }

    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // decorative bubbles
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                // top row actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: roleColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            roleLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          site: widget.site,
                          department: widget.department,
                          name: widget.name,
                          email: AuthSession.email ?? "-",
                          employeeId: AuthSession.employeeId ?? "-",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        // avatar modern
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              "assets/logo.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${widget.department} • ${widget.site}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "View Profile",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
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

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: (q) {
        if (q.trim().isEmpty) {
          setState(() {
            filterMenuByRole();
          });
        } else {
          filterSearch(q);
        }
      },
      decoration: InputDecoration(
        hintText: "Cari menu...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff1d63ff), width: 1.4),
        ),
      ),
    );
  }

  Widget menuCardPremium(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff1d63ff).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xff1d63ff), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItemPremium({
    required IconData icon,
    required String label,
    required Function() onTap,
    bool isActive = false,
  }) {
    const blue = Color(0xff1d63ff);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? blue.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? blue.withOpacity(0.20) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: blue), // icon biru semua
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void openWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("WhatsApp tidak ditemukan"),
            content: const Text("Pastikan WhatsApp terinstall di perangkat."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }
}
