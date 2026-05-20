import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safety_apps/models/dropdown_item.dart';

class MasterDataService {
  static const String baseUrl = 'http://safety.borneo.co.id/api';

  Future<List<DropdownItemModel>> fetchMasterData(String endpoint) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$endpoint'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DropdownItemModel.fromJson(item)).toList();
    } else {
      throw Exception(
        'Gagal mengambil data dari endpoint: $endpoint '
        '(status: ${response.statusCode}, body: ${response.body})',
      );
    }
  }
}
