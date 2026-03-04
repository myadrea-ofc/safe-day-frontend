import 'package:flutter/material.dart';
import 'package:safety_apps/pages/event/hses_buletin.dart';
import 'package:safety_apps/pages/event/hses_daily_plant.dart';

class HsesEventPage extends StatelessWidget {
  const HsesEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeef2f7),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "HSES EVENT",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Choose Event",
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: EdgeInsets.all(18),
        children: [
          _menuCardPremium(
            context: context,
            title: "HSES Daily Plan",
            icon: Icons.calendar_month,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HSESDailyPlanPage()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "HSES Buletin",
            icon: Icons.newspaper_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HSESBuletinPage()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "HSES Training",
            icon: Icons.menu_book_rounded,
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuCardPremium({
    required BuildContext context,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: enabled ? 3 : 1,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled
              ? onTap
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "🚧 Fitur ini akan tersedia di update selanjutnya",
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // ICON (STYLE TETAP)
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: enabled
                          ? const [Color(0xff1d63ff), Color(0xff4fa9ff)]
                          : const [Colors.grey, Colors.grey],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),

                const SizedBox(width: 16),

                // TITLE + BADGE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: enabled ? Colors.black : Colors.grey,
                        ),
                      ),

                      // 🔖 BADGE COMING SOON
                      if (!enabled)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "COMING SOON",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // RIGHT ICON
                Icon(
                  enabled
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline,
                  size: 18,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
