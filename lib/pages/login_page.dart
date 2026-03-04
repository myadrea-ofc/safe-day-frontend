import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/drawer/change_password.dart';
import 'package:safety_apps/firebase/firebase_notification_service.dart';
import 'package:safety_apps/network/device_info_plus.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _surface = Colors.white;
  static const Color _bg = Color(0xffeef2f7);
  static const Color _fieldFill = Color(0xfff6f8fb);

  BoxShadow get _softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 26,
    offset: const Offset(0, 12),
  );

  OutlineInputBorder _roundedNoBorder(double r) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(r),
    borderSide: BorderSide.none,
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fpNameController = TextEditingController();
  final TextEditingController fpEmailController = TextEditingController();
  final storage = const FlutterSecureStorage();

  bool isPasswordVisible = false;
  bool isLoggingIn = false;

  String? selectedSite;
  int? selectedSiteId;
  String? selectedDepartment;
  int? selectedDepartmentId;

  List<Map<String, dynamic>> siteList = [];
  List<Map<String, dynamic>> departmentList = [];

  bool loadingSites = true;
  bool loadingDepartments = false;

  @override
  void initState() {
    super.initState();
    resetForm();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      fetchSites();
    });

    // fetchSites();
  }

  void resetForm() {
    setState(() {
      nameController.clear();
      passwordController.clear();
      selectedSite = null;
      selectedSiteId = null;
      selectedDepartment = null;
      selectedDepartmentId = null;
      siteList.clear();
      departmentList.clear();
      loadingSites = true;
      loadingDepartments = false;
    });
  }

  Future<bool> isNetworkReady() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchSites() async {
    setState(() => loadingSites = true);
    int attempts = 0;

    while (attempts < 5) {
      if (!mounted) return;
      if (!await isNetworkReady()) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
        continue;
      }

      try {
        final res = await http.get(
          Uri.parse("http://safety.borneo.co.id/sites"),
          headers: {"Content-Type": "application/json"},
        );

        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          setState(() {
            siteList = data
                .map((e) => {"id": e["id"], "name": e["name"]})
                .toList();
            loadingSites = false;
          });
          return;
        } else {
          throw Exception("Failed to fetch sites");
        }
      } catch (_) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
    }

    if (mounted) setState(() => loadingSites = false);
  }

  Future<void> fetchDepartments(int siteId) async {
    setState(() => loadingDepartments = true);
    try {
      final res = await http.get(
        Uri.parse("http://safety.borneo.co.id/departments?site_id=$siteId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          departmentList = List<Map<String, dynamic>>.from(data);
          selectedDepartment = null;
          selectedDepartmentId = null;
          loadingDepartments = false;
        });
      } else {
        setState(() => loadingDepartments = false);
      }
    } catch (_) {
      setState(() => loadingDepartments = false);
    }
  }

  Future<void> handleLogin({int retryCount = 0}) async {
    if (isLoggingIn) return;

    if (selectedSite == null || selectedDepartment == null) {
      _showValidationDialog(context);
      return;
    }

    if (selectedSiteId == null || selectedDepartmentId == null) {
      _showValidationDialog(context);
      return;
    }

    setState(() => isLoggingIn = true);

    try {
      final String deviceId = await DeviceHelper.getInstallationId();

      if (deviceId.isEmpty) {
        throw Exception("Device ID tidak ditemukan");
      }

      await storage.write(key: "device_id", value: deviceId);

      final fcmToken = await FirebaseMessaging.instance.getToken();

      debugPrint("🔥 LOGIN FCM TOKEN: $fcmToken");

      final res = await http.post(
        Uri.parse("http://safety.borneo.co.id/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "password": passwordController.text,
          "site_id": selectedSiteId,
          "department_id": selectedDepartmentId,
          "device_id": deviceId,
          "fcm_token": fcmToken,
        }),
      );

      // ================= EMAIL REQUIRED =================
      if (res.statusCode == 428) {
        try {
          final data428 = jsonDecode(res.body);
          if (data428["code"] == "EMAIL_REQUIRED") {
            final email = await _showRequireEmailDialogModern(context);
            if (email == null) return;

            final saveRes = await http.post(
              Uri.parse("http://safety.borneo.co.id/login/set-email"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "name": nameController.text.trim(),
                "password": passwordController.text,
                "site_id": selectedSiteId,
                "department_id": selectedDepartmentId,
                "device_id": deviceId,
                "email": email,
                "fcm_token": fcmToken,
              }),
            );

            // Kalau masih konflik device → biarkan flow takeover jalan normal
            if (saveRes.statusCode == 409) {
              await _runTakeoverFlow(deviceId: deviceId, fcmToken: fcmToken);
              return;
            }

            if (saveRes.statusCode != 200) {
              String msg = "Gagal menyimpan email";
              try {
                msg = jsonDecode(saveRes.body)["message"] ?? msg;
              } catch (_) {}
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
              return;
            }

            final dataLogin = jsonDecode(saveRes.body);
            await _onLoginSuccess(dataLogin); // ✅ langsung ke homepage
            return;
          }
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terjadi kesalahan saat memproses email"),
            ),
          );
          return;
        }
      }

      if (res.statusCode == 409) {
        bool otpRequired = false;
        String msg = "Akun ini sedang login di device lain";

        try {
          final data409 = jsonDecode(res.body);
          otpRequired = (data409["otp_required"] == true);
          msg = data409["message"] ?? msg;
        } catch (_) {}

        if (!otpRequired) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          _showSessionConflictDialog(context);
          return;
        }

        await _runTakeoverFlow(deviceId: deviceId, fcmToken: fcmToken);
        return;
      }

      if (res.statusCode != 200) {
        String msg = "Login gagal";
        try {
          final data = jsonDecode(res.body);
          msg = data["message"] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final data = jsonDecode(res.body);
      await _onLoginSuccess(data);
      return;
    } catch (e) {
      if ((e is SocketException || e.toString().contains("Socket")) &&
          retryCount < 3) {
        await Future.delayed(const Duration(seconds: 1));
        return handleLogin(retryCount: retryCount + 1);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains("Socket")
                ? "Koneksi belum siap, coba lagi"
                : "Terjadi kesalahan saat login",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoggingIn = false);
    }
  }

  Future<void> _runTakeoverFlow({
    required String deviceId,
    required String? fcmToken,
  }) async {
    // 0) yakinkan user dulu (dialog takeover)
    final agreeTakeover = await _showForceLoginDialog(context);
    if (!agreeTakeover) return;

    // 1) dialog: kirim OTP?
    final okSend = await _showSendOtpDialog(context);
    if (!okSend) return;

    // 2) request OTP ke backend
    final reqOtp = await http.post(
      Uri.parse("http://safety.borneo.co.id/login-force/request-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text.trim(),
        "password": passwordController.text,
        "site_id": selectedSiteId,
        "department_id": selectedDepartmentId,
        "device_id": deviceId,
      }),
    );

    if (reqOtp.statusCode != 200) {
      String m = "Gagal mengirim OTP";
      try {
        final d = jsonDecode(reqOtp.body);
        m = d["message"] ?? m;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP terkirim. Silakan cek email.")),
    );

    // 3) dialog input OTP
    final otp = await _showOtpInputDialog(context);
    if (otp == null) return;

    // 4) confirm OTP + takeover + login sukses
    final confirm = await http.post(
      Uri.parse("http://safety.borneo.co.id/login-force/confirm"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text.trim(),
        "password": passwordController.text,
        "site_id": selectedSiteId,
        "department_id": selectedDepartmentId,
        "device_id": deviceId,
        "otp": otp,
        "fcm_token": fcmToken,
      }),
    );

    if (confirm.statusCode != 200) {
      String m = "OTP tidak valid";
      try {
        final d = jsonDecode(confirm.body);
        m = d["message"] ?? m;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }

    final data2 = jsonDecode(confirm.body);
    await _onLoginSuccess(data2);
  }

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Theme.of(context).platform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      return android.id ?? android.model;
    } else {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? "unknown_ios";
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartmentsData(int siteId) async {
    try {
      final res = await http.get(
        Uri.parse("http://safety.borneo.co.id/departments?site_id=$siteId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return [];
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    fpNameController.dispose();
    fpEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand, // ✅ penting: kasih tight constraints
              children: [
                // background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withOpacity(0.10),
                        _secondary.withOpacity(0.06),
                        _bg,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // dekorasi bubble
                Positioned(
                  top: -120,
                  right: -120,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _secondary.withOpacity(0.18),
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: -140,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withOpacity(0.12),
                    ),
                  ),
                ),

                // ✅ konten dibuat fill biar ScrollView punya size
                Positioned.fill(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: AbsorbPointer(
                        absorbing: isLoggingIn,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headerSection(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: loginCard(),
                            ),
                            footerSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget headerSection() {
    return Container(
      height: 255,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(42)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative soft bubbles
          Positioned(
            top: -30,
            left: -40,
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
            bottom: -45,
            right: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Image(
                      image: AssetImage("assets/logo.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "SAFE DAY",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "HSES Management System",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget loginCard() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [_softShadow],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 24,
                  color: _primary.withOpacity(0.9),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Secure Login",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          buildDropdown(
            label: "Site",
            icon: Icons.location_on_outlined,
            value: selectedSite,
            items: siteList
                .where((e) => e["name"] != null)
                .map((e) => e["name"].toString())
                .toList(),
            isLoading: loadingSites,
            onChanged: (val) {
              setState(() {
                selectedSite = val;
                final site = siteList.firstWhere((e) => e["name"] == val);
                selectedSiteId = site["id"];

                departmentList.clear();
                selectedDepartment = null;
                selectedDepartmentId = null;
              });
              fetchDepartments(selectedSiteId!);
            },
          ),

          buildDropdown(
            label: "Department",
            icon: Icons.apartment_outlined,
            value: selectedDepartment,
            items: departmentList
                .where((e) => e["department_name"] != null)
                .map((e) => e["department_name"].toString())
                .toList(),
            isLoading: loadingDepartments,
            onChanged: (val) {
              setState(() {
                selectedDepartment = val;
                selectedDepartmentId = departmentList.firstWhere(
                  (e) => e["department_name"] == val,
                )["id"];
              });
            },
          ),

          buildInput(
            controller: nameController,
            label: "Nama Lengkap",
            icon: Icons.person_outline,
          ),

          buildPasswordInput(),

          // ===== FORGOT PASSWORD LINK =====
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _showForgotPasswordDialog(),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: _primary.withOpacity(0.95),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoggingIn ? null : handleLogin, // ✅ sama
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoggingIn ? Colors.grey : _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: isLoggingIn
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget footerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // divider halus
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
              const SizedBox(width: 10),

              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // badge info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primary.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Pastikan Site & Department sesuai dan cek kembali password Anda.",
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Colors.black54,
                      fontWeight: FontWeight.w800,
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

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [UpperCaseTextFormatter()],
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(icon, color: _primary),
            filled: true,
            fillColor: Colors.transparent,
            border: _roundedNoBorder(16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Memuat $label...",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(icon, color: _primary),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: _roundedNoBorder(16),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: "Password",
            hintStyle: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: _primary),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black45,
              ),
              onPressed: () =>
                  setState(() => isPasswordVisible = !isPasswordVisible),
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: _roundedNoBorder(16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    // Local state khusus dialog (biar nggak ganggu form login)
    String? fpSelectedSite;
    int? fpSelectedSiteId;
    String? fpSelectedDepartment;
    int? fpSelectedDepartmentId;

    bool fpLoadingDepartments = false;
    bool fpSending = false;

    List<Map<String, dynamic>> fpDepartmentList = [];

    // prefill nama dari login (opsional, biar nyaman)
    fpNameController.text = nameController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: !fpSending,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> loadDepartments(int siteId) async {
              setLocal(() {
                fpLoadingDepartments = true;
                fpDepartmentList = [];
                fpSelectedDepartment = null;
                fpSelectedDepartmentId = null;
              });

              final deps = await fetchDepartmentsData(siteId);

              if (!mounted) return;
              setLocal(() {
                fpDepartmentList = deps;
                fpLoadingDepartments = false;
              });
            }

            Future<void> submitForgot() async {
              if (fpSending) return;

              if (fpSelectedSiteId == null || fpSelectedDepartmentId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pilih Site dan Department dulu"),
                  ),
                );
                return;
              }

              final fullName = fpNameController.text.trim();
              final email = fpEmailController.text.trim();

              if (fullName.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nama lengkap dan email wajib diisi"),
                  ),
                );
                return;
              }

              setLocal(() => fpSending = true);

              try {
                final res = await http.post(
                  Uri.parse("http://safety.borneo.co.id/forgot-password"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "site_id": fpSelectedSiteId,
                    "department_id": fpSelectedDepartmentId,
                    "name": fullName,
                    "email": email,
                  }),
                );

                if (res.statusCode != 200) {
                  String msg =
                      "Data tidak valid. Mohon cek dan masukkan data kembali.";
                  try {
                    final data = jsonDecode(res.body);
                    msg = data["message"] ?? msg;
                  } catch (_) {}

                  _showEmailFailedDialog(ctx, msg);
                  return;
                }

                // ✅ sukses: baru tutup dialog forgot password
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                _showEmailSuccessDialog();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Terjadi kesalahan saat mengirim email"),
                  ),
                );
              } finally {
                if (mounted) setLocal(() => fpSending = false);
              }
            }

            return Dialog(
              alignment: Alignment.center,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(ctx).unfocus(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 26,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ===== HEADER GRADIENT =====
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                10,
                                16,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xff1d63ff),
                                    Color(0xff4fa9ff),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(
                                      Icons.lock_reset_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Forgot Password",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Masukkan data untuk kirim instruksi reset.",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: fpSending
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ BODY SCROLLABLE
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  18,
                                ),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Site (reuse dropdown kamu)
                                    buildDropdown(
                                      label: "Site",
                                      icon: Icons.location_on_outlined,
                                      value: fpSelectedSite,
                                      items: siteList
                                          .where((e) => e["name"] != null)
                                          .map((e) => e["name"].toString())
                                          .toList(),
                                      isLoading: loadingSites,
                                      onChanged: (val) async {
                                        setLocal(() {
                                          fpSelectedSite = val;
                                          fpSelectedSiteId = null;
                                          fpSelectedDepartment = null;
                                          fpSelectedDepartmentId = null;
                                          fpDepartmentList = [];
                                        });

                                        if (val == null) return;

                                        final site = siteList.firstWhere(
                                          (e) => e["name"] == val,
                                        );
                                        final id = site["id"];

                                        setLocal(() => fpSelectedSiteId = id);

                                        await loadDepartments(id);
                                      },
                                    ),

                                    // Department
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff6f8fb),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.black12.withOpacity(
                                            0.06,
                                          ),
                                        ),
                                      ),
                                      child: fpLoadingDepartments
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                              child: LinearProgressIndicator(
                                                minHeight: 3,
                                              ),
                                            )
                                          : DropdownButtonFormField<String>(
                                              value: fpSelectedDepartment,
                                              isExpanded: true,
                                              items: fpDepartmentList
                                                  .where(
                                                    (e) =>
                                                        e["department_name"] !=
                                                        null,
                                                  )
                                                  .map(
                                                    (e) => DropdownMenuItem(
                                                      value:
                                                          e["department_name"]
                                                              .toString(),
                                                      child: Text(
                                                        e["department_name"]
                                                            .toString(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                setLocal(() {
                                                  fpSelectedDepartment = val;
                                                  if (val != null) {
                                                    fpSelectedDepartmentId =
                                                        fpDepartmentList.firstWhere(
                                                          (e) =>
                                                              e["department_name"] ==
                                                              val,
                                                        )["id"];
                                                  }
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                hintText: "Department",
                                                prefixIcon: Icon(
                                                  Icons.apartment_outlined,
                                                  color: Color(0xff1d63ff),
                                                ),
                                                filled: true,
                                                fillColor: Color(0xfff6f8fb),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide.none,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(14),
                                                      ),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                    ),

                                    // Nama lengkap
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff6f8fb),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.black12.withOpacity(
                                            0.06,
                                          ),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: fpNameController,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        inputFormatters: [
                                          UpperCaseTextFormatter(),
                                        ],
                                        decoration: const InputDecoration(
                                          hintText: "Nama Lengkap",
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                            color: Color(0xff1d63ff),
                                          ),
                                          filled: true,
                                          fillColor: Color(0xfff6f8fb),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(14),
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Email
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff6f8fb),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.black12.withOpacity(
                                            0.06,
                                          ),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: fpEmailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          hintText: "Alamat Email",
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: Color(0xff1d63ff),
                                          ),
                                          filled: true,
                                          fillColor: Color(0xfff6f8fb),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(14),
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // info kecil
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xff1d63ff,
                                        ).withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(
                                            0xff1d63ff,
                                          ).withOpacity(0.10),
                                        ),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: Color(0xff1d63ff),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Kami akan kirim instruksi reset ke email yang terdaftar.",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                height: 1.35,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: fpSending
                                                  ? null
                                                  : () =>
                                                        Navigator.of(ctx).pop(),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: const Color(
                                                    0xff1d63ff,
                                                  ).withOpacity(0.35),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                "BATAL",
                                                style: TextStyle(
                                                  color: Color(0xff1d63ff),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: fpSending
                                                  ? null
                                                  : submitForgot,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: fpSending
                                                    ? Colors.grey
                                                    : const Color(0xff1d63ff),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: fpSending
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Text(
                                                      "KIRIM",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.2,
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
                          ],
                        ),
                      ),
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

  Future<void> _onLoginSuccess(dynamic data) async {
    final bool mustChange = (data["user"]?["must_change_password"] == true);

    await storage.write(key: "jwt_token", value: data["token"]);
    await storage.write(key: "user_name", value: data["user"]["name"]);
    await storage.write(key: "site_name", value: selectedSite);
    await storage.write(key: "department_name", value: selectedDepartment);
    await storage.write(key: "site_id", value: selectedSiteId.toString());
    await storage.write(
      key: "department_id",
      value: selectedDepartmentId.toString(),
    );
    await storage.write(key: "user_email", value: data["user"]["email"] ?? "");
    await storage.write(
      key: "employee_id",
      value: (data["user"]["employee_id"] ?? "").toString(),
    );
    await storage.write(key: "user_id", value: data["user"]["id"].toString());
    await storage.write(key: "user_role", value: data["user"]["role"]);

    await FirebaseNotificationService.syncTokenAfterLogin();

    AuthSession.userId = data["user"]["id"];
    AuthSession.name = data["user"]["name"]?.toString();
    AuthSession.role = data["user"]["role"];
    AuthSession.siteId = selectedSiteId;
    AuthSession.departmentId = selectedDepartmentId;
    AuthSession.email = data["user"]?["email"]?.toString();
    AuthSession.employeeId = data["user"]?["employee_id"]?.toString();
    AuthSession.token = data["token"];
    AuthSession.markReady();

    if (mustChange) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ChangePasswordPage(hideBack: true),
        ),
        (_) => false,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: data["user"]["name"],
          role: data["user"]["role"],
          site: selectedSite!,
          department: selectedDepartment!,
        ),
      ),
      (_) => false,
    );
  }

  Future<bool> _showForceLoginDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: Colors.white,
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== ICON BUBBLE (mirip EmailSuccessDialog) =====
                Container(
                  width: 64,
                  height: 64,
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
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== TITLE =====
                const Text(
                  "Akun Sedang Digunakan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 8),

                // ===== MESSAGE =====
                const Text(
                  "Akun ini masih aktif di perangkat lain.\nLanjutkan untuk mengeluarkan perangkat tersebut dan masuk di sini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.8,
                    color: Colors.black54,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                // ===== INFO BOX =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff1d63ff).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xff1d63ff).withOpacity(0.10),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xff1d63ff),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Untuk keamanan, pastikan kamu yang melakukan login ini.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== BUTTONS =====
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xff1d63ff).withOpacity(0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "BATAL",
                            style: TextStyle(
                              color: Color(0xff1d63ff),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1d63ff),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "LANJUTKAN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _showRequireEmailDialogModern(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final c = TextEditingController();
    bool saving = false;
    String? errorText;

    bool isValidEmail(String v) {
      final email = v.trim();
      return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    }

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> onSave() async {
              final email = c.text.trim();

              if (email.isEmpty) {
                setLocal(() => errorText = "Email wajib diisi.");
                return;
              }
              if (!isValidEmail(email)) {
                setLocal(
                  () => errorText =
                      "Format email tidak valid. Contoh: nama@domain.com",
                );
                return;
              }

              // ✅ aktifkan loading
              setLocal(() {
                saving = true;
                errorText = null;
              });

              // ⚠️ Jangan dispose controller di sini.
              // ✅ Tutup dialog dan kembalikan email.
              // Delay 1 frame biar animasi/tap selesai rapi (opsional tapi bikin lebih halus)
              await Future.delayed(const Duration(milliseconds: 60));

              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop(email);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // ===== GLASS LAYER (BLUR) =====
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.white.withOpacity(0.18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                              ),
                            ),
                          ),
                        ),

                        // ===== CARD CONTENT =====
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.72),
                                Colors.white.withOpacity(0.48),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ===== HEADER =====
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  10,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xff1d63ff).withOpacity(0.95),
                                      const Color(0xff4fa9ff).withOpacity(0.90),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.alternate_email_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Tambahkan Email",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "Dibutuhkan untuk OTP & fitur lupa password.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12.6,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: saving
                                          ? null
                                          : () => Navigator.of(ctx).pop(null),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ===== CAPTION / INFO BOX =====
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xff1d63ff,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xff1d63ff,
                                          ).withOpacity(0.14),
                                        ),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: Color(0xff1d63ff),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Masukkan email aktif yang bisa menerima OTP. Kami akan gunakan untuk verifikasi login dan pemulihan akun.",
                                              style: TextStyle(
                                                fontSize: 12.7,
                                                height: 1.35,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // ===== EMAIL FIELD =====
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white.withOpacity(0.60),
                                        border: Border.all(
                                          color: Colors.black12.withOpacity(
                                            0.08,
                                          ),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: c,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        onChanged: (_) {
                                          if (errorText != null) {
                                            setLocal(() => errorText = null);
                                          }
                                        },
                                        onSubmitted: (_) {
                                          if (!saving) onSave();
                                        },
                                        decoration: InputDecoration(
                                          hintText: "contoh: nama@domain.com",
                                          labelText: "Alamat Email",
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xff1d63ff),
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 14,
                                              ),
                                          errorText:
                                              errorText, // ✅ inline error
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // ===== BUTTONS =====
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: saving
                                                  ? null
                                                  : () => Navigator.of(
                                                      ctx,
                                                    ).pop(null),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: const Color(
                                                    0xff1d63ff,
                                                  ).withOpacity(0.30),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                "BATAL",
                                                style: TextStyle(
                                                  color: Color(0xff1d63ff),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: saving ? null : onSave,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xff1d63ff,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: saving
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Text(
                                                      "SIMPAN & LANJUT",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.2,
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
                            ],
                          ),
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

    // ✅ dispose aman setelah dialog benar-benar selesai (menghindari "used after disposed")
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.dispose();
    });

    return result;
  }

  Future<bool> _showSendOtpDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(ctx).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 26,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ===== HEADER GRADIENT =====
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Verifikasi OTP",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Untuk memastikan ini benar-benar Anda.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Akun masih aktif di perangkat lain.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Kami akan mengirim OTP ke email terdaftar untuk mengizinkan login & mengeluarkan perangkat lain.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.4,
                                  height: 1.5,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // info box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xff1d63ff,
                                  ).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xff1d63ff,
                                    ).withOpacity(0.10),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Color(0xff1d63ff),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Jika ini bukan Anda, tekan Batal untuk menghentikan proses.",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.35,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 46,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: const Color(
                                              0xff1d63ff,
                                            ).withOpacity(0.35),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "BATAL",
                                          style: TextStyle(
                                            color: Color(0xff1d63ff),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 46,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff1d63ff,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          "KIRIM OTP",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.2,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _showOtpInputDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final controllers = List.generate(6, (_) => TextEditingController());
    final nodes = List.generate(6, (_) => FocusNode());

    String joinOtp() => controllers.map((e) => e.text).join();

    // ✅ state untuk resend
    int cooldown = 0;
    bool sendingResend = false;

    // ✅ ambil data yang dibutuhkan endpoint resend
    final String name = nameController.text.trim();
    final String password = passwordController.text;
    final int? siteId = selectedSiteId;
    final int? deptId = selectedDepartmentId;
    final String deviceId = await DeviceHelper.getInstallationId();

    // timer manual pakai Future loop (tanpa Timer) agar simpel dan aman di dialog
    bool ticking = false;
    Future<void> startCooldown(StateSetter setLocal) async {
      if (ticking) return;
      ticking = true;
      cooldown = 60;
      setLocal(() {});
      while (cooldown > 0) {
        await Future.delayed(const Duration(seconds: 1));
        cooldown--;
        // dialog masih hidup? setLocal masih valid selama builder aktif
        try {
          setLocal(() {});
        } catch (_) {
          break;
        }
      }
      ticking = false;
    }

    Future<void> resendOtp(StateSetter setLocal, BuildContext dialogCtx) async {
      if (sendingResend) return;
      if (cooldown > 0) return;

      if (siteId == null || deptId == null || deviceId.isEmpty) {
        _snack(context, "Data login belum lengkap untuk resend OTP.");
        return;
      }

      setLocal(() => sendingResend = true);

      try {
        final res = await http.post(
          Uri.parse("http://safety.borneo.co.id/login-force/request-otp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": name,
            "password": password,
            "site_id": siteId,
            "department_id": deptId,
            "device_id": deviceId,
          }),
        );

        if (res.statusCode == 200) {
          _snack(context, "OTP terkirim ulang. Cek inbox/spam.");
          await startCooldown(setLocal);
          return;
        }

        if (res.statusCode == 429) {
          final msg = _tryGetMessage(
            res.body,
            fallback: "OTP baru saja dikirim. Coba lagi sebentar.",
          );
          _snack(context, msg);
          // tetap mulai cooldown biar UX konsisten
          await startCooldown(setLocal);
          return;
        }

        if (res.statusCode == 400) {
          final msg = _tryGetMessage(
            res.body,
            fallback: "Tidak bisa resend OTP. Cek lagi status konflik session.",
          );
          _snack(context, msg);
          return;
        }

        if (res.statusCode == 401) {
          final msg = _tryGetMessage(
            res.body,
            fallback: "Password salah / user tidak cocok.",
          );
          _snack(context, msg);
          return;
        }

        final msg = _tryGetMessage(
          res.body,
          fallback: "Gagal mengirim OTP. Coba lagi.",
        );
        _snack(context, msg);
      } catch (e) {
        _snack(context, "Koneksi bermasalah. Coba lagi.");
      } finally {
        // dialog masih ada?
        try {
          setLocal(() => sendingResend = false);
        } catch (_) {}
      }
    }

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final canResend = cooldown == 0 && !sendingResend;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              elevation: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // ✅ blur glass
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.white.withOpacity(0.22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                          ),
                        ),

                        // ✅ konten card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.55),
                                Colors.white.withOpacity(0.35),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  10,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xff1d63ff).withOpacity(0.95),
                                      const Color(0xff4fa9ff).withOpacity(0.90),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Masukkan OTP",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "Kode 6 digit sudah dikirim ke email Anda.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(null),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // caption/info
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xff1d63ff,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xff1d63ff,
                                          ).withOpacity(0.14),
                                        ),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: Color(0xff1d63ff),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Cek inbox/spam. OTP berlaku beberapa menit. Jika belum masuk, kirim ulang OTP.",
                                              style: TextStyle(
                                                fontSize: 12.6,
                                                height: 1.35,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // OTP boxes
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (i) {
                                        return SizedBox(
                                          width: 44,
                                          child: TextField(
                                            controller: controllers[i],
                                            focusNode: nodes[i],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              counterText: "",
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.65),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: Colors.black12
                                                      .withOpacity(0.08),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xff1d63ff),
                                                  width: 1.6,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 14,
                                                  ),
                                            ),
                                            onChanged: (v) {
                                              if (v.isNotEmpty) {
                                                if (i < 5) {
                                                  FocusScope.of(
                                                    ctx,
                                                  ).requestFocus(nodes[i + 1]);
                                                } else {
                                                  FocusScope.of(ctx).unfocus();
                                                }
                                              } else {
                                                if (i > 0) {
                                                  FocusScope.of(
                                                    ctx,
                                                  ).requestFocus(nodes[i - 1]);
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      }),
                                    ),

                                    const SizedBox(height: 14),

                                    // resend row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              cooldown > 0
                                                  ? "Kirim ulang dalam ${cooldown}s"
                                                  : "Tidak menerima kode?",
                                              style: TextStyle(
                                                fontSize: 12.8,
                                                color: Colors.black.withOpacity(
                                                  0.55,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: canResend
                                              ? () => resendOtp(setLocal, ctx)
                                              : null,
                                          child: sendingResend
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  "KIRIM ULANG",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.2,
                                                    color: canResend
                                                        ? const Color(
                                                            0xff1d63ff,
                                                          )
                                                        : Colors.black26,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 46,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(null),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: const Color(
                                                    0xff1d63ff,
                                                  ).withOpacity(0.30),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                "BATAL",
                                                style: TextStyle(
                                                  color: Color(0xff1d63ff),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 46,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final otp = joinOtp();
                                                if (otp.length != 6) {
                                                  _snack(
                                                    context,
                                                    "OTP harus 6 digit",
                                                  );
                                                  return;
                                                }
                                                Navigator.of(ctx).pop(otp);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xff1d63ff,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                "VERIFIKASI",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.2,
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
                            ],
                          ),
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

    // ✅ dispose aman setelah dialog selesai total
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final x in controllers) x.dispose();
      for (final x in nodes) x.dispose();
    });

    return result;
  }

  void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _tryGetMessage(String body, {String fallback = "Terjadi kesalahan"}) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j["message"] != null) return j["message"].toString();
    } catch (_) {}
    return fallback;
  }

  void _showEmailSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
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
                  width: 64,
                  height: 64,
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
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Email Terkirim",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Silakan cek inbox/spam untuk langkah selanjutnya.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
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
}

void _showEmailFailedDialog(BuildContext ctx, String message) {
  showDialog(
    context: ctx,
    barrierDismissible: true,
    builder: (dctx) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (Navigator.of(dctx).canPop()) Navigator.of(dctx).pop();
      });

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xffFF5F6D), Color(0xffFF7A45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffFF5F6D).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Gagal Mengirim Email",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
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

void _showSessionConflictDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        }
      });

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== ICON =====
              Container(
                width: 64,
                height: 64,
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
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              const SizedBox(height: 16),

              // ===== TITLE =====
              const Text(
                "Akun Digunakan di Perangkat Lain",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              // ===== MESSAGE =====
              const Text(
                "Akun ini sedang login di device lain",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
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

void _showValidationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        }
      });

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== ICON =====
              Container(
                width: 64,
                height: 64,
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
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // ===== TITLE =====
              const Text(
                "Data Belum Lengkap",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              // ===== MESSAGE =====
              const Text(
                "Silakan pilih Site dan Department terlebih dahulu sebelum melanjutkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
