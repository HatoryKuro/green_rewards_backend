import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerList extends StatefulWidget {
  const PartnerList({super.key});

  @override
  State<PartnerList> createState() => _PartnerListState();
}

class _PartnerListState extends State<PartnerList> {
  int expandedIndex = -1;

  final List<Map<String, String>> partners = [
    {
      'name': 'May Cha',
      'type': 'Trà sữa',
      'price': '25.000đ – 45.000đ',
      'segment': 'Sinh viên – giới trẻ',
      'desc': 'Phong cách trẻ trung, vị trà đậm, topping đa dạng',
    },
    {
      'name': 'TuTiMi',
      'type': 'Trà sữa',
      'price': '30.000đ – 50.000đ',
      'segment': 'Học sinh – sinh viên',
      'desc': 'Vị ngọt vừa, menu dễ uống, giá mềm',
    },
    {
      'name': 'Sunday Basic',
      'type': 'Trà sữa / Đồ uống',
      'price': '35.000đ – 60.000đ',
      'segment': 'Dân văn phòng',
      'desc': 'Thiết kế tối giản, đồ uống hiện đại',
    },
    {
      'name': 'Sóng Sánh',
      'type': 'Trà sữa',
      'price': '28.000đ – 48.000đ',
      'segment': 'Giới trẻ',
      'desc': 'Trân châu ngon, vị béo rõ',
    },
    {
      'name': 'Te Amo',
      'type': 'Trà sữa',
      'price': '30.000đ – 55.000đ',
      'segment': 'Cặp đôi – giới trẻ',
      'desc': 'Phong cách lãng mạn, menu sáng tạo',
    },
    {
      'name': 'Trà Sữa Boss',
      'type': 'Trà sữa',
      'price': '25.000đ – 45.000đ',
      'segment': 'Sinh viên',
      'desc': 'Giá rẻ, topping nhiều',
    },
    {
      'name': 'Hồng Trà Ngô Gia',
      'type': 'Trà / Hồng trà',
      'price': '40.000đ – 70.000đ',
      'segment': 'Khách thích trà nguyên vị',
      'desc': 'Trà đậm vị, ít ngọt, cao cấp',
    },
    {
      'name': 'Lục Trà Thăng Hoa',
      'type': 'Trà trái cây',
      'price': '35.000đ – 60.000đ',
      'segment': 'Người thích healthy',
      'desc': 'Trà thanh, trái cây tươi',
    },
    {
      'name': 'Viên Viên',
      'type': 'Trà sữa',
      'price': '30.000đ – 50.000đ',
      'segment': 'Giới trẻ',
      'desc': 'Vị béo, topping handmade',
    },
    {
      'name': 'TocoToco',
      'type': 'Trà sữa',
      'price': '30.000đ – 55.000đ',
      'segment': 'Đại chúng',
      'desc': 'Chuỗi lớn, chất lượng ổn định',
    },
  ];

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
      appBar: AppBar(title: const Text('Danh sách đối tác')),
      body: ListView.builder(
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/partners/${i + 1}.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    p['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(p['type']!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.green),
                        onPressed: () => openMap(p['name']!),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
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
                        Text('• Giá: ${p['price']}'),
                        Text('• Đặc điểm: ${p['desc']}'),
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
}
