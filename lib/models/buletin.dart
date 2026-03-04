class Buletin {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String? image;
  final DateTime? createdAt;

  int? rating;
  String? comment;

  final String? createdByRole;
  final int? createdBySiteId;
  final int? createdById;

  final List<int> siteIds;
  final bool isForAllSites;

  Buletin({
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

  factory Buletin.fromJson(Map<String, dynamic> json) {
    return Buletin(
      id: int.parse(json['id'].toString()),
      title: json['judul']?.toString() ?? '',
      subtitle: json['sub_judul']?.toString() ?? '',
      description: json['deskripsi']?.toString() ?? '',
      image: json['gambar']?.toString(),
      createdAt:
          json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      rating: json['rating'] != null
          ? int.tryParse(json['rating'].toString())
          : null,
      comment: json['comment']?.toString(),

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
