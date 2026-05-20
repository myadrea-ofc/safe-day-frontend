import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:safety_apps/constants/excel_acess_features.dart';
import 'package:safety_apps/drawer/access_permission.dart';
import 'package:safety_apps/drawer/excel_access_request.dart';
import 'package:safety_apps/network/api_client.dart';
import 'package:safety_apps/pages/home_page.dart';
import 'package:safety_apps/pages/pending_submisson.dart';
import 'package:safety_apps/pages/profile_page.dart';
import 'package:safety_apps/service/pending/pending_submission_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/session/permission_refresh.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final String role;
  final String site;
  final String department;
  final String name;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.site,
    required this.department,
    required this.name,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int pendingCount = 0;
  int accessBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllCounts();
    PermissionRefresh.excelAccessVersion.addListener(_handleAccessRefresh);
  }

  @override
  void dispose() {
    PermissionRefresh.excelAccessVersion.removeListener(_handleAccessRefresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadAllCounts();
  }

  void _handleAccessRefresh() {
    if (!mounted) return;
    _loadAccessBadgeCount();
  }

  Future<void> _loadAllCounts() async {
    await Future.wait([_loadPendingCount(), _loadAccessBadgeCount()]);
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await PendingSubmissionService.countPendingOnly();
      if (!mounted) return;

      setState(() {
        pendingCount = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        pendingCount = 0;
      });
    }
  }

  Future<void> _loadAccessBadgeCount() async {
    final resolvedRole = (AuthSession.role ?? widget.role).toLowerCase().trim();

    try {
      if (resolvedRole == "member") {
        final bulkRes = await ApiClient.get("/excel-access-requests/me");

        if (bulkRes.statusCode == 200) {
          final decoded = jsonDecode(bulkRes.body);

          if (decoded is List) {
            final rows = decoded
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            final approved = rows
                .where((e) => (e["status"] ?? "").toString() == "approved")
                .length;

            final rejected = rows
                .where((e) => (e["status"] ?? "").toString() == "rejected")
                .length;

            if (!mounted) return;
            setState(() {
              accessBadgeCount = approved + rejected;
            });
            return;
          }
        }

        int approved = 0;
        int rejected = 0;

        for (final item in kExcelAccessFeatures) {
          final feature = (item["key"] ?? "").trim();
          if (feature.isEmpty) continue;

          final res = await ApiClient.get(
            "/excel-access-requests/me?feature=$feature",
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data != null) {
              final status = (data["status"] ?? "none").toString();
              if (status == "approved") approved++;
              if (status == "rejected") rejected++;
            }
          }
        }

        if (!mounted) return;
        setState(() {
          accessBadgeCount = approved + rejected;
        });
      } else if (resolvedRole == "admin" || resolvedRole == "superadmin") {
        final res = await ApiClient.get(
          "/excel-access-requests?status=pending",
        );

        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);

          if (!mounted) return;
          setState(() {
            accessBadgeCount = data.length;
          });
        } else {
          if (!mounted) return;
          setState(() {
            accessBadgeCount = 0;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          accessBadgeCount = 0;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        accessBadgeCount = 0;
      });
    }
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    final resolvedRole = (AuthSession.role ?? widget.role).toLowerCase().trim();
    final resolvedSite = AuthSession.siteName ?? widget.site;
    final resolvedDepartment = AuthSession.departmentName ?? widget.department;
    final resolvedName = AuthSession.name ?? widget.name;
    final resolvedEmail = AuthSession.email ?? "-";
    final resolvedEmployeeId = AuthSession.employeeId ?? "-";

    Widget targetPage;

    if (index == 0) {
      targetPage = HomePage(
        site: resolvedSite,
        department: resolvedDepartment,
        name: resolvedName,
        role: resolvedRole,
      );
    } else if (index == 1) {
      targetPage = resolvedRole == "member"
          ? const AccessPermissionPage(feature: "")
          : const ExcelAccessRequestPage(feature: "");
    } else if (index == 2) {
      targetPage = const PendingSubmissionPage();
    } else {
      targetPage = ProfilePage(
        site: resolvedSite,
        department: resolvedDepartment,
        name: resolvedName,
        email: resolvedEmail,
        employeeId: resolvedEmployeeId,
      );
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, __) => targetPage,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconWithBadge(
    IconData icon,
    bool isSelected, {
    required int count,
    Color badgeColor = Colors.redAccent,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: isSelected ? 21 : 20,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.78),
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedRole = (AuthSession.role ?? widget.role)
        .toLowerCase()
        .trim();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final items = [
      {"icon": Icons.home_rounded, "label": "Home"},
      {
        "icon": normalizedRole == "member"
            ? Icons.verified_user_rounded
            : Icons.inbox_rounded,
        "label": normalizedRole == "member" ? "Access" : "Request",
      },
      {"icon": Icons.schedule_send_rounded, "label": "Pending"},
      {"icon": Icons.person_rounded, "label": "Profile"},
    ];

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.95),
                    const Color(0xFF60A5FA).withOpacity(0.90),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.22),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = widget.currentIndex == index;
                    final icon = item["icon"] as IconData;
                    final label = item["label"] as String;
                    final isRequestTab =
                        index == 1 && normalizedRole != "member";
                    final isPendingTab = index == 2;

                    return Expanded(
                      child: InkWell(
                        onTap: () => _onTap(context, index),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? Colors.white.withOpacity(0.14)
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: isRequestTab
                                    ? _buildIconWithBadge(
                                        icon,
                                        isSelected,
                                        count: accessBadgeCount,
                                        badgeColor: Colors.redAccent,
                                      )
                                    : isPendingTab
                                    ? _buildIconWithBadge(
                                        icon,
                                        isSelected,
                                        count: pendingCount,
                                        badgeColor: Colors.redAccent,
                                      )
                                    : Icon(
                                        icon,
                                        size: isSelected ? 21 : 20,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.78),
                                      ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.78),
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
