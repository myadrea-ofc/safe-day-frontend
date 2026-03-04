import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/add_member_page.dart';
import 'package:safety_apps/drawer/change_role.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: const SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Manajemen User",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Kelola akun & hak akses pengguna",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 140),

                _segmentedButton(),

                const SizedBox(height: 16),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: selectedTab == 0
                        ? const AddMemberFormCard(key: ValueKey("add"))
                        : const ChangeRolePage(key: ValueKey("role")),
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

  // ===== SEGMENTED BUTTON WIDGET =====
  Widget _segmentedButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton(
            title: "Add User",
            icon: Icons.person_add,
            isActive: selectedTab == 0,
            onTap: () => setState(() => selectedTab = 0),
          ),
          _tabButton(
            title: "Change Role",
            icon: Icons.manage_accounts,
            isActive: selectedTab == 1,
            onTap: () => setState(() => selectedTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xff1d63ff) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
