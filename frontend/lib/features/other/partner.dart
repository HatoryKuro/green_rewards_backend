// lib/core/models/partner.dart
class Partner {
  final String id;
  final String name;
  final String type;
  final String priceRange;
  final String segment;
  final String description;
  final String imageUrl;
  final String status;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.priceRange,
    required this.segment,
    required this.description,
    required this.imageUrl,
    required this.status,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      priceRange: json['price_range'] ?? json['priceRange'] ?? '',
      segment: json['segment'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'price_range': priceRange,
      'segment': segment,
      'description': description,
      'image_url': imageUrl,
      'status': status,
    };
  }
}
