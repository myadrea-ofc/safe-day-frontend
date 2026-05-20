class AuditLogModel {
  final int id;

  final int? userId;
  final String userName;
  final String userRole;

  final int? siteId;
  final String siteName;

  final int? departmentId;
  final String departmentName;

  final String action;
  final String module;
  final String method;
  final String endpoint;
  final String description;

  final int? responseStatus;
  final String ipAddress;
  final String deviceId;
  final String userAgent;

  final DateTime? createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.siteId,
    required this.siteName,
    required this.departmentId,
    required this.departmentName,
    required this.action,
    required this.module,
    required this.method,
    required this.endpoint,
    required this.description,
    required this.responseStatus,
    required this.ipAddress,
    required this.deviceId,
    required this.userAgent,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: _toInt(json["id"]) ?? 0,

      userId: _toInt(json["user_id"]),
      userName: _toStringValue(json["user_name"]),
      userRole: _toStringValue(json["user_role"]),

      siteId: _toInt(json["site_id"]),
      siteName: _toStringValue(json["site_name"]),

      departmentId: _toInt(json["department_id"]),
      departmentName: _toStringValue(json["department_name"]),

      action: _toStringValue(json["action"]),
      module: _toStringValue(json["module"]),
      method: _toStringValue(json["method"]),
      endpoint: _toStringValue(json["endpoint"]),
      description: _toStringValue(json["description"]),

      responseStatus: _toInt(json["response_status"]),
      ipAddress: _toStringValue(json["ip_address"]),
      deviceId: _toStringValue(json["device_id"]),
      userAgent: _toStringValue(json["user_agent"]),

      createdAt: _toDateTime(json["created_at"]),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _toStringValue(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    return text.isEmpty ? "-" : text;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}
