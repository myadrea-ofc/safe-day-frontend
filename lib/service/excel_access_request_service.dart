import 'dart:convert';
import 'package:http/http.dart' as http;

class ExcelAccessRequest {
  final int id;
  final int siteId;
  final String feature;
  final String status; // pending/approved/rejected
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final String? rejectReason;
  final bool revoked;

  ExcelAccessRequest({
    required this.id,
    required this.siteId,
    required this.feature,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
    this.rejectReason,
    this.revoked = false,
  });

  factory ExcelAccessRequest.fromJson(Map<String, dynamic> json) {
    return ExcelAccessRequest(
      id: json['id'],
      siteId: json['site_id'],
      feature: (json['feature'] ?? '').toString(),
      status: json['status'],
      requestedAt: DateTime.parse(json['requested_at']),
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'])
          : null,
      rejectReason: json['reject_reason'],
      revoked: json['revoked'] == true,
    );
  }
}

class ExcelAccessRequestAdminItem {
  final int id;
  final int siteId;
  final String feature;
  final String status;
  final DateTime requestedAt;
  final int requesterUserId;
  final String requesterName;
  final String? departmentName;
  final DateTime? decidedAt;
  final String? rejectReason;

  ExcelAccessRequestAdminItem({
    required this.id,
    required this.siteId,
    required this.feature,
    required this.status,
    required this.requestedAt,
    required this.requesterUserId,
    required this.requesterName,
    this.departmentName,
    this.decidedAt,
    this.rejectReason,
  });

  factory ExcelAccessRequestAdminItem.fromJson(Map<String, dynamic> json) {
    return ExcelAccessRequestAdminItem(
      id: json['id'],
      siteId: json['site_id'],
      feature: (json['feature'] ?? '').toString(),
      status: json['status'],
      requestedAt: DateTime.parse(json['requested_at']),
      requesterUserId: json['requester_user_id'],
      requesterName: (json['requester_name'] ?? '-').toString(),
      departmentName: json['department_name']?.toString(),
      decidedAt: json['decided_at'] != null
          ? DateTime.parse(json['decided_at'])
          : null,
      rejectReason: json['reject_reason']?.toString(),
    );
  }
}

class ExcelAccessRequestService {
  final String baseUrl;
  final Future<Map<String, String>> Function() authHeaders;

  ExcelAccessRequestService({required this.baseUrl, required this.authHeaders});

  Future<ExcelAccessRequest?> getMyLatest({required String feature}) async {
    final headers = await authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/excel-access-requests/me?feature=$feature'),
      headers: headers,
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body == null) return null;
      return ExcelAccessRequest.fromJson(body as Map<String, dynamic>);
    }
    throw Exception('Get my request failed: ${resp.body}');
  }

  Future<ExcelAccessRequest> createRequest({required String feature}) async {
    final headers = await authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/excel-access-requests'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'feature': feature}),
    );

    if (resp.statusCode == 201) {
      return ExcelAccessRequest.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
      );
    }

    if (resp.statusCode == 409) {
      throw Exception('Masih ada permintaan pending untuk fitur ini.');
    }

    throw Exception('Create request failed: ${resp.body}');
  }

  Future<List<ExcelAccessRequestAdminItem>> list({
    String status = 'pending',
    String q = '',
  }) async {
    final headers = await authHeaders();
    final uri = Uri.parse('$baseUrl/excel-access-requests').replace(
      queryParameters: {
        'status': status,
        if (q.trim().isNotEmpty) 'q': q.trim(),
      },
    );

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final raw = jsonDecode(resp.body) as List;
      return raw.map((e) => ExcelAccessRequestAdminItem.fromJson(e)).toList();
    }
    throw Exception('List failed: ${resp.body}');
  }

  Future<void> approve(int requestId) async {
    final headers = await authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/excel-access-requests/$requestId/approve'),
      headers: headers,
    );
    if (resp.statusCode == 200) return;
    throw Exception('Approve failed: ${resp.body}');
  }

  Future<void> reject(int requestId, {String? reason}) async {
    final headers = await authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/excel-access-requests/$requestId/reject'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'reject_reason': reason?.trim()}),
    );
    if (resp.statusCode == 200) return;
    throw Exception('Reject failed: ${resp.body}');
  }
}
