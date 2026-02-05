import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';

class PartnerList extends StatefulWidget {
  const PartnerList({super.key});

  @override
  State<PartnerList> createState() => _PartnerListState();
}

class _PartnerListState extends State<PartnerList> {
  int expandedIndex = -1;
  List<Map<String, dynamic>> partners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    try {
      final response = await ApiService.getPartners();
      setState(() {
        partners = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      // Fallback: dùng danh sách hardcode nếu API fail
      setState(() {
        partners = [
          {
            'name': 'May Cha',
            'type': 'Trà sữa',
            'price_range': '25.000đ – 45.000đ',
            'segment': 'Sinh viên – giới trẻ',
            'description': 'Phong cách trẻ trung, vị trà đậm, topping đa dạng',
          },
          // ... các partner khác
        ];
        isLoading = false;
      });
    }
  }

  Future<void> openMap(String name) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$name',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đối tác'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPartners),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: partners.length,
              itemBuilder: (_, i) {
                final p = partners[i];
                final isExpanded = expandedIndex == i;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _buildPartnerImage(p, i),
                        title: Text(
                          p['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(p['type'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.green),
                              onPressed: () => openMap(p['name']),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            expandedIndex = isExpanded ? -1 : i;
                          });
                        },
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• Đồ uống: ${p['type']}'),
                              Text('• Phân khúc: ${p['segment']}'),
                              Text('• Giá: ${p['price_range']}'),
                              Text('• Đặc điểm: ${p['description']}'),
                              const Text('• Áp dụng tích điểm GreenPoints'),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPartnerImage(Map<String, dynamic> p, int index) {
    final imageUrl = p['image_url'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(index);
          },
        ),
      );
    }

    return _buildDefaultImage(index);
  }

  Widget _buildDefaultImage(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.grey[200],
        child: Icon(Icons.store, color: Colors.grey[600]),
      ),
    );
  }
}
