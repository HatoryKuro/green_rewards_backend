import '../../core/services/api_service.dart';

// lib/core/models/partner.dart
class Partner {
  final String id;
  final String name;
  final String type;
  final String priceRange;
  final String segment;
  final String description;
  final String? imageId; // Thay đổi từ imageUrl sang imageId
  final String status;
  final String? imageUrl; // Giữ lại cho tương thích (tự động tạo từ imageId)

  Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.priceRange,
    required this.segment,
    required this.description,
    this.imageId,
    required this.status,
    this.imageUrl,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      priceRange: json['price_range'] ?? json['priceRange'] ?? '',
      segment: json['segment'] ?? '',
      description: json['description'] ?? '',
      imageId: json['image_id'] ?? json['imageId'], // Lấy image_id từ backend
      status: json['status'] ?? 'active',
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'price_range': priceRange,
      'segment': segment,
      'description': description,
      'image_id': imageId, // Gửi image_id thay vì image_url
      'status': status,
    };
  }

  // Helper để lấy URL ảnh
  String? get imageUrlFromId {
    if (imageId != null && imageId!.isNotEmpty) {
      // Tạo URL từ imageId (sẽ được xử lý bởi ApiService)
      return ApiService.getImageUrl(imageId!);
    }
    return null;
  }
}
