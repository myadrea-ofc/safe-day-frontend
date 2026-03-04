import 'package:flutter/material.dart';
import 'package:safety_apps/models/buletin.dart';
import 'package:safety_apps/service/event/buletin_service.dart';
import 'package:safety_apps/session/auth_session.dart';

Future<Buletin?> showBuletinDetailDialog(
  BuildContext parentContext, {
  required Buletin buletin,
}) async {
  double dialogRating = buletin.rating?.toDouble() ?? 0;
  final dialogCommentCtrl = TextEditingController(text: buletin.comment ?? '');

  final role = (buletin.createdByRole ?? '').toLowerCase();

  final bool canReview =
      AuthSession.isMember || (AuthSession.isAdmin && role == 'superadmin');

  final bool sudahReview =
      (buletin.rating ?? 0) > 0 &&
      ((buletin.comment?.trim().isNotEmpty) ?? false);

  final bool isViewOnly = AuthSession.isSuperAdmin;

  final result = await showDialog<Buletin>(
    context: parentContext,
    builder: (_) {
      return Dialog(
        backgroundColor: const Color(0xffeef2f7),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final bool isFormValid =
                dialogRating > 0 && dialogCommentCtrl.text.trim().isNotEmpty;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.event_note_rounded,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Detail Buletin",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buletin.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          buletin.subtitle,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          buletin.description,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        if (!isViewOnly && canReview && sudahReview) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Terima kasih sudah mereview Buletin ini 🙏",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      size: 26,
                                      color: index < (buletin.rating ?? 0)
                                          ? Colors.amber
                                          : Colors.grey.shade400,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  buletin.comment ?? "-",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ====== FORM REVIEW ======
                        if (!isViewOnly && canReview && !sudahReview) ...[
                          Row(
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    dialogRating = index + 1;
                                  });
                                },
                                child: Icon(
                                  Icons.star,
                                  size: 28,
                                  color: index < dialogRating
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: dialogCommentCtrl,
                            maxLines: 3,
                            onChanged: (_) => setStateDialog(() {}),
                            decoration: InputDecoration(
                              hintText: "Tulis komentar...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (!isFormValid)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                "Rating dan komentar wajib diisi",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1d63ff),
                                disabledBackgroundColor: const Color(
                                  0xff1d63ff,
                                ).withOpacity(0.35),
                                elevation: 3,
                                shadowColor: const Color(
                                  0xff1d63ff,
                                ).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isFormValid
                                  ? () async {
                                      final success =
                                          await HSESBuletinService.submitReview(
                                            buletinId: buletin.id,
                                            rating: dialogRating.toInt(),
                                            comment: dialogCommentCtrl.text
                                                .trim(),
                                          );

                                      if (!success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Gagal menyimpan review",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      buletin.rating = dialogRating.toInt();
                                      buletin.comment = dialogCommentCtrl.text
                                          .trim();

                                      Navigator.of(parentContext).pop(buletin);
                                    }
                                  : null,
                              child: const Text(
                                "Simpan Review",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (isViewOnly || !canReview) ...[],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  dialogCommentCtrl.dispose();
  return result;
}
