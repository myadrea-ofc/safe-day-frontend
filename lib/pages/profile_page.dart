import 'package:flutter/material.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/app_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  final String site;
  final String department;
  final String name;
  final String email;
  final String employeeId;

  const ProfilePage({
    super.key,
    required this.site,
    required this.department,
    required this.name,
    required this.email,
    required this.employeeId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);

  static const Color _bg = Color(0xfff5f8ff);
  static const Color _surface = Colors.white;
  static const Color _textPrimary = Color(0xff0f172a);
  static const Color _textSecondary = Color(0xff64748b);
  static const Color _line = Color(0xffe2e8f0);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    final currentName = AuthSession.name ?? widget.name;
    final currentSite = AuthSession.siteName ?? widget.site;
    final currentDepartment = AuthSession.departmentName ?? widget.department;
    final currentEmail = (AuthSession.email?.isNotEmpty ?? false)
        ? AuthSession.email!
        : widget.email;
    final currentEmployeeId = (AuthSession.employeeId?.isNotEmpty ?? false)
        ? AuthSession.employeeId!
        : widget.employeeId;

    return Scaffold(
      extendBody: true,
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildBackground(topPad),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildAppBar(),
                const SizedBox(height: 14),

                // content fixed, no scrolling
                // ======= BAGIAN INI SAJA YANG DIUBAH (BUILD METHOD) =======
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Column(
                        children: [
                          _buildHeroCard(
                            name: currentName,
                            department: currentDepartment,
                            site: currentSite,
                            employeeId: currentEmployeeId,
                          ),
                          const SizedBox(height: 14),

                          // ✅ FIX: HAPUS SEMUA EXPANDED DI SINI
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.08),
                                  blurRadius: 26,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        gradient: const LinearGradient(
                                          colors: [_primary, _secondary],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Account Information",
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // ✅ FIX: TIDAK ADA EXPANDED
                                _profileTile(
                                  icon: Icons.person_rounded,
                                  label: "Nama",
                                  value: currentName,
                                ),
                                const SizedBox(height: 10),

                                _profileTile(
                                  icon: Icons.apartment_rounded,
                                  label: "Department",
                                  value: currentDepartment,
                                ),
                                const SizedBox(height: 10),

                                _profileTile(
                                  icon: Icons.location_on_rounded,
                                  label: "Site",
                                  value: currentSite,
                                ),
                                const SizedBox(height: 10),

                                _profileTile(
                                  icon: Icons.email_rounded,
                                  label: "Email",
                                  value: currentEmail.isEmpty
                                      ? "-"
                                      : currentEmail,
                                ),
                                const SizedBox(height: 10),

                                _profileTile(
                                  icon: Icons.badge_rounded,
                                  label: "Employee ID",
                                  value: currentEmployeeId.isEmpty
                                      ? "-"
                                      : currentEmployeeId,
                                ),
                              ],
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
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        role: AuthSession.role ?? "member",
        site: currentSite,
        department: currentDepartment,
        name: currentName,
      ),
    );
  }

  Widget _buildBackground(double topPad) {
    return Stack(
      children: [
        Container(
          height: 250 + topPad,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
          ),
        ),
        Positioned(
          top: -35,
          right: -25,
          child: _bubble(150, Colors.white.withOpacity(0.12)),
        ),
        Positioned(
          top: 90,
          left: -35,
          child: _bubble(110, Colors.white.withOpacity(0.08)),
        ),
        Positioned(
          top: 160,
          right: 40,
          child: _bubble(70, Colors.white.withOpacity(0.08)),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SizedBox(width: 40),
          Expanded(
            child: Text(
              "My Profile",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String name,
    required String department,
    required String site,
    required String employeeId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _heroBadge(
                  icon: Icons.location_on_outlined,
                  label: "Site",
                  value: site,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroBadge(
                  icon: Icons.badge_outlined,
                  label: "ID",
                  value: currentSafe(employeeId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 70,
      height: 70,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.30),
            Colors.white.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: const LinearGradient(
            colors: [_primary, _secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfdff),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(0.14),
                  _secondary.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  String _getInitials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.isEmpty) return "U";
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  String currentSafe(String value) {
    return value.isEmpty ? "-" : value;
  }
}
