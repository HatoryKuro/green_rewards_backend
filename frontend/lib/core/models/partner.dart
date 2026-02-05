class Partner {
  final String id;
  final String name;
  final String type;
  final String description;
  final String? imageId;
  final String status;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.imageId,
    required this.status,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      imageId: json['image_id'] ?? json['imageId'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'image_id': imageId,
      'status': status,
    };
  }

  // Lấy URL ảnh từ imageId
  String? getImageUrl(String baseUrl) {
    if (imageId != null && imageId!.isNotEmpty) {
      return '$baseUrl/image/$imageId';
    }
    return null;
  }
}
