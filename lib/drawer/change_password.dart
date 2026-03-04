import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:safety_apps/pages/login_page.dart';
import 'package:safety_apps/service/user_service.dart';
import 'package:safety_apps/session/auth_session.dart';

class ChangePasswordPage extends StatefulWidget {
  final bool hideBack;

  const ChangePasswordPage({super.key, this.hideBack = false});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final storage = FlutterSecureStorage();

  bool showOld = false;
  bool showNew = false;
  bool showConfirm = false;
  bool isLoading = false;

  Future<void> handleSubmit() async {
    if (isLoading) return;

    if (oldPasswordCtrl.text.isEmpty ||
        newPasswordCtrl.text.isEmpty ||
        confirmPasswordCtrl.text.isEmpty) {
      showMessage(false, "Semua field wajib diisi");
      return;
    }

    final passwordError = validatePassword(newPasswordCtrl.text);
    if (passwordError != null) {
      showMessage(false, passwordError);
      return;
    }

    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
      showMessage(false, "Konfirmasi password tidak sama");
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await UserService.changePassword(
        oldPassword: oldPasswordCtrl.text,
        newPassword: newPasswordCtrl.text,
      );

      if (!success) {
        showMessage(false, "Password lama salah atau gagal");
        return;
      }

      oldPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();

      showMessage(true, "Password berhasil diubah. Silakan login ulang.");
    } catch (_) {
      showMessage(false, "Terjadi kesalahan saat mengganti password");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(bool success, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 80,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              success ? "Berhasil Disimpan" : "Gagal Menyimpan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              success ? "Password Berhasil Diganti" : "Password Gagal Diganti",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? Colors.green : Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  final storage = const FlutterSecureStorage();
                  final deviceId = await storage.read(key: "device_id");

                  try {
                    final headers = await UserService.getHeaders();
                    await http.post(
                      Uri.parse("${UserService.baseUrl}/logout"),
                      headers: headers,
                    );
                  } catch (_) {}

                  await storage.deleteAll();

                  if (deviceId != null) {
                    await storage.write(key: "device_id", value: deviceId);
                  }

                  AuthSession.clear();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.hideBack,
      child: Scaffold(
        backgroundColor: const Color(0xffeef2f7),
        body: Stack(
          children: [
            Container(
              height: 500,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      Icon(Icons.lock_reset, size: 50, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Ganti password akun Anda",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 200),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildPasswordInput(
                              controller: oldPasswordCtrl,
                              label: "Password Lama",
                              helper:
                                  "Masukkan password yang sedang digunakan saat ini.",
                              show: showOld,
                              onToggle: () =>
                                  setState(() => showOld = !showOld),
                            ),

                            const SizedBox(height: 8),
                            _buildHintChipRow(),
                            const SizedBox(height: 12),

                            buildPasswordInput(
                              controller: newPasswordCtrl,
                              label: "Password Baru",
                              helper:
                                  "Min. 8 karakter, max. 12, ada huruf kapital & angka.",
                              show: showNew,
                              onToggle: () =>
                                  setState(() => showNew = !showNew),
                            ),
                            buildPasswordInput(
                              controller: confirmPasswordCtrl,
                              label: "Konfirmasi Password",
                              helper:
                                  "Ketik ulang password baru untuk memastikan.",
                              show: showConfirm,
                              onToggle: () =>
                                  setState(() => showConfirm = !showConfirm),
                            ),

                            const SizedBox(height: 22),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff1d63ff),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isLoading ? null : handleSubmit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Simpan Password",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!widget.hideBack)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ chip kecil biar lebih “modern” (tanpa ubah logic)
  Widget _buildHintChipRow() {
    Widget chip(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xfff6f8fb),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xffe7edf6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xff1d63ff)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(Icons.password_rounded, "8–12 karakter"),
        chip(Icons.text_fields_rounded, "Huruf kapital"),
        chip(Icons.format_list_numbered, "Angka"),
      ],
    );
  }

  String? validatePassword(String password) {
    if (password.length < 8) {
      return "Password minimal 8 karakter";
    }
    if (password.length > 12) {
      return "Password maksimal 12 karakter";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password harus mengandung huruf kapital";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password harus mengandung angka";
    }
    return null;
  }

  // ✅ UI only: sekarang ada “label + helper” di atas field + field dalam card
  Widget buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String helper,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xfffbfcfe),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe7edf6)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              offset: Offset(0, 8),
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              helper,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black54,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: !show,
              decoration: InputDecoration(
                hintText: "Masukkan $label",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(show ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggle,
                ),
                filled: true,
                fillColor: const Color(0xfff6f8fb),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
