import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _selectedImage;
  String? _imageId; // ID của ảnh sau khi upload
  bool isLoading = false;
  bool isUploadingImage = false;

  // Chọn ảnh từ gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageId = null; // Reset imageId khi chọn ảnh mới
      });
    }
  }

  // Upload ảnh lên server
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => isUploadingImage = true);

    try {
      // Ở đây chưa có partner_id, nên chưa thể upload ảnh
      // Chúng ta sẽ upload ảnh sau khi tạo partner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ảnh sẽ được upload sau khi tạo partner')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  // Tạo partner mới
  Future<void> _createPartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Tạo partner trước (chưa có ảnh)
      final result = await ApiService.createPartner(
        name: nameController.text,
        type: typeController.text,
        priceRange: priceController.text,
        segment: segmentController.text,
        description: descriptionController.text,
        imageId: _imageId, // Có thể null
      );

      final partnerId = result['partner_id'];

      // Nếu có ảnh đã chọn, upload ảnh
      if (_selectedImage != null && partnerId != null) {
        try {
          final uploadResult = await ApiService.uploadPartnerImage(
            partnerId: partnerId,
            imagePath: _selectedImage!.path,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tạo partner và upload ảnh thành công')),
          );
        } catch (e) {
          // Partner đã tạo nhưng upload ảnh thất bại
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Partner đã tạo, nhưng upload ảnh thất bại: $e'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tạo partner thành công')));
      }

      // Clear form
      _resetForm();

      // Quay lại màn hình trước sau 2 giây
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    typeController.clear();
    priceController.clear();
    segmentController.clear();
    descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _imageId = null;
    });
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Đã chọn ảnh',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(Icons.image, color: Colors.grey[400], size: 40),
        ),
        SizedBox(height: 8),
        Text(
          'Chưa có ảnh',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Đối Tác Mới'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
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
              // Preview ảnh
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _buildImagePreview(),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library, size: 18),
                  label: Text(_selectedImage == null ? 'Chọn ảnh' : 'Đổi ảnh'),
                ),
              ),
              SizedBox(height: 24),

              // Tên partner
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đối tác*',
                  hintText: 'Ví dụ: May Cha',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên đối tác';
                  }
                  if (value.length < 2) {
                    return 'Tên quá ngắn';
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
                  prefixIcon: Icon(Icons.category),
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
                  prefixIcon: Icon(Icons.attach_money),
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
                  prefixIcon: Icon(Icons.people),
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
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  if (value.length < 10) {
                    return 'Mô tả quá ngắn';
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
                  onPressed: (isLoading || isUploadingImage)
                      ? null
                      : _createPartner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading || isUploadingImage)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        isLoading
                            ? 'ĐANG TẠO...'
                            : isUploadingImage
                            ? 'ĐANG UPLOAD...'
                            : 'TẠO ĐỐI TÁC',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
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
    typeController.dispose();
    priceController.dispose();
    segmentController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
