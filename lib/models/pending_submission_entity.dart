class PendingSubmissionEntity {
  final String id;
  final String module;
  final String title;
  final String subtitle;
  final Map<String, dynamic> payload;
  final List<String> localFiles;
  final String status;
  final DateTime createdAt;
  final int retryCount;

  PendingSubmissionEntity({
    required this.id,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.payload,
    required this.localFiles,
    required this.status,
    required this.createdAt,
    required this.retryCount,
  });

  PendingSubmissionEntity copyWith({
    String? id,
    String? module,
    String? title,
    String? subtitle,
    Map<String, dynamic>? payload,
    List<String>? localFiles,
    String? status,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingSubmissionEntity(
      id: id ?? this.id,
      module: module ?? this.module,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      payload: payload ?? this.payload,
      localFiles: localFiles ?? this.localFiles,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module,
      'title': title,
      'subtitle': subtitle,
      'payload': payload,
      'localFiles': localFiles,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingSubmissionEntity.fromMap(Map<dynamic, dynamic> map) {
    return PendingSubmissionEntity(
      id: map['id']?.toString() ?? '',
      module: map['module']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      localFiles: List<String>.from(map['localFiles'] ?? const []),
      status: map['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    );
  }
}
