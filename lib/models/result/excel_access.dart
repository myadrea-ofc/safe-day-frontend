class ExcelAccess {
  final int userId;
  final String userName;
  final String userRole;
  final int siteId;
  final String siteName;
  final String feature;
  bool canDownload;
  final int grantedBy;
  DateTime createdAt;
  bool seenByAdmin;

  ExcelAccess({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.siteId,
    required this.siteName,
    required this.canDownload,
    required this.grantedBy,
    required this.createdAt,
    required this.seenByAdmin,
    required this.feature,
  });
}
