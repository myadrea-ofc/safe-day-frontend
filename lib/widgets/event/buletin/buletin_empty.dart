import 'package:flutter/material.dart';

class BuletinEmpty extends StatelessWidget {
  const BuletinEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1d63ff).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Belum ada Buletin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "Tekan tombol + untuk menambahkan Buletin",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
