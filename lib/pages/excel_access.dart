import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safety_apps/service/master_services.dart';
import 'package:safety_apps/service/user_service.dart';
import 'package:safety_apps/service/excel_access_service.dart';

class GrantExcelAccessPage extends StatefulWidget {
  final String currentRole;
  final int? currentSiteId;
  final VoidCallback? onGranted;
  final String feature;
  final int currentUserId;

  const GrantExcelAccessPage({
    super.key,
    required this.currentRole,
    required this.currentSiteId,
    required this.currentUserId,
    required this.feature,
    this.onGranted,
  });

  @override
  State<GrantExcelAccessPage> createState() => _GrantExcelAccessPageState();
}

class _GrantExcelAccessPageState extends State<GrantExcelAccessPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _selectedUserCtrl = TextEditingController();

  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> users = [];

  int? selectedSiteId;
  int? selectedDepartmentId;
  int? selectedUserId;

  bool loadingPage = true;
  bool loadingDept = false;
  bool loadingUsers = false;
  bool submitting = false;

  int _userPage = 0;
  final int _userLimit = 50;
  bool _hasMoreUsers = true;

  bool get isSuperadmin => widget.currentRole.toLowerCase() == "superadmin";
  bool get isAdmin => widget.currentRole.toLowerCase() == "admin";

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedUserCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    try {
      if (isSuperadmin) {
        sites = await MasterService.getSites();

        if (sites.isNotEmpty) {
          selectedSiteId = sites.first["id"];
          await _loadDepartments(selectedSiteId!);
        }
      } else {
        selectedSiteId = widget.currentSiteId;
        if (selectedSiteId == null) {
          throw Exception("Site admin tidak ditemukan. Login ulang.");
        }
        await _loadDepartments(selectedSiteId!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal inisialisasi halaman: $e")));
    } finally {
      if (mounted) setState(() => loadingPage = false);
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

      _userPage = 0;
      _hasMoreUsers = true;
    });

    try {
      final data = await MasterService.getDepartments(siteId);
      setState(() => departments = data);
    } catch (e) {
      // optional
    } finally {
      if (mounted) setState(() => loadingDept = false);
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
        if (selectedSiteId != null) "site_id": selectedSiteId.toString(),
        "limit": _userLimit.toString(),
        "offset": (_userPage * _userLimit).toString(),
        "search": search,
        "role_name": "member",
        "exclude_user_id": widget.currentUserId.toString(),
      };

      final uri = Uri.parse(
        "${UserService.baseUrl}/users",
      ).replace(queryParameters: queryParameters);

      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        setState(() {
          users.addAll(data.map((e) => {"id": e["id"], "name": e["name"]}));
          _hasMoreUsers = data.length == _userLimit;
          if (_hasMoreUsers) _userPage++;
        });
      } else {
        throw Exception("Gagal load users: ${res.statusCode}");
      }
    } catch (e) {
      if (reset) setState(() => users.clear());
    } finally {
      if (mounted) setState(() => loadingUsers = false);
    }
  }

  Future<void> _selectUser() async {
    if (selectedDepartmentId == null) return;

    String search = "";
    await _loadUsers(reset: true);

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scrollController = ScrollController();

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

                final ia = aName.indexOf(q);
                final ib = bName.indexOf(q);
                if (ia != ib) return ia.compareTo(ib);

                return aName.compareTo(bName);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_search_rounded,
                              color: Color(0xFF1D63FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pilih User",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Cari user berdasarkan nama",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Cari nama user...",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
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
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) {
                            search = val;
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                            itemCount:
                                filteredUsers.length + (showLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= filteredUsers.length) {
                                return showLoadMore
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
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
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => Navigator.pop(context, u),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF2FF),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: Color(0xFF1D63FF),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              u["name"],
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.chevron_right_rounded,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (loadingUsers && search.isEmpty)
                            Positioned(
                              top: 8,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
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

  Future<void> _handleGrant() async {
    if (selectedSiteId == null) {
      _showResultDialog(false, "Site wajib dipilih");
      return;
    }
    if (selectedDepartmentId == null) {
      _showResultDialog(false, "Department wajib dipilih");
      return;
    }
    if (selectedUserId == null) {
      _showResultDialog(false, "User wajib dipilih");
      return;
    }

    setState(() => submitting = true);
    try {
      await ExcelAccessService.grant(
        userId: selectedUserId!,
        siteId: selectedSiteId!,
        feature: widget.feature,
      );

      widget.onGranted?.call();

      if (!mounted) return;
      _showResultDialog(true, "Akses download berhasil diberikan");
      setState(() {
        selectedUserId = null;
        _selectedUserCtrl.clear();
      });
    } catch (e) {
      _showResultDialog(false, e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _showResultDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: success
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 30,
                  color: success
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                success ? "Berhasil Disimpan" : "Gagal Menyimpan",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE11D48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _field({
    required String title,
    String? subtitle,
    required Widget child,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF1D63FF)),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1D63FF), width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D63FF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// BACK + TITLE
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _headerIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    "Grant Excel Access",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// ICON + DESCRIPTION
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.file_open_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Text(
                    "Berikan akses download file Excel untuk user yang dipilih",
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingPage) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (isSuperadmin)
                          _field(
                            title: "Site",
                            subtitle: "Pilih site tujuan akses download",
                            icon: Icons.location_on_outlined,
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
                          title: "Department",
                          subtitle: "Pilih department user",
                          icon: Icons.apartment_outlined,
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
                                    setState(() => selectedDepartmentId = val);
                                    if (val != null) {
                                      await _loadUsers(reset: true);
                                    }
                                  },
                          ),
                        ),

                        _field(
                          title: "User",
                          subtitle: "Pilih user yang akan diberi akses",
                          icon: Icons.person_rounded,
                          child: GestureDetector(
                            onTap: loadingUsers ? null : _selectUser,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _selectedUserCtrl,
                                decoration: _input("Ketuk untuk mencari user")
                                    .copyWith(
                                      suffixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D63FF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: submitting ? null : _handleGrant,
                            child: submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.verified_user_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Berikan Akses Download",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}
