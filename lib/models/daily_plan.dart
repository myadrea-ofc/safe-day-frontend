class DailyPlan {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String? image;
  final DateTime? createdAt;

  final String? createdByRole;
  final int? createdBySiteId;
  final int? createdById;

  int? rating;
  String? comment;

  final List<int> siteIds;
  final bool isForAllSites;

  DailyPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.image,
    this.createdAt,
    this.rating,
    this.comment,
    this.createdByRole,
    this.createdBySiteId,
    this.createdById,

    this.siteIds = const [],
    this.isForAllSites = false,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: int.parse(json['id'].toString()),
      title: json['judul'] ?? '',
      subtitle: json['sub_judul'] ?? '',
      description: json['deskripsi'] ?? '',
      image: json['gambar'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      rating: json['rating'],
      comment: json['comment'],
      createdByRole: json['created_by_role'],
      createdBySiteId: json['created_by_site_id'],
      createdById: json['created_by'],

      siteIds: json['site_ids'] != null
          ? List<int>.from(json['site_ids'].map((e) => int.parse(e.toString())))
          : [],
      isForAllSites: json['is_for_all_sites'] == true,
    );
  }
}
