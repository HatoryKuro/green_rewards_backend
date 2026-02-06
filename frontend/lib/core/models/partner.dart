import 'package:green_rewards/core/services/api_service.dart';

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
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      imageId: json['image_id'] ?? json['imageId'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'image_id': imageId,
      'status': status,
    };
  }

  // Helper method để lấy URL ảnh
  String getImageUrl() {
    return ApiService.getImageUrl(imageId);
  }
}
