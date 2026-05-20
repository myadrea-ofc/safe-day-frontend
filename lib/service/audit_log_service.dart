import 'dart:convert';

import 'package:safety_apps/models/audit_log.dart';
import 'package:safety_apps/network/api_client.dart';

class AuditLogResponse {
  final List<AuditLogModel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPage;

  AuditLogResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    final meta = json["meta"] as Map<String, dynamic>? ?? {};
    final rawData = json["data"];

    return AuditLogResponse(
      data: rawData is List
          ? rawData
                .map(
                  (item) =>
                      AuditLogModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : <AuditLogModel>[],
      page: int.tryParse(meta["page"].toString()) ?? 1,
      limit: int.tryParse(meta["limit"].toString()) ?? 10,
      total: int.tryParse(meta["total"].toString()) ?? 0,
      totalPage: int.tryParse(meta["total_page"].toString()) ?? 1,
    );
  }
}

class AuditLogService {
  static Future<AuditLogResponse> fetchAuditLogs({
    required int page,
    required int limit,
    int? siteId,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, String>{
      "page": page.toString(),
      "limit": limit.toString(),
    };

    if (siteId != null) {
      query["site_id"] = siteId.toString();
    }

    if (search != null && search.trim().isNotEmpty) {
      query["search"] = search.trim();
    }

    if (dateFrom != null && dateFrom.trim().isNotEmpty) {
      query["date_from"] = dateFrom;
    }

    if (dateTo != null && dateTo.trim().isNotEmpty) {
      query["date_to"] = dateTo;
    }

    final uri = Uri(path: "/audit-logs", queryParameters: query);

    final response = await ApiClient.get(
      uri.toString(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil audit log");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Format response audit log tidak valid");
    }

    return AuditLogResponse.fromJson(decoded);
  }
}
