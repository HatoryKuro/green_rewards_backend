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
  final List<String> _typeOptions = [
    'trà',
    'trà sữa',
    'đồ uống',
    'cà phê',
    'sinh tố',
    'detox',
  ];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'trà sữa';
  File? _selectedImage;
  bool _isLoading = false;
  String? _imageError;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageError = null;
      });
    }
  }

  Future<void> _createPartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _imageError = null;
    });

    try {
      // 1. Tạo partner trước (không có image_id ban đầu)
      final partnerResult = await ApiService.createPartner(
        name: _nameController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim(),
      );

      // 2. Lấy partnerId từ kết quả trả về
      // QUAN TRỌNG: API trả về {"message": "...", "partner_id": "..."}
      // KHÔNG PHẢI "_id" hay "id"
      final partnerId = partnerResult['partner_id']?.toString();

      // Debug: In ra toàn bộ response để kiểm tra
      print('API Response: $partnerResult');
      print('Partner ID từ API: $partnerId');

      if (partnerId == null || partnerId.isEmpty) {
        throw Exception(
          'Không lấy được ID của partner từ server. Response: $partnerResult',
        );
      }

      // 3. Nếu có ảnh, upload ảnh
      if (_selectedImage != null) {
        try {
          await ApiService.uploadPartnerImageFile(
            partnerId: partnerId,
            imageFile: _selectedImage!,
          );
        } catch (e) {
          // Vẫn thành công nếu partner đã tạo, chỉ báo lỗi upload ảnh
          print('Lỗi upload ảnh: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tạo đối tác thành công nhưng upload ảnh thất bại: ${ApiService.cleanErrorMessage(e.toString())}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // 4. Thông báo thành công và quay lại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo đối tác thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _resetForm();

        // Quay lại với kết quả thành công
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      String errorMessage = ApiService.cleanErrorMessage(e.toString());

      // Debug: In lỗi ra console
      print('Lỗi khi tạo partner: $errorMessage');

      // Xử lý lỗi cụ thể từ API
      if (errorMessage.contains('Partner name already exists')) {
        errorMessage = 'Tên đối tác đã tồn tại. Vui lòng chọn tên khác.';
      } else if (errorMessage.contains('Database không khả dụng')) {
        errorMessage = 'Database không khả dụng. Vui lòng thử lại sau.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = 'trà sữa';
      _selectedImage = null;
      _imageError = null;
    });
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 48),
          const SizedBox(height: 8),
          Text(
            'Thêm ảnh',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '(Không bắt buộc)',
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
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
            icon: const Icon(Icons.clear_all),
            onPressed: _resetForm,
            tooltip: 'Xóa toàn bộ',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh đối tác
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: _buildImagePreview(),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Chọn ảnh từ thư viện'),
                  ),
                ),
                if (_imageError != null)
                  Center(
                    child: Text(
                      _imageError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(),

                // Tên đối tác
                const Text(
                  'Thông tin cơ bản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên cửa hàng*',
                    hintText: 'Ví dụ: May Cha Tea',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên cửa hàng';
                    }
                    if (value.trim().length < 2) {
                      return 'Tên cửa hàng phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Loại hình (Dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại hình*',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _typeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
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
                  controller: _descriptionController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả*',
                    hintText:
                        'Mô tả về cửa hàng, địa điểm, đặc điểm nổi bật...',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mô tả';
                    }
                    if (value.trim().length < 10) {
                      return 'Mô tả phải có ít nhất 10 ký tự';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mô tả giúp người dùng hiểu rõ hơn về đối tác của bạn',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 32),

                // Nút tạo
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createPartner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'TẠO ĐỐI TÁC',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Thông báo
                if (_isLoading)
                  const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Text(
                          'Đang tạo đối tác...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
