import 'package:flutter/material.dart';
import 'package:safety_apps/models/daily_plan.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/event/daily_plan/daily_plan_dialog_review.dart';

class DailyPlanCard extends StatefulWidget {
  final DailyPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DailyPlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DailyPlanCard> createState() => _DailyPlanCardState();
}

class _DailyPlanCardState extends State<DailyPlanCard> {
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);

  double rating = 0;
  final TextEditingController commentCtrl = TextEditingController();

  bool get canEditOrDelete {
    if (AuthSession.isSuperAdmin) return true;

    if (AuthSession.isAdmin) {
      final createdById = widget.plan.createdById ?? -1;
      final createdByRole = (widget.plan.createdByRole ?? '').toLowerCase();
      return createdById == AuthSession.userId && createdByRole != 'superadmin';
    }

    return false;
  }

  bool get canReview {
    final role = (widget.plan.createdByRole ?? '').toLowerCase();

    if (AuthSession.isMember) return true;

    if (AuthSession.isAdmin && role == 'superadmin') return true;

    return false;
  }

  bool get sudahReview {
    return (widget.plan.rating ?? 0) > 0 &&
        (widget.plan.comment?.trim().isNotEmpty ?? false);
  }

  bool get isViewOnly {
    return AuthSession.isSuperAdmin;
  }

  bool get showNeedReviewUI {
    // superadmin view only -> jangan pernah tampilkan need review
    if (AuthSession.isSuperAdmin) return false;

    // tampilkan hanya kalau memang canReview dan belum review
    return canReview && !sudahReview;
  }

  bool get showReviewedUI {
    if (AuthSession.isSuperAdmin)
      return false; // optional: superadmin cukup view-only
    return canReview && sudahReview;
  }

  bool get showViewOnlyUI => AuthSession.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    rating = widget.plan.rating?.toDouble() ?? 0;
    commentCtrl.text = widget.plan.comment ?? '';
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool sessionReady = AuthSession.isReady;
    final plan = widget.plan;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        if (!sessionReady) return;

        final updated = await showDailyPlanDetailDialog(
          context,
          plan: widget.plan,
        );
        if (updated != null) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.image != null && plan.image!.isNotEmpty)
                _imageHeader(plan)
              else
                _noImageHeader(plan),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== SUBTITLE =====
                    Text(
                      plan.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: _primary,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ===== DESCRIPTION =====
                    Text(
                      plan.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // ===== BOTTOM BAR (DATE + STATUS) =====
                    if (canReview || canEditOrDelete) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.06),
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (_) {
                          final hasStatus = showViewOnlyUI || canReview;

                          return Row(
                            children: [
                              if (hasStatus) ...[
                                _datePill(formatDate(plan.createdAt)), // kiri
                                const Spacer(),
                                _statusPill(), // kanan
                              ] else ...[
                                const Spacer(),
                                _datePill(formatDate(plan.createdAt)), // kanan
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageHeader(DailyPlan plan) {
    return Stack(
      children: [
        Image.network(
          "http://safety.borneo.co.id/uploads/${plan.image}",
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageError(),
        ),
        // overlay gradient lebih halus
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.62),
                Colors.black.withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // right actions
        if (canEditOrDelete)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _iconAction(
                  icon: Icons.edit_rounded,
                  color: Colors.greenAccent,
                  onTap: widget.onEdit,
                ),
                const SizedBox(width: 8),
                _iconAction(
                  icon: Icons.delete_rounded,
                  color: Colors.redAccent,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),

        // title
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Text(
            plan.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _noImageHeader(DailyPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.95), _secondary.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(Icons.article_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plan.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill() {
    // superadmin: view only
    if (showViewOnlyUI) {
      return _miniInfo(
        icon: Icons.visibility_rounded,
        text: "View Only",
        color: Colors.grey.shade700,
      );
    }

    // hanya user yang bisa review
    if (canReview) {
      return _miniInfo(
        icon: Icons.rate_review_rounded,
        text: sudahReview ? "Selesai" : "Butuh Review",
        color: sudahReview ? Colors.green : _primary,
      );
    }

    // default: tidak tampil apa-apa
    return const SizedBox.shrink();
  }

  Widget _datePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: _primary.withOpacity(0.85),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageError() => Container(
    height: 180,
    color: Colors.grey.shade300,
    child: const Center(child: Icon(Icons.broken_image, size: 40)),
  );

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Hapus Daily Plan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Daily Plan yang dihapus tidak dapat dikembalikan. Yakin ingin melanjutkan?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Batal",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      widget.onDelete();
    }
  }
}

String formatDate(DateTime? date) {
  if (date == null) return "-";

  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final day = date.day.toString().padLeft(2, '0');
  final monthName = months[date.month - 1];
  final year = date.year;

  return "$day $monthName $year";
}
