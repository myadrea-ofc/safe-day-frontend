import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/about_page.dart';
import 'package:safety_apps/drawer/audit_log_page.dart';
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
import 'package:safety_apps/session/permission_refresh.dart';
import 'package:safety_apps/widgets/app_bottom_nav.dart';
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

  bool _loadingExcelAccess = false;
  DateTime? _lastExcelAccessLoadAt;

  bool _memberCanSeeP5MResults = false;
  bool _memberCanSeeLPIResults = false;
  bool _memberCanSeeHazardResults = false;
  bool _memberCanSeeInspeksiCHPResults = false;
  bool _memberCanSeeInspeksiJalanTambangResults = false;
  bool _memberCanSeeInspeksiKantorResults = false;
  bool _memberCanSeeInspeksiMTDResults = false;
  bool _memberCanSeeInspeksiPlantResults = false;
  bool _memberCanSeeInspeksiFasilitasBBMResults = false;
  bool _memberCanSeeP2HLVResults = false;
  bool _memberCanSeeP2HBusResults = false;
  bool _memberCanSeeP2HDTResults = false;
  bool _memberCanSeeP2HExcavatorResults = false;
  bool _memberCanSeeP2HGraderResults = false;
  bool _memberCanSeeP2HDozerResults = false;
  bool _memberCanSeeP2HTowerLampResults = false;
  bool _memberCanSeeP2HCraneResults = false;
  bool _memberCanSeeP2HForkliftResults = false;
  bool _memberCanSeeP2HTruckHaulingResults = false;
  bool _memberCanSeeP2HWaterTruckResults = false;
  bool _memberCanSeeP2HWheelLoaderResults = false;
  bool _memberCanSeeP2HWaterPumpResults = false;
  bool _memberCanSeeP2HServiceTruckResults = false;
  bool _memberCanSeeP2HCompactorResults = false;
  bool _memberCanSeeP2HFuelTruckResults = false;
  bool _memberCanSeeDailyPlanResults = false;
  bool _memberCanSeeBuletinResults = false;
  bool _memberCanSeeTrainingResults = false;

  bool get _memberCanSeeAnyInspectionResults {
    return _memberCanSeeInspeksiCHPResults ||
        _memberCanSeeInspeksiJalanTambangResults ||
        _memberCanSeeInspeksiKantorResults ||
        _memberCanSeeInspeksiMTDResults ||
        _memberCanSeeInspeksiPlantResults ||
        _memberCanSeeInspeksiFasilitasBBMResults;
  }

  bool get _memberCanSeeAnyP2HResults {
    return _memberCanSeeP2HLVResults ||
        _memberCanSeeP2HBusResults ||
        _memberCanSeeP2HDTResults ||
        _memberCanSeeP2HExcavatorResults ||
        _memberCanSeeP2HGraderResults ||
        _memberCanSeeP2HDozerResults ||
        _memberCanSeeP2HTowerLampResults ||
        _memberCanSeeP2HCraneResults ||
        _memberCanSeeP2HForkliftResults ||
        _memberCanSeeP2HTruckHaulingResults ||
        _memberCanSeeP2HWaterTruckResults ||
        _memberCanSeeP2HWheelLoaderResults ||
        _memberCanSeeP2HWaterPumpResults ||
        _memberCanSeeP2HServiceTruckResults ||
        _memberCanSeeP2HCompactorResults ||
        _memberCanSeeP2HFuelTruckResults;
  }

  bool get _memberCanSeeAnyEventResults {
    return _memberCanSeeDailyPlanResults ||
        _memberCanSeeBuletinResults ||
        _memberCanSeeTrainingResults;
  }

  void _resetMemberExcelAccess() {
    _memberCanSeeP5MResults = false;
    _memberCanSeeLPIResults = false;
    _memberCanSeeHazardResults = false;
    _memberCanSeeInspeksiCHPResults = false;
    _memberCanSeeInspeksiJalanTambangResults = false;
    _memberCanSeeInspeksiKantorResults = false;
    _memberCanSeeInspeksiMTDResults = false;
    _memberCanSeeInspeksiPlantResults = false;
    _memberCanSeeInspeksiFasilitasBBMResults = false;

    _memberCanSeeP2HLVResults = false;
    _memberCanSeeP2HBusResults = false;
    _memberCanSeeP2HDTResults = false;
    _memberCanSeeP2HExcavatorResults = false;
    _memberCanSeeP2HGraderResults = false;
    _memberCanSeeP2HDozerResults = false;
    _memberCanSeeP2HTowerLampResults = false;
    _memberCanSeeP2HCraneResults = false;
    _memberCanSeeP2HForkliftResults = false;
    _memberCanSeeP2HTruckHaulingResults = false;
    _memberCanSeeP2HWaterTruckResults = false;
    _memberCanSeeP2HWheelLoaderResults = false;
    _memberCanSeeP2HWaterPumpResults = false;
    _memberCanSeeP2HServiceTruckResults = false;
    _memberCanSeeP2HCompactorResults = false;
    _memberCanSeeP2HFuelTruckResults = false;

    _memberCanSeeDailyPlanResults = false;
    _memberCanSeeBuletinResults = false;
    _memberCanSeeTrainingResults = false;
  }

  bool _parseCanDownload(dynamic response) {
    try {
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      return (data["can_download"] ?? false) == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _fetchExcelAccess(String feature) async {
    final response = await ApiClient.get("/excel-access/me?feature=$feature");
    return _parseCanDownload(response);
  }

  void _handleExcelAccessRefresh() {
    _loadMemberExcelAccess(force: true);
  }

  Future<void> _loadMemberExcelAccess({bool force = false}) async {
    final role = _currentRole.toLowerCase().trim();

    if (role != "member") {
      if (!mounted) return;
      setState(_resetMemberExcelAccess);
      return;
    }

    if (_loadingExcelAccess) {
      return;
    }

    final now = DateTime.now();

    if (!force &&
        _lastExcelAccessLoadAt != null &&
        now.difference(_lastExcelAccessLoadAt!) < const Duration(seconds: 30)) {
      return;
    }

    _loadingExcelAccess = true;
    _lastExcelAccessLoadAt = now;

    try {
      final results = await Future.wait([
        _fetchExcelAccess("p5m"),
        _fetchExcelAccess("lpi"),
        _fetchExcelAccess("hazard"),
        _fetchExcelAccess("inspeksi_chp"),
        _fetchExcelAccess("inspeksi_jalan_tambang"),
        _fetchExcelAccess("inspeksi_kantor"),
        _fetchExcelAccess("inspeksi_mtd"),
        _fetchExcelAccess("inspeksi_plant"),
        _fetchExcelAccess("inspeksi_fasilitas_bbm"),
        _fetchExcelAccess("p2h_lv"),
        _fetchExcelAccess("p2h_bus"),
        _fetchExcelAccess("p2h_dt"),
        _fetchExcelAccess("p2h_excavator"),
        _fetchExcelAccess("p2h_grader"),
        _fetchExcelAccess("p2h_dozer"),
        _fetchExcelAccess("p2h_tower_lamp"),
        _fetchExcelAccess("p2h_crane"),
        _fetchExcelAccess("p2h_forklift"),
        _fetchExcelAccess("p2h_truck_hauling"),
        _fetchExcelAccess("p2h_water_truck"),
        _fetchExcelAccess("p2h_wheel_loader"),
        _fetchExcelAccess("p2h_water_pump"),
        _fetchExcelAccess("p2h_service_truck"),
        _fetchExcelAccess("p2h_compactor"),
        _fetchExcelAccess("p2h_fuel_truck"),
        _fetchExcelAccess("daily_plan"),
        _fetchExcelAccess("buletin"),
        _fetchExcelAccess("training"),
      ]);

      if (!mounted) return;

      setState(() {
        _memberCanSeeP5MResults = results[0];
        _memberCanSeeLPIResults = results[1];
        _memberCanSeeHazardResults = results[2];
        _memberCanSeeInspeksiCHPResults = results[3];
        _memberCanSeeInspeksiJalanTambangResults = results[4];
        _memberCanSeeInspeksiKantorResults = results[5];
        _memberCanSeeInspeksiMTDResults = results[6];
        _memberCanSeeInspeksiPlantResults = results[7];
        _memberCanSeeInspeksiFasilitasBBMResults = results[8];

        _memberCanSeeP2HLVResults = results[9];
        _memberCanSeeP2HBusResults = results[10];
        _memberCanSeeP2HDTResults = results[11];
        _memberCanSeeP2HExcavatorResults = results[12];
        _memberCanSeeP2HGraderResults = results[13];
        _memberCanSeeP2HDozerResults = results[14];
        _memberCanSeeP2HTowerLampResults = results[15];
        _memberCanSeeP2HCraneResults = results[16];
        _memberCanSeeP2HForkliftResults = results[17];
        _memberCanSeeP2HTruckHaulingResults = results[18];
        _memberCanSeeP2HWaterTruckResults = results[19];
        _memberCanSeeP2HWheelLoaderResults = results[20];
        _memberCanSeeP2HWaterPumpResults = results[21];
        _memberCanSeeP2HServiceTruckResults = results[22];
        _memberCanSeeP2HCompactorResults = results[23];
        _memberCanSeeP2HFuelTruckResults = results[24];

        _memberCanSeeDailyPlanResults = results[25];
        _memberCanSeeBuletinResults = results[26];
        _memberCanSeeTrainingResults = results[27];
      });
    } catch (e) {
      debugPrint("❌ LoadMemberExcelAccess error: $e");

      if (!mounted) return;
      setState(_resetMemberExcelAccess);
    } finally {
      _loadingExcelAccess = false;
    }
  }

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

  List<Map<String, dynamic>> filteredMenu = [];

  final TextEditingController searchController = TextEditingController();

  bool _checkingProfile = false;

  void _startSessionPolling() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_checkingProfile) return;
      _checkingProfile = true;
      try {
        await ApiClient.get("/profile");
      } catch (_) {
      } finally {
        _checkingProfile = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("🏠 HomePage: initState masuk");
    print("ROLE DARI LOGIN => '$_currentRole'");
    filterMenuByRole();
    _loadUnreadCount();
    debugPrint("📡 HomePage: mulai load permission");
    _loadMemberExcelAccess();
    PermissionRefresh.excelAccessVersion.addListener(_handleExcelAccessRefresh);
    WidgetsBinding.instance.addObserver(this);
    _startSessionPolling();
  }

  void filterMenuByRole() {
    final role = _currentRole.toLowerCase().trim();

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
    final role = _currentRole.toLowerCase().trim();
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

  List<Map<String, dynamic>> get drawerMenus {
    final role = _currentRole.toLowerCase().trim();

    return [
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
        "icon": Icons.manage_search_rounded,
        "label": "Audit Log",
        "roles": ["admin", "superadmin"],
        "page": AuditLogPage(),
      },

      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeLPIResults))
        {
          "icon": Icons.report_gmailerrorred,
          "label": "LPI Results",
          "roles": ["admin", "superadmin", "member"],
          "page": LPIResultPage(),
        },
      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeHazardResults))
        {
          "icon": Icons.warning_amber,
          "label": "Hazard Results",
          "roles": ["admin", "superadmin", "member"],
          "page": HazardResultPage(),
        },
      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeAnyInspectionResults))
        {
          "icon": Icons.search_rounded,
          "label": "Inspection Results",
          "roles": ["admin", "superadmin", "member"],
          "page": InspectionResultPage(
            canSeeInspeksiCHP: _memberCanSeeInspeksiCHPResults,
            canSeeInspeksiJalanTambang:
                _memberCanSeeInspeksiJalanTambangResults,
            canSeeInspeksiKantor: _memberCanSeeInspeksiKantorResults,
            canSeeInspeksiMTD: _memberCanSeeInspeksiMTDResults,
            canSeeInspeksiPlant: _memberCanSeeInspeksiPlantResults,
            canSeeInspeksiFasilitasBBM:
                _memberCanSeeInspeksiFasilitasBBMResults,
            userRole: _currentRole,
          ),
        },
      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeAnyP2HResults))
        {
          "icon": Icons.fact_check_rounded,
          "label": "P2H Results",
          "roles": ["admin", "superadmin", "member"],
          "page": P2HResultPage(
            canSeeLV: _memberCanSeeP2HLVResults,
            canSeeBus: _memberCanSeeP2HBusResults,
            canSeeDT: _memberCanSeeP2HDTResults,
            canSeeExcavator: _memberCanSeeP2HExcavatorResults,
            canSeeGrader: _memberCanSeeP2HGraderResults,
            canSeeDozer: _memberCanSeeP2HDozerResults,
            canSeeTowerLamp: _memberCanSeeP2HTowerLampResults,
            canSeeCrane: _memberCanSeeP2HCraneResults,
            canSeeForklift: _memberCanSeeP2HForkliftResults,
            canSeeTruckHauling: _memberCanSeeP2HTruckHaulingResults,
            canSeeWaterTruck: _memberCanSeeP2HWaterTruckResults,
            canSeeWheelLoader: _memberCanSeeP2HWheelLoaderResults,
            canSeeWaterPump: _memberCanSeeP2HWaterPumpResults,
            canSeeServiceTruck: _memberCanSeeP2HServiceTruckResults,
            canSeeCompactor: _memberCanSeeP2HCompactorResults,
            canSeeFuelTruck: _memberCanSeeP2HFuelTruckResults,
            userRole: _currentRole,
          ),
        },
      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeP5MResults))
        {
          "icon": Icons.table_chart_rounded,
          "label": "P5M Results",
          "roles": ["admin", "superadmin", "member"],
          "page": P5MResultPage(),
        },
      if (role == "admin" ||
          role == "superadmin" ||
          (role == "member" && _memberCanSeeAnyEventResults))
        {
          "icon": Icons.event_sharp,
          "label": "Events",
          "roles": ["admin", "superadmin", "member"],
          "page": EventPage(
            canSeeDailyPlan: _memberCanSeeDailyPlanResults,
            canSeeBuletin: _memberCanSeeBuletinResults,
            canSeeTraining: _memberCanSeeTrainingResults,
            userRole: _currentRole,
          ),
        },
    ];
  }

  List<Map<String, dynamic>> get filteredDrawerMenus {
    final role = _currentRole.toLowerCase().trim();

    return drawerMenus.where((menu) {
      if (!menu.containsKey("roles")) return true;

      final roles = (menu["roles"] as List)
          .map((r) => r.toLowerCase())
          .toList();

      return roles.contains(role);
    }).toList();
  }

  final _storage = const FlutterSecureStorage();

  String get _currentName => AuthSession.name ?? widget.name;
  String get _currentSite => AuthSession.siteName ?? widget.site;
  String get _currentDepartment =>
      AuthSession.departmentName ?? widget.department;
  String get _currentRole => AuthSession.role ?? widget.role;
  String get _currentEmail => AuthSession.email ?? "-";
  String get _currentEmployeeId => AuthSession.employeeId ?? "-";

  Future<void> handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    _sessionTimer?.cancel();

    AuthSession.isManualLogout = true;

    try {
      final res = await ApiClient.post("/logout");
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw Exception(data["message"] ?? "Logout gagal");
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
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

      if (_currentRole.toLowerCase().trim() == "member") {
        _loadMemberExcelAccess();
      }

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
    PermissionRefresh.excelAccessVersion.removeListener(
      _handleExcelAccessRefresh,
    );

    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        role: _currentRole,
        site: _currentSite,
        department: _currentDepartment,
        name: _currentName,
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
                _currentSite.toUpperCase(),
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
                      name: _currentName,
                      site: _currentSite,
                      department: _currentDepartment,
                      role: _currentRole,
                      email: _currentEmail,
                      employeeId: _currentEmployeeId,
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

  Widget _buildDrawerHeader(BuildContext context) {
    final role = _currentRole.toLowerCase().trim();

    Color roleColor() {
      switch (role) {
        case "superadmin":
          return const Color(0xFF00D1B2);
        case "admin":
          return const Color(0xFFFFC107);
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
                          site: _currentSite,
                          department: _currentDepartment,
                          name: _currentName,
                          email: _currentEmail,
                          employeeId: _currentEmployeeId,
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
                                _currentName,
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
                                "$_currentDepartment • $_currentSite",
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
