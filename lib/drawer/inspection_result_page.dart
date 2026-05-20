import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/inspeksi/Inspeksi_plant_result.dart';
import 'package:safety_apps/drawer/inspeksi/inspeksi_chp_result.dart';
import 'package:safety_apps/drawer/inspeksi/inspeksi_fasilitas_bbm_result.dart';
import 'package:safety_apps/drawer/inspeksi/inspeksi_jalan_tambang_result.dart';
import 'package:safety_apps/drawer/inspeksi/inspeksi_kantor_result.dart';
import 'package:safety_apps/drawer/inspeksi/inspeksi_mtd_result.dart';

class InspectionResultPage extends StatelessWidget {
  final bool canSeeInspeksiCHP;
  final bool canSeeInspeksiJalanTambang;
  final bool canSeeInspeksiKantor;
  final bool canSeeInspeksiMTD;
  final bool canSeeInspeksiPlant;
  final bool canSeeInspeksiFasilitasBBM;
  final String userRole;

  const InspectionResultPage({
    super.key,
    this.canSeeInspeksiCHP = false,
    this.canSeeInspeksiJalanTambang = false,
    this.canSeeInspeksiKantor = false,
    this.canSeeInspeksiMTD = false,
    this.canSeeInspeksiPlant = false,
    this.canSeeInspeksiFasilitasBBM = false,
    this.userRole = "",
  });

  bool get _isAdminOrSuperadmin {
    final role = userRole.toLowerCase().trim();
    return role == "admin" || role == "superadmin";
  }

  bool get _canShowJalanTambang =>
      _isAdminOrSuperadmin || canSeeInspeksiJalanTambang;
  bool get _canShowKantor => _isAdminOrSuperadmin || canSeeInspeksiKantor;
  bool get _canShowMTD => _isAdminOrSuperadmin || canSeeInspeksiMTD;
  bool get _canShowPlant => _isAdminOrSuperadmin || canSeeInspeksiPlant;
  bool get _canShowCHP => _isAdminOrSuperadmin || canSeeInspeksiCHP;
  bool get _canShowFasilitasBBM =>
      _isAdminOrSuperadmin || canSeeInspeksiFasilitasBBM;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),

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
                    "Inspection Result",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Choose inspection category",
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
        children: [
          if (_canShowJalanTambang)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Jalan Tambang",
              icon: Icons.traffic,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspeksiJalanTambangResultPage(),
                  ),
                );
              },
            ),

          if (_canShowKantor)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Kantor",
              icon: Icons.apartment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InspeksiKantorResultPage()),
                );
              },
            ),

          if (_isAdminOrSuperadmin)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Handak & Blasting",
              icon: Icons.bolt,
              enabled: false,
              onTap: () {},
            ),

          if (_canShowMTD)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Mess, Toilet, Dapur",
              icon: Icons.home_filled,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InspeksiMTDResultPage()),
                );
              },
            ),

          if (_canShowPlant)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Plant",
              icon: Icons.factory,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InspeksiPlantResultPage()),
                );
              },
            ),

          if (_isAdminOrSuperadmin)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Fasilitas Hydrokarbon",
              icon: Icons.local_gas_station,
              enabled: false,
              onTap: () {},
            ),

          if (_isAdminOrSuperadmin)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Environment",
              icon: Icons.eco,
              enabled: false,
              onTap: () {},
            ),

          if (_isAdminOrSuperadmin)
            _menuCardPremium(
              context: context,
              title: "Health Inspection",
              icon: Icons.health_and_safety,
              enabled: false,
              onTap: () {},
            ),

          if (_canShowCHP)
            _menuCardPremium(
              context: context,
              title: "Inspeksi CHP",
              icon: Icons.fire_extinguisher,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InspeksiCHPResultPage()),
                );
              },
            ),

          if (_canShowFasilitasBBM)
            _menuCardPremium(
              context: context,
              title: "Inspeksi Fasilitas BBM",
              icon: Icons.local_gas_station_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspeksiFasilitasBBMResultPage(),
                  ),
                );
              },
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
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: enabled
                          ? [Color(0xff1d63ff), Color(0xff4fa9ff)]
                          : [Colors.grey, Colors.grey],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),

                const SizedBox(width: 16),

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
