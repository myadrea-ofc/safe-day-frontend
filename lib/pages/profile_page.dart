import 'package:flutter/material.dart';

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
  static const Color _blue = Color(0xff1d63ff);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: Stack(
        children: [
          // ===== BACKGROUND GRADIENT HEADER =====
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: Stack(
              children: [
                // Decorative bubbles (halus)
                Positioned(
                  right: -60,
                  top: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  top: 90,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
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

                // Top bar (back + title)
                Positioned(
                  left: 12,
                  right: 12,
                  top: topPad + 10,
                  child: Row(
                    children: [
                      _iconPillButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      // spacer agar title benar2 center (seimbang)
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 92),

                // ===== GLASS CARD (identity) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        _premiumAvatar(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.80),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _chip(
                                icon: Icons.location_on_outlined,
                                text: widget.site,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== BOTTOM SHEET CARD =====
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // handle bar
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            "Informasi Akun",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 16),

                          _profileTile(
                            icon: Icons.badge_outlined,
                            label: "Nama",
                            value: widget.name,
                          ),
                          _profileTile(
                            icon: Icons.apartment_outlined,
                            label: "Department",
                            value: widget.department,
                          ),
                          _profileTile(
                            icon: Icons.location_on_outlined,
                            label: "Site",
                            value: widget.site,
                          ),

                          _profileTile(
                            icon: Icons.email_outlined,
                            label: "Email",
                            value: widget.email.isEmpty ? "-" : widget.email,
                          ),

                          _profileTile(
                            icon: Icons.perm_identity_rounded,
                            label: "Employee ID",
                            value: widget.employeeId.isEmpty
                                ? "-"
                                : widget.employeeId,
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _blue,
                                      side: BorderSide(
                                        color: _blue.withOpacity(0.35),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Kembali",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
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
    );
  }

  // ===== UI PARTS =====

  Widget _premiumAvatar() {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconPillButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff6f8fb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
