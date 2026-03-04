import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_apps/service/master_services.dart';
import 'package:safety_apps/service/user_service.dart';

class AddMemberFormCard extends StatefulWidget {
  const AddMemberFormCard({super.key});

  @override
  State<AddMemberFormCard> createState() => _AddMemberFormCardState();
}

class _AddMemberFormCardState extends State<AddMemberFormCard> {
  final nameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  bool showPassword = false;
  bool loadingSubmit = false;
  bool loadingSite = true;
  bool loadingDept = false;

  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> departments = [];

  int? selectedSiteId;
  int? selectedDepartmentId;

  String? userRole;
  int? userSiteId;

  String selectedRole = "member";

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    passwordCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final profile = await UserService.getProfile();
    userRole = profile["role"];
    userSiteId = profile["site_id"];

    if (userRole == "admin") {
      selectedSiteId = userSiteId;
      await _loadDepartments(userSiteId!);
      loadingSite = false;
    } else {
      await _loadSites();
    }

    setState(() {});
  }

  Future<void> _loadSites() async {
    try {
      sites = await MasterService.getSites();
    } finally {
      loadingSite = false;
    }
  }

  Future<void> _loadDepartments(int siteId) async {
    setState(() {
      loadingDept = true;
      departments.clear();
      selectedDepartmentId = null;
    });

    final data = await MasterService.getDepartments(siteId);

    setState(() {
      departments = data;
      loadingDept = false;
    });
  }

  Future<void> _handleSubmit() async {
    final email = emailCtrl.text.trim();
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailOk) {
      _showDialog(false, "Format email tidak valid");
      return;
    }
    if (selectedSiteId == null ||
        selectedDepartmentId == null ||
        nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty) {
      _showDialog(false, "Semua field wajib diisi");
      return;
    }

    if (selectedRole == "superadmin" && userRole != "superadmin") {
      _showDialog(false, "Anda tidak memiliki izin membuat Super Admin");
      return;
    }

    setState(() => loadingSubmit = true);

    try {
      await UserService.addUser(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        role: selectedRole,
        departmentId: selectedDepartmentId!,
        siteId: selectedSiteId,
      );

      _showDialog(true, "Member berhasil ditambahkan");
      nameCtrl.clear();
      passwordCtrl.clear();
      emailCtrl.clear();

      setState(() {
        selectedDepartmentId = null;
        departments.clear();
      });
    } catch (e) {
      _showDialog(false, e.toString());
    } finally {
      setState(() => loadingSubmit = false);
    }
  }

  void _showDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              success ? "Berhasil" : "Gagal",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingSite) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ===== FORM =====
                      _field(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedRole,
                          decoration: _input("Role User"),
                          items: [
                            if (userRole == "superadmin")
                              const DropdownMenuItem(
                                value: "superadmin",
                                child: Text("Superadmin"),
                              ),
                            const DropdownMenuItem(
                              value: "member",
                              child: Text("Member"),
                            ),
                            const DropdownMenuItem(
                              value: "admin",
                              child: Text("Admin"),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedRole = val!),
                        ),
                      ),

                      if (userRole == "superadmin")
                        _field(
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: selectedSiteId,
                            decoration: _input("Site"),
                            items: sites
                                .map(
                                  (s) => DropdownMenuItem<int>(
                                    value: s["id"],
                                    child: Text(
                                      s["name"],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => selectedSiteId = val);
                              if (val != null) _loadDepartments(val);
                            },
                          ),
                        ),

                      _field(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedDepartmentId,
                          decoration: _input("Department"),
                          items: departments
                              .map(
                                (d) => DropdownMenuItem<int>(
                                  value: d["id"],
                                  child: Text(
                                    d["name"],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: loadingDept
                              ? null
                              : (val) =>
                                    setState(() => selectedDepartmentId = val),
                        ),
                      ),

                      _field(
                        child: TextField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          decoration: _input("Nama Lengkap"),
                        ),
                      ),

                      _field(
                        child: TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _input("Email"),
                        ),
                      ),

                      _field(
                        child: TextField(
                          controller: passwordCtrl,
                          obscureText: !showPassword,
                          decoration: _input("Password").copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1d63ff),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: loadingSubmit ? null : _handleSubmit,
                          child: loadingSubmit
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Simpan User",
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
    );
  }

  Widget _field({required Widget child}) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xff5f6c7b),
      ),
      filled: true,
      fillColor: const Color(0xfff6f8fb),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
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
