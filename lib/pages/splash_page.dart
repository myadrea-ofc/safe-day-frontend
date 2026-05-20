import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safety_apps/pages/home_page.dart';
import 'package:safety_apps/pages/login_page.dart';
import 'package:safety_apps/session/auth_session.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  late AnimationController _logoController;
  late AnimationController _bgController;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Alignment> _beginAlign;
  late Animation<Alignment> _endAlign;

  bool _checkingSession = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _beginAlign = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _endAlign = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    try {
      await _doCheckSession().timeout(const Duration(seconds: 18));
    } catch (e) {
      debugPrint("❌ Splash fatal/timeout: $e");
      await _clearSessionKeepDeviceId();
      AuthSession.clear();
      _goToLogin();
    }
  }

  Future<void> _doCheckSession() async {
    debugPrint("🚀 Splash: start checkSession");
    if (!mounted) return;

    setState(() => _checkingSession = true);

    await Future.delayed(const Duration(seconds: 2));
    debugPrint("⏳ Splash: delay selesai");

    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    debugPrint("🔑 Token exists: ${token != null && token.isNotEmpty}");
    debugPrint(
      "📱 DeviceId exists: ${deviceId != null && deviceId.isNotEmpty}",
    );

    if (!mounted) return;

    if (token == null ||
        token.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      debugPrint("➡️ Splash exit: token/device kosong");
      _goToLogin();
      return;
    }

    final networkReady = await _waitForNetworkReadiness();
    if (!networkReady) {
      debugPrint("➡️ Splash exit: network not ready");
      await _clearSessionKeepDeviceId();
      AuthSession.clear();
      _goToLogin();
      return;
    }

    final profile = await _readStoredProfile();
    if (!profile.isValid) {
      debugPrint("➡️ Splash exit: profile storage tidak valid");
      await _clearSessionKeepDeviceId();
      AuthSession.clear();
      _goToLogin();
      return;
    }

    final isSessionValid = await _validateSessionToBackend(
      token: token,
      deviceId: deviceId,
    );

    if (!isSessionValid) {
      debugPrint("➡️ Splash exit: backend session invalid");
      await _clearSessionKeepDeviceId();
      AuthSession.clear();
      _goToLogin();
      return;
    }

    // Baru restore AuthSession setelah backend valid
    AuthSession.token = token;
    AuthSession.name = profile.name!;
    AuthSession.role = profile.role!;
    AuthSession.userId = profile.userId!;
    AuthSession.siteId = profile.siteId!;
    AuthSession.departmentId = profile.departmentId!;
    AuthSession.siteName = profile.site!;
    AuthSession.departmentName = profile.department!;
    AuthSession.email = profile.email;
    AuthSession.employeeId = profile.employeeId;
    AuthSession.markReady();

    debugPrint("➡️ Splash exit: go home");

    if (!mounted || _navigated) return;

    _navigated = true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: profile.name!,
          role: profile.role!,
          site: profile.site!,
          department: profile.department!,
        ),
      ),
      (route) => false,
    );
  }

  Future<bool> _waitForNetworkReadiness() async {
    if (kIsWeb) {
      debugPrint("🌐 Network readiness skipped on web");
      return true;
    }

    for (int tries = 1; tries <= 5; tries++) {
      debugPrint("🌐 Network check try: $tries");
      final ready = await isNetworkReady();
      debugPrint("🌐 Network ready: $ready");

      if (ready) return true;

      await Future.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<bool> isNetworkReady() async {
    if (kIsWeb) {
      debugPrint("🌐 Network check skipped on web");
      return true;
    }

    try {
      final result = await InternetAddress.lookup(
        'safety.borneo.co.id',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint("🌐 Network lookup failed: $e");
      return false;
    }
  }

  Future<_StoredProfile> _readStoredProfile() async {
    debugPrint("📦 Reading stored profile");

    final name = await _storage.read(key: "user_name");
    final role = await _storage.read(key: "user_role");
    final site = await _storage.read(key: "site_name");
    final department = await _storage.read(key: "department_name");
    final email = await _storage.read(key: "user_email");
    final employeeId = await _storage.read(key: "employee_id");
    final userIdStr = await _storage.read(key: "user_id");
    final siteIdStr = await _storage.read(key: "site_id");
    final departmentIdStr = await _storage.read(key: "department_id");

    final parsedUserId = int.tryParse(userIdStr ?? '');
    final parsedSiteId = int.tryParse(siteIdStr ?? '');
    final parsedDepartmentId = int.tryParse(departmentIdStr ?? '');

    final hasRequiredFields =
        (name?.isNotEmpty ?? false) &&
        (role?.isNotEmpty ?? false) &&
        (site?.isNotEmpty ?? false) &&
        (department?.isNotEmpty ?? false) &&
        parsedUserId != null &&
        parsedSiteId != null &&
        parsedDepartmentId != null;

    debugPrint("📦 Stored profile valid: $hasRequiredFields");

    return _StoredProfile(
      name: name,
      role: role,
      site: site,
      department: department,
      email: email,
      employeeId: employeeId,
      userId: parsedUserId,
      siteId: parsedSiteId,
      departmentId: parsedDepartmentId,
      isValid: hasRequiredFields,
    );
  }

  Future<bool> _validateSessionToBackend({
    required String token,
    required String deviceId,
  }) async {
    try {
      debugPrint("🛰️ Validate session to backend: start");

      final res = await _safeGet(
        Uri.parse("http://safety.borneo.co.id/validate-session"),
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "x-device-id": deviceId,
        },
      );

      debugPrint("🛰️ Validate session status: ${res?.statusCode}");

      if (res == null || res.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(res.body);
      final valid = data["valid"] == true;

      debugPrint("🛰️ Validate session result: $valid");
      return valid;
    } catch (e) {
      debugPrint("🛰️ Validate session error: $e");
      return false;
    }
  }

  Future<void> _clearSessionKeepDeviceId() async {
    final savedDeviceId = await _storage.read(key: "device_id");

    await _storage.deleteAll();

    if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
      await _storage.write(key: "device_id", value: savedDeviceId);
    }
  }

  void _goToLogin() {
    if (!mounted || _navigated) return;

    _navigated = true;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<http.Response?> _safeGet(Uri uri, Map<String, String> headers) async {
    for (int i = 0; i < 2; i++) {
      try {
        debugPrint("🌍 GET try ${i + 1}: $uri");

        final res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 5));

        return res;
      } catch (e) {
        debugPrint("🌍 GET failed try ${i + 1}: $e");
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return null;
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _beginAlign.value,
                    end: _endAlign.value,
                    colors: const [Color(0xff1d63ff), Color(0xff4fa9ff)],
                  ),
                ),
              );
            },
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/logo.png", width: 200, height: 200),
                    if (_checkingSession) const SizedBox(height: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoredProfile {
  final String? name;
  final String? role;
  final String? site;
  final String? department;
  final String? email;
  final String? employeeId;
  final int? userId;
  final int? siteId;
  final int? departmentId;
  final bool isValid;

  const _StoredProfile({
    required this.name,
    required this.role,
    required this.site,
    required this.department,
    required this.email,
    required this.employeeId,
    required this.userId,
    required this.siteId,
    required this.departmentId,
    required this.isValid,
  });
}
