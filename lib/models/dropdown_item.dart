class DropdownItemModel {
  final int? id;
  final String label;
  final bool isOther;

  DropdownItemModel({
    required this.id,
    required this.label,
    this.isOther = false,
  });

  factory DropdownItemModel.fromJson(Map<String, dynamic> json) {
    return DropdownItemModel(id: json['id'], label: json['label'] ?? '');
  }

  @override
  String toString() => label;
}
