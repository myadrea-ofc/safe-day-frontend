// ================= SPLASH PAGE =================
import 'dart:convert';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();

    // ===== LOGO ANIMATION =====
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

    // ===== BACKGROUND ANIMATION =====
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

    // 🔥 TUNGGU FRAME PERTAMA, BARU CEK SESSION
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<bool> isNetworkReady() async {
    try {
      final result = await InternetAddress.lookup('safety.borneo.co.id');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkSession() async {
    setState(() => _checkingSession = true);

    await Future.delayed(const Duration(seconds: 2));

    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (!mounted) return;

    bool ready = false;
    int tries = 0;
    while (!ready && tries < 5) {
      ready = await isNetworkReady();
      if (!ready) {
        tries++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (!ready) {
      if (!mounted) return;

      await _showAutoCloseDialog(
        context,
        title: "Koneksi Bermasalah",
        message: "Koneksi internet belum siap.\nPeriksa jaringan Anda.",
      );
      if (!mounted) return;

      _goToLogin();
      return;
    }

    if (token == null ||
        token.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      _goToLogin();
      return;
    }

    // Ambil semua data dari storage
    final name = await _storage.read(key: "user_name");
    final role = await _storage.read(key: "user_role");
    final site = await _storage.read(key: "site_name");
    final department = await _storage.read(key: "department_name");
    final userIdStr = await _storage.read(key: "user_id");
    final siteIdStr = await _storage.read(key: "site_id");
    final departmentIdStr = await _storage.read(key: "department_id");

    if (name == null ||
        role == null ||
        site == null ||
        department == null ||
        userIdStr == null ||
        siteIdStr == null ||
        departmentIdStr == null) {
      final savedDeviceId = await _storage.read(key: "device_id");
      await _storage.deleteAll();
      if (savedDeviceId != null) {
        await _storage.write(key: "device_id", value: savedDeviceId);
      }
      _goToLogin();
      return;
    }

    // Restore AuthSession
    AuthSession.token = token;
    AuthSession.role = role;
    AuthSession.userId = int.parse(userIdStr);
    AuthSession.siteId = int.parse(siteIdStr);
    AuthSession.departmentId = int.parse(departmentIdStr);

    // VALIDASI SESSION KE BACKEND
    try {
      final res = await _safeGet(
        Uri.parse("http://safety.borneo.co.id/validate-session"),
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "x-device-id": deviceId,
        },
      );

      if (res == null || res.statusCode != 200) {
        throw Exception("Network not ready");
      }

      final data = jsonDecode(res.body);
      if (data["valid"] != true) {
        await _storage.deleteAll();
        AuthSession.clear();
        _goToLogin();
        return;
      }
    } catch (_) {
      await _storage.deleteAll();
      AuthSession.clear();
      _goToLogin();
      return;
    }

    // SEMUA OK → LANJUT KE HOME
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: name,
          role: role,
          site: site,
          department: department,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _showAutoCloseDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // ambil navigator sekali
        final nav = Navigator.of(ctx, rootNavigator: true);

        Future.delayed(const Duration(seconds: 2), () {
          try {
            if (nav.canPop()) nav.pop();
          } catch (_) {}
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white,
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff1d63ff).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    setState(() => _checkingSession = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<http.Response?> _safeGet(Uri uri, Map<String, String> headers) async {
    for (int i = 0; i < 2; i++) {
      try {
        final res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 5));
        return res;
      } catch (_) {
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
