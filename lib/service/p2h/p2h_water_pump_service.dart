import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safety_apps/models/p2h/p2h_water_pump.dart';

class P2HWaterPumpService {
  static const _storage = FlutterSecureStorage();
  static const String baseUrl = "http://safety.borneo.co.id/p2h_water_pump";

  static Future<bool> submitP2HWaterPump({
    required String nama,
    required String jabatan,
    required String department,
    required String perusahaan,
    required String tanggal,

    required String hmUnit,
    required String noLambungUnit,
    required String shiftKerja,

    required String opsiItem1,
    required String opsiItem2,
    required String opsiItem3,
    required String opsiItem4,
    required String opsiItem5,
    required String opsiItem6,
    required String opsiItem7,
    required String opsiItem8,
    required String opsiItem9,
    required String opsiItem10,
    required String opsiItem11,
    required String opsiItem12,
    required String opsiItem13,
    required String opsiItem14,
    required String opsiItem15,
    required String opsiItem16,
    required String opsiItem17,
    required String opsiItem18,
    required String opsiItem19,
    required String opsiItem20,

    required String alatKeselamatanAir1,
    required String alatKeselamatanAir2,
    required String alatKeselamatanAir3,
    required String alatKeselamatanAir4,

    required String unitAman,

    List<String>? filePaths,
  }) async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    final client = http.Client();

    try {
      final request = http.MultipartRequest("POST", Uri.parse(baseUrl));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "x-device-id": deviceId,
      });

      request.fields.addAll({
        "nama": nama,
        "jabatan": jabatan,
        "department": department,
        "perusahaan": perusahaan,
        "tanggal": tanggal,

        "hm_unit": hmUnit,
        "no_lambung_unit": noLambungUnit,
        "shift_kerja": shiftKerja,

        "opsi_item1": opsiItem1,
        "opsi_item2": opsiItem2,
        "opsi_item3": opsiItem3,
        "opsi_item4": opsiItem4,
        "opsi_item5": opsiItem5,
        "opsi_item6": opsiItem6,
        "opsi_item7": opsiItem7,
        "opsi_item8": opsiItem8,
        "opsi_item9": opsiItem9,
        "opsi_item10": opsiItem10,
        "opsi_item11": opsiItem11,
        "opsi_item12": opsiItem12,
        "opsi_item13": opsiItem13,
        "opsi_item14": opsiItem14,
        "opsi_item15": opsiItem15,
        "opsi_item16": opsiItem16,
        "opsi_item17": opsiItem17,
        "opsi_item18": opsiItem18,
        "opsi_item19": opsiItem19,
        "opsi_item20": opsiItem20,

        "alat_keselamatan_air1": alatKeselamatanAir1,
        "alat_keselamatan_air2": alatKeselamatanAir2,
        "alat_keselamatan_air3": alatKeselamatanAir3,
        "alat_keselamatan_air4": alatKeselamatanAir4,

        "unit_aman": unitAman,
      });

      if (filePaths != null && filePaths.isNotEmpty) {
        int i = 1;
        for (final path in filePaths.take(5)) {
          print("Uploading file $i/${filePaths.length}");
          request.files.add(
            await http.MultipartFile.fromPath(
              "files",
              path,
              filename: path.split('/').last,
              contentType: http.MediaType("image", "jpeg"),
            ),
          );
          i++;
        }
      }

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 3));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body["success"] == true;
      } else {
        print("Submit P2H WATER PUMP Failed: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Submit P2H WATER PUMP Exception: $e");
      return false;
    } finally {
      client.close();
    }
  }

  static Future<List<P2HWaterPumpModel>> fetchP2HWaterPump() async {
    final token = await _storage.read(key: "jwt_token");
    final deviceId = await _storage.read(key: "device_id");

    if (token == null || deviceId == null) {
      throw Exception("Token atau Device ID tidak ditemukan");
    }

    try {
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token", "x-device-id": deviceId},
      );

      if (res.statusCode != 200) return [];

      final List data = jsonDecode(res.body);
      return data.map((e) => P2HWaterPumpModel.fromJson(e)).toList();
    } catch (e) {
      print("Error Fetch P2H WATER PUMP: $e");
      return [];
    }
  }
}
