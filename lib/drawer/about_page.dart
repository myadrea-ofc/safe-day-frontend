import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 14)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _heroCard(),
                  const SizedBox(height: 14),

                  _infoCardModern(
                    icon: Icons.info_outline,
                    title: "Tentang Aplikasi",
                    content:
                        "Safe Day adalah aplikasi yang dirancang untuk memberikan informasi tentang HSES Performance PT Mantimin Coal Mining seluruh mitra kerja perusahaan. Dalam Dashboard ini HSES Department menyajikan informasi tentang laporan-laporan yang menunjang kinerja keselamatan setiap insan karyawan PT MCM dan mitra kerja ",
                  ),

                  _infoCardModern(
                    icon: Icons.flag_outlined,
                    title: "Tujuan",
                    content:
                        "Mempermudah proses pelaporan keselamatan dan meningkatkan awareness "
                        "terhadap kondisi berbahaya di area kerja. Memberikan notifikasi cepat "
                        "dan pencatatan yang akurat untuk HSES Department.",
                  ),

                  _infoCardModern(
                    icon: Icons.person_outline,
                    title: "Developed By",
                    content:
                        "Dikembangkan oleh IT Team HO Bagas Bumi Persada sebagai bentuk dukungan terhadap Zero Harm Program di seluruh area operasi. ",
                  ),

                  _contactCard(),
                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      "© 2025 HSES Department\nAll Rights Reserved",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.45),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HEADER (gradient premium) =====
  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "About Safe Day",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "SAFE DAY",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.4,
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

  // ===== HERO CARD (logo + nama + versi) =====
  Widget _heroCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff1d63ff).withOpacity(0.12),
                    const Color(0xff4fa9ff).withOpacity(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xff1d63ff).withOpacity(0.12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Image(
                  image: AssetImage("assets/logo.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Safety Day App",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffeef2f7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: const Text(
                      "Zero Harm Program Support",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff1d63ff),
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
  }

  // ===== INFO CARD MODERN =====
  Widget _infoCardModern({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff1d63ff).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xff1d63ff).withOpacity(0.14),
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xff1d63ff)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 46,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xff1d63ff).withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.78),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CONTACT CARD (lebih rapi) =====
  Widget _contactCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff1d63ff).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xff1d63ff).withOpacity(0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_outlined,
                    color: Color(0xff1d63ff),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Kontak & Support",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _contactRow("Email", "hses.support@company.com"),
            const SizedBox(height: 8),
            _contactRow("Hotline HSES", "+62 811-455-89558"),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xffeef2f7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xff1d63ff),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black.withOpacity(0.80),
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
