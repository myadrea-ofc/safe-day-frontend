import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safety_apps/service/master_services.dart';
import 'package:safety_apps/service/user_service.dart';

class ChangeRolePage extends StatefulWidget {
  const ChangeRolePage({super.key});

  @override
  State<ChangeRolePage> createState() => _ChangeRolePageState();
}

class _ChangeRolePageState extends State<ChangeRolePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _selectedUserCtrl = TextEditingController();

  String? userRole;
  int? userSiteId;

  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> users = [];

  int? selectedSiteId;
  int? selectedDepartmentId;
  int? selectedUserId;
  String selectedRole = "member";

  bool loadingPage = true;
  bool loadingDept = false;
  bool loadingUsers = false;
  bool submitting = false;

  int _userPage = 0;
  final int _userLimit = 50;
  bool _hasMoreUsers = true;

  @override
  void dispose() {
    _searchController.dispose();
    _selectedUserCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    try {
      final profile = await UserService.getProfile();
      userRole = profile["role"];
      userSiteId = profile["site_id"];

      if (userRole == "superadmin") {
        sites = await MasterService.getSites();

        if (sites.isNotEmpty) {
          selectedSiteId = sites.first["id"]; // 🔥 INI KUNCI
          await _loadDepartments(selectedSiteId!);
        }
      } else {
        selectedSiteId = userSiteId;
        await _loadDepartments(userSiteId!);
      }
    } catch (e) {
      print("❌ Error init page: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal load profile: $e")));
    } finally {
      setState(() => loadingPage = false);
    }
  }

  Future<void> _loadDepartments(int siteId) async {
    setState(() {
      loadingDept = true;
      departments.clear();
      selectedDepartmentId = null;
      users.clear();
      selectedUserId = null;
      _selectedUserCtrl.clear();
    });

    try {
      final data = await MasterService.getDepartments(siteId);
      setState(() {
        departments = data;
      });
    } catch (e) {
      print("Error load departments: $e");
    } finally {
      setState(() => loadingDept = false);
    }
  }

  Future<void> _loadUsers({bool reset = false, String search = ""}) async {
    if (selectedDepartmentId == null) return;

    if (!reset && !_hasMoreUsers) return;

    if (reset) {
      _userPage = 0;
      _hasMoreUsers = true;
      users.clear();
      selectedUserId = null;
      _selectedUserCtrl.clear();
    }

    setState(() => loadingUsers = true);

    try {
      final headers = await UserService.getHeaders(json: false);

      final queryParameters = {
        "department_id": selectedDepartmentId.toString(),
        if (selectedSiteId != null && userRole == "superadmin")
          "site_id": selectedSiteId.toString(),
        "limit": _userLimit.toString(),
        "offset": (_userPage * _userLimit).toString(),
        "search": search,
      };

      final uri = Uri.parse(
        "${UserService.baseUrl}/users",
      ).replace(queryParameters: queryParameters);

      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          users.addAll(
            data.map((e) => {"id": e["id"], "name": e["name"]}).toList(),
          );
          _hasMoreUsers = data.length == _userLimit;
          if (_hasMoreUsers) _userPage++;
        });
      } else {
        throw Exception("Gagal load users: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Error load users: $e");
      if (reset) setState(() => users.clear());
    } finally {
      setState(() => loadingUsers = false);
    }
  }

  Future<void> _selectUser() async {
    if (selectedDepartmentId == null) return;

    String search = "";
    await _loadUsers(reset: true);

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        ScrollController scrollController = ScrollController();

        scrollController.addListener(() {
          if (search.isNotEmpty) return;

          if (scrollController.position.pixels >=
                  scrollController.position.maxScrollExtent - 50 &&
              _hasMoreUsers &&
              !loadingUsers) {
            _loadUsers();
          }
        });

        return StatefulBuilder(
          builder: (context, setModalState) {
            final showLoadMore = search.isEmpty && _hasMoreUsers;
            final q = search.toLowerCase().trim();

            List<Map<String, dynamic>> filteredUsers = users.where((u) {
              if (q.isEmpty) return true;
              final name = (u["name"] ?? "").toString().toLowerCase();
              return name.contains(q);
            }).toList();

            if (q.isNotEmpty) {
              int rank(String name) {
                if (name.startsWith(q)) return 0;
                final wholeWord = RegExp(
                  r'(^|[\s\W])' + RegExp.escape(q) + r'([\s\W]|$)',
                );
                if (wholeWord.hasMatch(name)) return 1;
                if (name.contains(q)) return 2;

                return 3;
              }

              filteredUsers.sort((a, b) {
                final aName = (a["name"] ?? "").toString().toLowerCase();
                final bName = (b["name"] ?? "").toString().toLowerCase();

                final ra = rank(aName);
                final rb = rank(bName);
                if (ra != rb) return ra.compareTo(rb);

                // tie-breaker: yang posisi kemunculan q lebih awal dulu
                final ia = aName.indexOf(q);
                final ib = bName.indexOf(q);
                if (ia != ib) return ia.compareTo(ib);

                // tie-breaker terakhir: alfabet
                return aName.compareTo(bName);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // SEARCH FIELD
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Cari nama user...",
                            hintStyle: const TextStyle(color: Colors.black38),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () async {
                                      _searchController.clear();
                                      search = "";
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xfff6f8fb),
                          ),
                          onChanged: (val) async {
                            search = val;
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),

                    Expanded(
                      child: Stack(
                        children: [
                          // 🔹 LIST TETAP MUNCUL (INI KUNCI UX)
                          ListView.builder(
                            controller: scrollController,
                            itemCount:
                                filteredUsers.length + (showLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= filteredUsers.length) {
                                return showLoadMore
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final u = filteredUsers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  elevation: 1.5,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.pop(context, u),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(
                                              0xffe3ebff,
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: Color(0xff1d63ff),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              u["name"],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // 🔹 LOADING KECIL (TIDAK MENUTUP LIST)
                          if (loadingUsers && search.isEmpty)
                            Positioned(
                              top: 8,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => selectedUserId = selected["id"]);
      _selectedUserCtrl.text = (selected["name"] ?? "").toString();
    }
  }

  Future<void> _handleSubmit() async {
    if (selectedUserId == null) {
      _showDialog(false, "User wajib dipilih");
      return;
    }

    if (selectedRole == "superadmin" && userRole != "superadmin") {
      _showDialog(false, "Anda tidak memiliki izin mengubah ke Superadmin");
      return;
    }

    setState(() => submitting = true);
    try {
      await UserService.changeUserRole(
        userId: selectedUserId!,
        role: selectedRole,
      );
      _showDialog(true, "Role berhasil diubah");

      setState(() {
        selectedUserId = null;
        selectedRole = "member";
      });

      _selectedUserCtrl.clear();
      _searchController.clear();
    } catch (e) {
      _showDialog(false, e.toString());
    } finally {
      setState(() => submitting = false);
    }
  }

  void _showDialog(bool success, String message) {
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
            Text(message, style: const TextStyle(color: Colors.black54)),
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
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: const Color(0xfff6f8fb),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingPage) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
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
                        children: [
                          if (userRole == "superadmin")
                            _field(
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: _input("Site"),
                                initialValue: selectedSiteId,
                                items: sites
                                    .map(
                                      (s) => DropdownMenuItem<int>(
                                        value: s["id"],
                                        child: Text(s["name"]),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) async {
                                  setState(() => selectedSiteId = val);
                                  if (val != null) await _loadDepartments(val);
                                },
                              ),
                            ),
                          _field(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              decoration: _input("Department"),
                              initialValue: selectedDepartmentId,
                              items: departments
                                  .map(
                                    (d) => DropdownMenuItem<int>(
                                      value: d["id"],
                                      child: Text(d["name"]),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (loadingDept || departments.isEmpty)
                                  ? null
                                  : (val) async {
                                      setState(() {
                                        selectedDepartmentId = val;
                                      });

                                      if (val != null) {
                                        await _loadUsers(reset: true);
                                      }
                                    },
                            ),
                          ),
                          _field(
                            child: GestureDetector(
                              onTap: loadingUsers ? null : _selectUser,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _selectedUserCtrl,
                                  decoration: _input(
                                    "Ketuk untuk mencari user",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _field(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: _input("Role Baru"),
                              initialValue: selectedRole,
                              items: [
                                const DropdownMenuItem(
                                  value: "member",
                                  child: Text("Member"),
                                ),
                                const DropdownMenuItem(
                                  value: "admin",
                                  child: Text("Admin"),
                                ),
                                if (userRole == "superadmin")
                                  const DropdownMenuItem(
                                    value: "superadmin",
                                    child: Text("Superadmin"),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => selectedRole = val!),
                            ),
                          ),
                          const SizedBox(height: 30),
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
                              onPressed: submitting ? null : _handleSubmit,
                              child: submitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Simpan Perubahan",
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
    );
  }
}
