class DailyPlanReview {
  final int id;
  final int rating;
  final String comment;
  final String userName;
  final String departmentName;
  final String siteName;
  final String dailyPlanTitle;
  final DateTime createdAt;

  final String reviewerRole;
  final String dailyPlanCreatorRole;

  DailyPlanReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.departmentName,
    required this.siteName,
    required this.dailyPlanTitle,
    required this.createdAt,
    required this.reviewerRole,
    required this.dailyPlanCreatorRole,
  });

  factory DailyPlanReview.fromJson(Map<String, dynamic> json) {
    return DailyPlanReview(
      id: json['review_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '-',
      userName: json['user_name'] ?? '-',
      departmentName: json['department_name'] ?? '-',
      siteName: json['site_name'] ?? '-',
      dailyPlanTitle: json['daily_plan_title'] ?? '-',
      createdAt: DateTime.parse(json['created_at']),
      reviewerRole: json['user_role'] ?? "-", // ✅ FIX
      dailyPlanCreatorRole: json['creator_role'] ?? "-", // ✅ FIX
    );
  }
}
