// lib/features/partner/partner_create.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class PartnerCreate extends StatefulWidget {
  const PartnerCreate({super.key});

  @override
  State<PartnerCreate> createState() => _PartnerCreateState();
}

class _PartnerCreateState extends State<PartnerCreate> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final priceController = TextEditingController();
  final segmentController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();

  bool isLoading = false;

  Future<void> _createPartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ApiService.createPartner(
        name: nameController.text,
        type: typeController.text,
        priceRange: priceController.text,
        segment: segmentController.text,
        description: descriptionController.text,
        imageUrl: imageUrlController.text,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tạo partner thành công')));

      // Clear form
      _formKey.currentState!.reset();
      nameController.clear();
      typeController.clear();
      priceController.clear();
      segmentController.clear();
      descriptionController.clear();
      imageUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Đối Tác Mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên partner
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đối tác*',
                  hintText: 'Ví dụ: May Cha',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên đối tác';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Loại hình
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Loại hình*',
                  hintText: 'Ví dụ: Trà sữa, Ăn uống, Giải trí',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập loại hình';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phân khúc giá
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Phân khúc giá*',
                  hintText: 'Ví dụ: 25.000đ – 45.000đ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập phân khúc giá';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phân khúc khách hàng
              TextFormField(
                controller: segmentController,
                decoration: const InputDecoration(
                  labelText: 'Phân khúc khách hàng*',
                  hintText: 'Ví dụ: Sinh viên – giới trẻ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập phân khúc khách hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả*',
                  hintText: 'Mô tả về đối tác',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // URL hình ảnh
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh',
                  hintText: 'https://example.com/logo.png',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Nút tạo
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _createPartner,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('TẠO ĐỐI TÁC'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    priceController.dispose();
    segmentController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}
