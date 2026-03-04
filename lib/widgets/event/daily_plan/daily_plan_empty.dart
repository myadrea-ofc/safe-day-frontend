import 'package:flutter/material.dart';

class DailyPlanEmpty extends StatelessWidget {
  const DailyPlanEmpty({super.key});

  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.note_alt_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Belum ada Daily Plan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tekan tombol + untuk menambahkan rencana kerja harian.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.60),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.10)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: _primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pastikan Site & Department sesuai agar akses fitur dan notifikasi tepat.",
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
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
}
