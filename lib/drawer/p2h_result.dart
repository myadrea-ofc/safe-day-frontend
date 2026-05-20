import 'package:flutter/material.dart';
import 'package:safety_apps/drawer/p2h/p2h_bus_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_compactor_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_crane_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_dozer_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_dt_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_exca_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_forklift_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_fuel_truck_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_grader.result.dart';
import 'package:safety_apps/drawer/p2h/p2h_lv_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_service_truck_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_towerlamp_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_truck_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_water_pump_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_water_truck_result.dart';
import 'package:safety_apps/drawer/p2h/p2h_wheelloader_result.dart';

class P2HResultPage extends StatelessWidget {
  final bool canSeeLV;
  final bool canSeeBus;
  final bool canSeeDT;
  final bool canSeeExcavator;
  final bool canSeeGrader;
  final bool canSeeDozer;
  final bool canSeeTowerLamp;
  final bool canSeeCrane;
  final bool canSeeForklift;
  final bool canSeeTruckHauling;
  final bool canSeeWaterTruck;
  final bool canSeeWheelLoader;
  final bool canSeeWaterPump;
  final bool canSeeServiceTruck;
  final bool canSeeCompactor;
  final bool canSeeFuelTruck;
  final String userRole;

  const P2HResultPage({
    super.key,
    this.canSeeLV = false,
    this.canSeeBus = false,
    this.canSeeDT = false,
    this.canSeeExcavator = false,
    this.canSeeGrader = false,
    this.canSeeDozer = false,
    this.canSeeTowerLamp = false,
    this.canSeeCrane = false,
    this.canSeeForklift = false,
    this.canSeeTruckHauling = false,
    this.canSeeWaterTruck = false,
    this.canSeeWheelLoader = false,
    this.canSeeWaterPump = false,
    this.canSeeServiceTruck = false,
    this.canSeeCompactor = false,
    this.canSeeFuelTruck = false,
    this.userRole = "",
  });

  bool get _isAdminOrSuperadmin {
    final role = userRole.toLowerCase().trim();
    return role == "admin" || role == "superadmin";
  }

  bool get _canShowLV => _isAdminOrSuperadmin || canSeeLV;
  bool get _canShowBus => _isAdminOrSuperadmin || canSeeBus;
  bool get _canShowDT => _isAdminOrSuperadmin || canSeeDT;
  bool get _canShowExcavator => _isAdminOrSuperadmin || canSeeExcavator;
  bool get _canShowGrader => _isAdminOrSuperadmin || canSeeGrader;
  bool get _canShowDozer => _isAdminOrSuperadmin || canSeeDozer;
  bool get _canShowTowerLamp => _isAdminOrSuperadmin || canSeeTowerLamp;
  bool get _canShowCrane => _isAdminOrSuperadmin || canSeeCrane;
  bool get _canShowForklift => _isAdminOrSuperadmin || canSeeForklift;
  bool get _canShowTruckHauling => _isAdminOrSuperadmin || canSeeTruckHauling;
  bool get _canShowWaterTruck => _isAdminOrSuperadmin || canSeeWaterTruck;
  bool get _canShowWheelLoader => _isAdminOrSuperadmin || canSeeWheelLoader;
  bool get _canShowWaterPump => _isAdminOrSuperadmin || canSeeWaterPump;
  bool get _canShowServiceTruck => _isAdminOrSuperadmin || canSeeServiceTruck;
  bool get _canShowCompactor => _isAdminOrSuperadmin || canSeeCompactor;
  bool get _canShowFuelTruck => _isAdminOrSuperadmin || canSeeFuelTruck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f7),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "P2H Result",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Choose P2H category",
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
          if (_canShowLV)
            _menuCardPremium(
              context: context,
              title: "P2H LV",
              icon: Icons.car_repair,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HLVResultPage()),
                );
              },
            ),

          if (_canShowBus)
            _menuCardPremium(
              context: context,
              title: "P2H Sarana Bus",
              icon: Icons.directions_bus_filled_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HBusResultPage()),
                );
              },
            ),

          if (_canShowDT)
            _menuCardPremium(
              context: context,
              title: "P2H Heavy Duty (HDT)",
              icon: Icons.fire_truck_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HDTResultPage()),
                );
              },
            ),

          if (_canShowExcavator)
            _menuCardPremium(
              context: context,
              title: "P2H Excavator",
              icon: Icons.construction_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HExcaResultPage()),
                );
              },
            ),

          if (_canShowGrader)
            _menuCardPremium(
              context: context,
              title: "P2H Grader",
              icon: Icons.engineering_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HGraderResultPage()),
                );
              },
            ),

          if (_canShowDozer)
            _menuCardPremium(
              context: context,
              title: "P2H Dozer",
              icon: Icons.precision_manufacturing_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HDozerResultPage()),
                );
              },
            ),

          if (_canShowTowerLamp)
            _menuCardPremium(
              context: context,
              title: "P2H Tower Lamp",
              icon: Icons.lightbulb_circle_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HTowerLampResultPage()),
                );
              },
            ),

          if (_canShowCrane)
            _menuCardPremium(
              context: context,
              title: "P2H Crane",
              icon: Icons.adf_scanner_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HCraneResultPage()),
                );
              },
            ),

          if (_canShowForklift)
            _menuCardPremium(
              context: context,
              title: "P2H Forklift",
              icon: Icons.forklift,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HForkliftResultPage()),
                );
              },
            ),

          if (_canShowTruckHauling)
            _menuCardPremium(
              context: context,
              title: "P2H Truck Hauling",
              icon: Icons.local_shipping_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HTruckResultPage()),
                );
              },
            ),

          if (_canShowWaterTruck)
            _menuCardPremium(
              context: context,
              title: "P2H Water Truck",
              icon: Icons.fire_truck_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HWaterTruckResultPage()),
                );
              },
            ),

          if (_canShowWheelLoader)
            _menuCardPremium(
              context: context,
              title: "P2H Wheel Loader",
              icon: Icons.fire_truck_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HWheelLoaderResultPage()),
                );
              },
            ),

          if (_isAdminOrSuperadmin)
            _menuCardPremium(
              context: context,
              title: "P2H Genset",
              icon: Icons.power_rounded,
              enabled: false,
              onTap: () {},
            ),

          if (_canShowWaterPump)
            _menuCardPremium(
              context: context,
              title: "P2H Water Pump",
              icon: Icons.water_drop_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HWaterPumpResultPage()),
                );
              },
            ),

          if (_canShowServiceTruck)
            _menuCardPremium(
              context: context,
              title: "P2H Service Truck",
              icon: Icons.miscellaneous_services_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => P2HServiceTruckResultPage(),
                  ),
                );
              },
            ),

          if (_canShowCompactor)
            _menuCardPremium(
              context: context,
              title: "P2H Compactor",
              icon: Icons.compress_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HCompactorResultPage()),
                );
              },
            ),

          if (_canShowFuelTruck)
            _menuCardPremium(
              context: context,
              title: "P2H Fuel Truck",
              icon: Icons.local_gas_station_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => P2HFuelTruckResultPage()),
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
