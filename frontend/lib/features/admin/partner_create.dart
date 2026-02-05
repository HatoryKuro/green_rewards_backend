import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/models/partner.dart';

class PartnerCreate extends StatefulWidget {
  const PartnerCreate({super.key});

  @override
  State<PartnerCreate> createState() => _PartnerCreateState();
}

class _PartnerCreateState extends State<PartnerCreate> {
  final _formKey = GlobalKey<FormState>();
  final List<String> typeOptions = [
    'trà',
    'trà sữa',
    'đồ uống',
    'cà phê',
    'sinh tố',
    'detox',
  ];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedType = 'trà sữa';
  File? _selectedImage;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. Tạo partner trước
      final result = await ApiService.createPartner(
        name: nameController.text,
        type: selectedType,
        description: descriptionController.text,
      );

      final partnerId = result['partner_id'];

      // 2. Nếu có ảnh, upload ảnh
      if (_selectedImage != null && partnerId != null) {
        try {
          await ApiService.uploadPartnerImage(
            partnerId: partnerId,
            imagePath: _selectedImage!.path,
          );
        } catch (e) {
          // Vẫn thành công nếu partner đã tạo
          print('Lỗi upload ảnh: $e');
        }
      }

      // 3. Thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tạo đối tác thành công')));

        // Reset form
        _resetForm();

        // Quay lại sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    descriptionController.clear();
    setState(() {
      selectedType = 'trà sữa';
      _selectedImage = null;
    });
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'Chọn ảnh',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Đối Tác Mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _resetForm,
            tooltip: 'Xóa form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(_selectedImage == null ? 'Chọn ảnh' : 'Đổi ảnh'),
                ),
              ),
              const SizedBox(height: 24),

              // Tên đối tác
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng*',
                  hintText: 'Ví dụ: May Cha',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên cửa hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Loại hình (Dropdown)
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại hình*',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: typeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn loại hình';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả*',
                  hintText: 'Mô tả về cửa hàng...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút tạo
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _createPartner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'TẠO ĐỐI TÁC',
                          style: TextStyle(fontSize: 16),
                        ),
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
    descriptionController.dispose();
    super.dispose();
  }
}
