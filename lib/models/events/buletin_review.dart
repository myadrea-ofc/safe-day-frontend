class BuletinReview {
  final int id;
  final int rating;
  final String comment;
  final DateTime createdAt;

  final String userName;

  final String departmentName;
  final String siteName;

  final String buletinTitle;

  final String reviewerRole;
  final String buletinCreatorRole;

  BuletinReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,

    required this.userName,
    required this.departmentName,
    required this.siteName,
    required this.buletinTitle,

    required this.reviewerRole,
    required this.buletinCreatorRole,
  });

  factory BuletinReview.fromJson(Map<String, dynamic> json) {
    return BuletinReview(
      id: json['review_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '-',
      userName: json['user_name'] ?? '-',
      departmentName: json['department_name'] ?? '-',
      siteName: json['site_name'] ?? '-',
      buletinTitle: json['buletin_title'] ?? '-',
      createdAt: DateTime.parse(json['created_at']),
      reviewerRole: json['user_role'] ?? "-", // ✅ FIX
      buletinCreatorRole: json['creator_role'] ?? "-", // ✅ FIX
    );
  }
}
