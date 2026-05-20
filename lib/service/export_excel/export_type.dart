enum ExportType {
  hazard,
  lpi,
  p5m,
  inspeksi_chp,
  inspeksi_fasilitas_bbm,
  inspeksi_jalan_tambang,
  inspeksi_kantor,
  inspeksi_mtd,
  inspeksi_plant,
  p2h_bus,
  p2h_dt,
  p2h_exca,
  p2h_grader,
  p2h_towerlamp,
  p2h_crane,
  p2h_compactor,
  p2h_dozer,
  p2h_forklift,
  p2h_fuel_truck,
  p2h_lv,
  p2h_service_truck,
  p2h_truck,
  p2h_water_pump,
  p2h_water_truck,
  p2h_wheelloader,
  daily_plan,
  buletin,
  audit_logs,
}

extension ExportTypeX on ExportType {
  String get endpoint {
    switch (this) {
      case ExportType.hazard:
        return "/hazard";
      case ExportType.lpi:
        return "/lpi";
      case ExportType.p5m:
        return "/p5m";
      case ExportType.inspeksi_chp:
        return "/inspeksi_chp";
      case ExportType.inspeksi_fasilitas_bbm:
        return "/inspeksi_fasilitas_bbm";
      case ExportType.inspeksi_jalan_tambang:
        return "/inspeksi_jalan_tambang";
      case ExportType.inspeksi_kantor:
        return "/inspeksi_kantor";
      case ExportType.inspeksi_mtd:
        return "/inspeksi_mtd";
      case ExportType.inspeksi_plant:
        return "/inspeksi_plant";
      case ExportType.p2h_bus:
        return "/p2h_bus";
      case ExportType.p2h_dt:
        return "/p2h_dt";
      case ExportType.p2h_exca:
        return "/p2h_exca";
      case ExportType.p2h_grader:
        return "/p2h_grader";
      case ExportType.p2h_towerlamp:
        return "/p2h_towerlamp";
      case ExportType.p2h_crane:
        return "/p2h_crane";
      case ExportType.p2h_compactor:
        return "/p2h_compactor";
      case ExportType.p2h_dozer:
        return "/p2h_dozer";
      case ExportType.p2h_forklift:
        return "/p2h_forklift";
      case ExportType.p2h_fuel_truck:
        return "/p2h_fuel_truck";
      case ExportType.p2h_lv:
        return "/p2h_lv";
      case ExportType.p2h_service_truck:
        return "/p2h_service_truck";
      case ExportType.p2h_truck:
        return "/p2h_truck";
      case ExportType.p2h_water_pump:
        return "/p2h_water_pump";
      case ExportType.p2h_water_truck:
        return "/p2h_water_truck";
      case ExportType.p2h_wheelloader:
        return "/p2h_wheelloader";
      case ExportType.daily_plan:
        return "/hses_daily_plan";
      case ExportType.buletin:
        return "/hses_buletin";
      case ExportType.audit_logs:
        return "/audit-logs";
    }
  }

  String get filePrefix {
    switch (this) {
      case ExportType.hazard:
        return "Hazard";
      case ExportType.lpi:
        return "LPI";
      case ExportType.p5m:
        return "P5M";
      case ExportType.inspeksi_chp:
        return "InspeksiCHP";
      case ExportType.inspeksi_fasilitas_bbm:
        return "InspeksiFasilitasBBM";
      case ExportType.inspeksi_jalan_tambang:
        return "InspeksiJalanTambang";
      case ExportType.inspeksi_kantor:
        return "InspeksiKantor";
      case ExportType.inspeksi_mtd:
        return "InspeksiMTD";
      case ExportType.inspeksi_plant:
        return "InspeksiPlant";
      case ExportType.p2h_bus:
        return "P2HBus";
      case ExportType.p2h_dt:
        return "P2HDT";
      case ExportType.p2h_exca:
        return "P2HExca";
      case ExportType.p2h_grader:
        return "P2HGrader";
      case ExportType.p2h_towerlamp:
        return "P2HTowerLamp";
      case ExportType.p2h_crane:
        return "P2HCrane";
      case ExportType.p2h_compactor:
        return "P2HCompactor";
      case ExportType.p2h_dozer:
        return "P2HDozer";
      case ExportType.p2h_forklift:
        return "P2HForklift";
      case ExportType.p2h_fuel_truck:
        return "P2HFuelTruck";
      case ExportType.p2h_lv:
        return "P2HLV";
      case ExportType.p2h_service_truck:
        return "P2HServiceTruck";
      case ExportType.p2h_truck:
        return "P2HTruck";
      case ExportType.p2h_water_pump:
        return "P2HWaterPump";
      case ExportType.p2h_water_truck:
        return "P2HWaterTruck";
      case ExportType.p2h_wheelloader:
        return "P2HWheelLoader";
      case ExportType.daily_plan:
        return "DailyPlan";
      case ExportType.buletin:
        return "Buletin";
      case ExportType.audit_logs:
        return "Audit Log";
    }
  }

  String get shareText {
    switch (this) {
      case ExportType.hazard:
        return "Export Hazard";
      case ExportType.lpi:
        return "Export LPI";
      case ExportType.p5m:
        return "Export P5M";
      case ExportType.inspeksi_chp:
        return "Export Inspeksi CHP";
      case ExportType.inspeksi_fasilitas_bbm:
        return "Export Inspeksi Fasilitas BBM";
      case ExportType.inspeksi_jalan_tambang:
        return "Export Inspeksi Jalan Tambang";
      case ExportType.inspeksi_kantor:
        return "Export Inspeksi Kantor";
      case ExportType.inspeksi_mtd:
        return "Export Inspeksi Mess, Toilet dan Dapur";
      case ExportType.inspeksi_plant:
        return "Export Inspeksi Plant";
      case ExportType.p2h_bus:
        return "Export P2H Bus";
      case ExportType.p2h_dt:
        return "Export P2H HDT";
      case ExportType.p2h_exca:
        return "Export P2H Excavator";
      case ExportType.p2h_grader:
        return "Export P2H Grader";
      case ExportType.p2h_towerlamp:
        return "Export P2H Tower Lamp";
      case ExportType.p2h_crane:
        return "Export P2H Crane";
      case ExportType.p2h_compactor:
        return "Export P2H Compactor";
      case ExportType.p2h_dozer:
        return "Export P2H Dozer";
      case ExportType.p2h_forklift:
        return "Export P2H Forklift";
      case ExportType.p2h_fuel_truck:
        return "Export P2H Fuel Truck";
      case ExportType.p2h_lv:
        return "Export P2H LV";
      case ExportType.p2h_service_truck:
        return "Export P2H Service Truck";
      case ExportType.p2h_truck:
        return "Export P2H Truck";
      case ExportType.p2h_water_pump:
        return "Export P2H Water Pump";
      case ExportType.p2h_water_truck:
        return "Export P2H Water Truck";
      case ExportType.p2h_wheelloader:
        return "Export P2H Wheel Loader";
      case ExportType.daily_plan:
        return "Export Daily Plan";
      case ExportType.buletin:
        return "Export Buletin";
      case ExportType.audit_logs:
        return "Export Audit Log";
    }
  }
}
