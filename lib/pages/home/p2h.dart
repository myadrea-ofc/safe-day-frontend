import 'package:flutter/material.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_bus.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_compactor.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_crane.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_dozer.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_excavator.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_forklift.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_fueltruck.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_grader.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_dt.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_lv.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_service_truck.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_towerlamp.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_truck.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_water_pump.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_water_truck.dart';
import 'package:safety_apps/pages/form_p2h/form_p2h_wheel_loader.dart';

class P2HPage extends StatelessWidget {
  const P2HPage({super.key});

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
                    "P2H FORM",
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
        padding: EdgeInsets.all(18),
        children: [
          _menuCardPremium(
            context: context,
            title: "P2H LV",
            icon: Icons.car_repair,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HLV()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Sarana Bus",
            icon: Icons.directions_bus_filled_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HBus()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Heavy Duty (HDT)",
            icon: Icons.fire_truck_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HHeavyDuty()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Excavator",
            icon: Icons.construction_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HExcavator()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Grader",
            icon: Icons.engineering_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HGrader()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Dozer",
            icon: Icons.precision_manufacturing_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HDozer()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Tower Lamp",
            icon: Icons.lightbulb_circle_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HTowerLamp()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Crane",
            icon: Icons.adf_scanner_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HCrane()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Forklift",
            icon: Icons.forklift,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HForklift()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Truck Hauling",
            icon: Icons.local_shipping_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HTruckHauling()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Water Truck",
            icon: Icons.fire_truck_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HWaterTruck()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Wheel Loader",
            icon: Icons.fire_truck_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HWheelLoader()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Genset",
            icon: Icons.power_rounded,
            enabled: false,
            onTap: () {},
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Water Pump",
            icon: Icons.water_drop_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HWaterPump()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Service Truck",
            icon: Icons.miscellaneous_services_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormServiceTruck()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Compactor",
            icon: Icons.compress_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HCompactor()),
              );
            },
          ),

          _menuCardPremium(
            context: context,
            title: "P2H Fuel Truck",
            icon: Icons.local_gas_station_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormP2HFuelTruck()),
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
