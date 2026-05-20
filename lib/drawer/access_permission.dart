import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safety_apps/constants/excel_acess_features.dart';
import 'package:safety_apps/network/api_client.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/session/permission_refresh.dart';
import 'package:safety_apps/widgets/app_bottom_nav.dart';

class AccessPermissionPage extends StatefulWidget {
  final String? feature;

  const AccessPermissionPage({super.key, this.feature});

  @override
  State<AccessPermissionPage> createState() => _AccessPermissionPageState();
}

class _AccessPermissionPageState extends State<AccessPermissionPage> {
  bool loading = true;
  final Set<String> submittingFeatures = {};
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatusFilter = 'all';

  bool _matchesStatusFilter(String feature) {
    final hasAccess = hasAccessMap[feature] ?? false;
    final requestStatus = requestStatusMap[feature] ?? "none";

    switch (_selectedStatusFilter) {
      case 'approved':
        return hasAccess == true;
      case 'pending':
        return requestStatus == 'pending';
      case 'rejected':
        return requestStatus == 'rejected';
      case 'all':
      default:
        return true;
    }
  }

  int get totalFeatureCount => visibleFeatures.length;
  int get approvedCount => hasAccessMap.values.where((e) => e).length;
  int get pendingCount =>
      requestStatusMap.values.where((e) => e == "pending").length;
  int get rejectedCount =>
      requestStatusMap.values.where((e) => e == "rejected").length;

  Timer? _refreshTimer;
  String _searchQuery = "";

  List<Map<String, String>> get visibleFeatures {
    final target = (widget.feature ?? "").trim().toLowerCase();

    if (target.isEmpty) return kExcelAccessFeatures;

    return kExcelAccessFeatures
        .where((e) => (e["key"] ?? "").toLowerCase() == target)
        .toList();
  }

  List<Map<String, String>> get filteredFeatures {
    final query = _searchQuery.trim().toLowerCase();

    return visibleFeatures.where((item) {
      final key = item['key'] ?? '';
      final keyLower = key.toLowerCase();
      final labelLower = (item['label'] ?? '').toLowerCase();

      final matchSearch =
          query.isEmpty ||
          keyLower.contains(query) ||
          labelLower.contains(query);

      final matchStatus = _matchesStatusFilter(key);

      return matchSearch && matchStatus;
    }).toList();
  }

  final Map<String, bool> hasAccessMap = {};
  final Map<String, String> requestStatusMap = {};
  final Map<String, String?> rejectReasonMap = {};
  final Map<String, bool> isRevokedMap = {};

  String _pageTitle() {
    final f = (widget.feature ?? "").trim().toLowerCase();
    if (f.isEmpty) return "Access Permission";

    final matched = kExcelAccessFeatures
        .cast<Map<String, String>?>()
        .firstWhere(
          (e) => (e?["key"] ?? "").toLowerCase() == f,
          orElse: () => null,
        );

    return matched?["label"] ?? "Access Permission";
  }

  @override
  void initState() {
    super.initState();
    _init();
    PermissionRefresh.excelAccessVersion.addListener(_handleExcelAccessRefresh);
  }

  @override
  void dispose() {
    PermissionRefresh.excelAccessVersion.removeListener(
      _handleExcelAccessRefresh,
    );
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleExcelAccessRefresh() {
    if (!mounted) return;
    _init();
  }

  Future<void> _init() async {
    setState(() => loading = true);
    try {
      for (final item in visibleFeatures) {
        final feature = item["key"]!;

        final accessRes = await ApiClient.get(
          "/excel-access/me?feature=$feature",
        );
        if (accessRes.statusCode == 200) {
          final data = jsonDecode(accessRes.body);
          hasAccessMap[feature] = (data["can_download"] ?? false) == true;
        } else {
          hasAccessMap[feature] = false;
        }

        final reqRes = await ApiClient.get(
          "/excel-access-requests/me?feature=$feature",
        );
        if (reqRes.statusCode == 200) {
          final data = jsonDecode(reqRes.body);
          if (data == null) {
            requestStatusMap[feature] = "none";
            rejectReasonMap[feature] = null;
            isRevokedMap[feature] = false;
          } else {
            requestStatusMap[feature] = (data["status"] ?? "none").toString();
            rejectReasonMap[feature] = data["reject_reason"]?.toString();
            isRevokedMap[feature] = data["revoked"] == true;
          }
        } else {
          requestStatusMap[feature] = "none";
          rejectReasonMap[feature] = null;
          isRevokedMap[feature] = false;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _requestFeatureExportAccess({
    required String feature,
    required String label,
  }) async {
    final hasAccess = hasAccessMap[feature] ?? false;
    final requestStatus = requestStatusMap[feature] ?? "none";

    if (submittingFeatures.contains(feature)) return;
    if (hasAccess) return;
    if (requestStatus == "pending") return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.16),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Kirim Permintaan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  "Permintaan akan dikirim ke Admin site dan Superadmin untuk diproses.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontSize: 13.5,
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
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Kirim",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
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
    );

    if (ok != true) return;

    setState(() => submittingFeatures.add(feature));
    try {
      final res = await ApiClient.post(
        "/excel-access-requests",
        body: {"feature": feature},
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        final data = jsonDecode(res.body);
        throw Exception(data["message"] ?? "Gagal mengirim permintaan");
      }

      if (!mounted) return;
      _showSuccessDialog(
        "Permintaan terkirim",
        "Berhasil meminta izin $label.\nTunggu respon Admin/Superadmin.",
      );

      await _init();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Gagal", e.toString());
    } finally {
      if (mounted) {
        setState(() => submittingFeatures.remove(feature));
      }
    }
  }

  void _showSuccessDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.16),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
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

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.16),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDA4AF), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    final role = (AuthSession.role ?? "").toLowerCase().trim();
    if (role != "member") {
      return const Scaffold(
        body: Center(child: Text("Halaman ini khusus Member.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFF), Color(0xFFF3F6FB), Color(0xFFEEF3FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _init,
            color: const Color(0xFF2563EB),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _modernHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _searchAndSummarySection(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _loadingState(),
                  )
                else if (filteredFeatures.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptySearchState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.separated(
                      itemCount: filteredFeatures.length,
                      itemBuilder: (context, index) {
                        final item = filteredFeatures[index];
                        return _requestCardFeature(
                          feature: item["key"]!,
                          label: item["label"]!,
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        role: role,
        site: AuthSession.siteName ?? "-",
        department: AuthSession.departmentName ?? "-",
        name: AuthSession.name ?? "-",
      ),
    );
  }

  Widget _modernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pageTitle(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kelola izin export dengan tampilan yang lebih cepat dicari.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                _headerStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const Text(
                  "Akses Export Excel • Ajukan izin ke Admin",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (AuthSession.role ?? "").toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
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

  Widget _searchAndSummarySection() {
    return Column(
      children: [
        _overviewCard(),
        const SizedBox(height: 14),
        _searchCard(),
        const SizedBox(height: 14),
        _statsGrid(),

        // FILTER ACTIVE INFO
        if (_selectedStatusFilter != 'all') ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Filter: ${_selectedStatusFilter[0].toUpperCase()}${_selectedStatusFilter.substring(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),

                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = 'all';
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _overviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE5EDFA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60A5FA).withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 18,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Total Permission",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Jumlah seluruh fitur export yang dapat diajukan oleh member.",
                          style: TextStyle(
                            fontSize: 12.8,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1D4ED8),
                      Color(0xFF2563EB),
                      Color(0xFF60A5FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$totalFeatureCount",
                            style: const TextStyle(
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Total fitur permission tersedia",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCEAFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Jika ingin cepat mendapatkan izin, hubungi Admin Site Anda untuk mengdapatkan akses",
                        style: TextStyle(
                          fontSize: 12.6,
                          height: 1.55,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                "Cari fitur akses",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Cari inspeksi, p2h, hazard, p5m...",
              prefixIcon: const Icon(Icons.manage_search_rounded),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickSearchChip('Semua', ''),
                const SizedBox(width: 8),
                _quickSearchChip('Inspeksi', 'inspeksi'),
                const SizedBox(width: 8),
                _quickSearchChip('P2H', 'p2h'),
                const SizedBox(width: 8),
                _quickSearchChip('Hazard', 'hazard'),
                const SizedBox(width: 8),
                _quickSearchChip('P5M', 'p5m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickSearchChip(String label, String value) {
    final selected = value.isEmpty
        ? _searchQuery.trim().isEmpty
        : _searchQuery.trim().toLowerCase() == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        _searchController.text = value;
        setState(() => _searchQuery = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Approved',
            value: '$approvedCount',
            icon: Icons.verified_rounded,
            filterKey: 'approved',
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Pending',
            value: '$pendingCount',
            icon: Icons.schedule_rounded,
            filterKey: 'pending',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Rejected',
            value: '$rejectedCount',
            icon: Icons.cancel_rounded,
            filterKey: 'rejected',
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFFB7185)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required String filterKey,
  }) {
    final isSelected = _selectedStatusFilter == filterKey;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedStatusFilter = _selectedStatusFilter == filterKey
              ? 'all'
              : filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE8EEF8),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _statusLabelShort(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Memuat data akses...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Mohon tunggu sebentar",
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySearchState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE8EEF8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 34,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fitur tidak ditemukan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coba kata kunci lain seperti inspeksi, p2h, hazard, atau p5m.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCardFeature({required String feature, required String label}) {
    final hasAccess = hasAccessMap[feature] ?? false;
    final requestStatus = requestStatusMap[feature] ?? "none";
    final rejectReason = rejectReasonMap[feature];
    final isRevoked = isRevokedMap[feature] ?? false;
    final submitting = submittingFeatures.contains(feature);

    String subtitle;
    String buttonText;
    bool enabled = true;

    if (hasAccess) {
      subtitle = "Kamu sudah diizinkan $label.";
      buttonText = "Sudah Diizinkan";
      enabled = false;
    } else if (requestStatus == "pending") {
      subtitle =
          "Permintaan sudah terkirim. Menunggu persetujuan Admin/Superadmin.";
      buttonText = "Menunggu…";
      enabled = false;
    } else if (requestStatus == "rejected") {
      subtitle =
          "Permintaan ditolak. Kamu bisa meminta lagi."
          "${(rejectReason ?? '').trim().isNotEmpty ? "\nAlasan: $rejectReason" : ""}";
      buttonText = "Minta Lagi";
      enabled = true;
    } else if (requestStatus == "approved" && !hasAccess && isRevoked) {
      subtitle =
          "Akses $label kamu telah dicabut oleh Admin/Superadmin. "
          "Jika masih membutuhkan akses ini, silakan ajukan permintaan lagi.";
      buttonText = "Ajukan Lagi";
      enabled = true;
    } else if (requestStatus == "approved" && !hasAccess) {
      subtitle =
          "Izin export sebelumnya sudah tidak aktif. Kamu bisa mengajukan permintaan lagi.";
      buttonText = "Minta Lagi";
      enabled = true;
    } else {
      subtitle = "Minta izin agar bisa $label sesuai site kamu.";
      buttonText = "Minta Izin";
      enabled = true;
    }

    final ui = _featureUi(
      feature: feature,
      hasAccess: hasAccess,
      requestStatus: requestStatus,
      isRevoked: isRevoked,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EEF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: ui.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ui.badgeFg.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(ui.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusPill(
                            text: ui.statusText,
                            bg: ui.badgeBg,
                            fg: ui.badgeFg,
                            icon: ui.badgeIcon,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                subtitle,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: enabled ? null : const Color(0xFFCBD5E1),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: (!enabled || submitting)
                      ? null
                      : () => _requestFeatureExportAccess(
                          feature: feature,
                          label: label,
                        ),
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              enabled ? Icons.send_rounded : Icons.lock_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
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

  Widget _statusPill({
    required String text,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  _FeatureUi _featureUi({
    required String feature,
    required bool hasAccess,
    required String requestStatus,
    required bool isRevoked,
  }) {
    if (hasAccess) {
      return const _FeatureUi(
        icon: Icons.verified_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        statusText: "Approved",
        badgeBg: Color(0xFFECFDF5),
        badgeFg: Color(0xFF059669),
        badgeIcon: Icons.check_circle_rounded,
      );
    }

    if (requestStatus == "pending") {
      return const _FeatureUi(
        icon: Icons.schedule_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        statusText: "Pending",
        badgeBg: Color(0xFFFFFBEB),
        badgeFg: Color(0xFFD97706),
        badgeIcon: Icons.access_time_filled_rounded,
      );
    }

    if (requestStatus == "rejected") {
      return const _FeatureUi(
        icon: Icons.gpp_bad_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFFFB7185), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        statusText: "Rejected",
        badgeBg: Color(0xFFFEF2F2),
        badgeFg: Color(0xFFDC2626),
        badgeIcon: Icons.cancel_rounded,
      );
    }

    if (requestStatus == "approved" && !hasAccess && isRevoked) {
      return const _FeatureUi(
        icon: Icons.lock_reset_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        statusText: "Revoked",
        badgeBg: Color(0xFFF5F3FF),
        badgeFg: Color(0xFF7C3AED),
        badgeIcon: Icons.remove_moderator_rounded,
      );
    }

    if (requestStatus == "approved" && !hasAccess) {
      return const _FeatureUi(
        icon: Icons.lock_clock_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        statusText: "Inactive",
        badgeBg: Color(0xFFF1F5F9),
        badgeFg: Color(0xFF475569),
        badgeIcon: Icons.hourglass_bottom_rounded,
      );
    }

    switch (feature) {
      case "lpi":
        return const _FeatureUi(
          icon: Icons.report_problem_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusText: "Ready",
          badgeBg: Color(0xFFEFF6FF),
          badgeFg: Color(0xFF2563EB),
          badgeIcon: Icons.bolt_rounded,
        );
      case "hazard":
        return const _FeatureUi(
          icon: Icons.warning_amber_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusText: "Ready",
          badgeBg: Color(0xFFFFF7ED),
          badgeFg: Color(0xFFEA580C),
          badgeIcon: Icons.bolt_rounded,
        );
      case "p5m":
        return const _FeatureUi(
          icon: Icons.table_chart_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusText: "Ready",
          badgeBg: Color(0xFFF0F9FF),
          badgeFg: Color(0xFF0284C7),
          badgeIcon: Icons.bolt_rounded,
        );
      default:
        return const _FeatureUi(
          icon: Icons.grid_view_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statusText: "Ready",
          badgeBg: Color(0xFFEEF2FF),
          badgeFg: Color(0xFF4338CA),
          badgeIcon: Icons.bolt_rounded,
        );
    }
  }

  String _statusLabelShort() {
    final anyApproved = hasAccessMap.values.any((v) => v == true);
    final anyPending = requestStatusMap.values.any((v) => v == "pending");
    final anyRevoked = isRevokedMap.values.any((v) => v == true);
    final anyRejected = requestStatusMap.values.any((v) => v == "rejected");
    final anyInactive = requestStatusMap.values.any((v) => v == "approved");

    if (anyApproved) return "Approved";
    if (anyRevoked) return "Revoked";
    if (anyPending) return "Pending";
    if (anyRejected) return "Rejected";
    if (anyInactive) return "Inactive";
    return "Ready";
  }
}

class _FeatureUi {
  final IconData icon;
  final LinearGradient gradient;
  final String statusText;
  final Color badgeBg;
  final Color badgeFg;
  final IconData badgeIcon;

  const _FeatureUi({
    required this.icon,
    required this.gradient,
    required this.statusText,
    required this.badgeBg,
    required this.badgeFg,
    required this.badgeIcon,
  });
}
