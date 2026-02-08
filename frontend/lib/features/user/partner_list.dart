import 'package:flutter/material.dart';
import 'package:green_rewards/features/admin/partner_create.dart';
import '../../core/services/api_service.dart';
import '../../core/services/user_preferences.dart'; // Thêm import helper class
import '../../core/models/partner.dart';

class PartnerList extends StatefulWidget {
  const PartnerList({super.key});

  @override
  State<PartnerList> createState() => _PartnerListState();
}

class _PartnerListState extends State<PartnerList> {
  List<Partner> _partners = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;
  int? _expandedIndex;
  bool _isAdmin = false; // Biến kiểm tra role admin

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load role trước
    _loadPartners();
  }

  // 🔥 Load role từ UserPreferences helper class
  Future<void> _loadUserRole() async {
    try {
      final isAdmin = await UserPreferences.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      print('Lỗi khi load role: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getPartners();
      setState(() {
        _partners = response
            .map<Partner>((json) => Partner.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Không thể tải danh sách đối tác: ${ApiService.cleanErrorMessage(e.toString())}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPartners() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final response = await ApiService.getPartners();
      setState(() {
        _partners = response
            .map<Partner>((json) => Partner.fromJson(json))
            .toList();
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Lỗi khi làm mới: ${ApiService.cleanErrorMessage(e.toString())}';
        _isRefreshing = false;
      });
    }
  }

  Future<void> _deletePartner(String partnerId, String partnerName) async {
    // 🔥 Chỉ admin mới được xóa
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ admin mới có quyền xóa đối tác'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa đối tác "$partnerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        final success = await ApiService.deletePartner(partnerId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa đối tác "$partnerName"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadPartners();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa đối tác thất bại'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi xóa: ${ApiService.cleanErrorMessage(e.toString())}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPartnerImage(Partner partner) {
    final imageUrl = partner.getImageUrl();

    if (imageUrl.isNotEmpty) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildDefaultImage();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultImage();
            },
          ),
        ),
      );
    }

    return _buildDefaultImage();
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: const Icon(Icons.store, color: Colors.grey, size: 32),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang tải danh sách đối tác...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 80),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPartners,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          const Text(
            'Không có đối tác nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách đối tác đang trống',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          // 🔥 Chỉ admin mới thấy nút tạo partner mới
          if (_isAdmin) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerCreate()),
                ).then((_) {
                  _loadPartners(); // Refresh sau khi tạo mới
                });
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Thêm đối tác mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerItem(Partner partner, int index) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: _buildPartnerImage(partner),
              title: Text(
                partner.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Text(
                          partner.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (partner.description.isNotEmpty)
                    Text(
                      partner.description,
                      maxLines: isExpanded ? null : 1,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    tooltip: isExpanded ? 'Thu gọn' : 'Xem thêm',
                  ),
                  // 🔥 CHỈ HIỆN NÚT XÓA NẾU LÀ ADMIN
                  if (_isAdmin)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 22,
                      ),
                      onPressed: () => _deletePartner(partner.id, partner.name),
                      tooltip: 'Xóa đối tác',
                    ),
                ],
              ),
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
            ),

            // Xem thêm thông tin khi mở rộng
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (partner.description.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mô tả chi tiết',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              partner.description,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Thông tin thêm (nếu có)
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.image,
                          label: partner.getImageUrl().isNotEmpty
                              ? 'Có ảnh'
                              : 'Không có ảnh',
                          color: partner.getImageUrl().isNotEmpty
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.verified,
                          label: partner.status == 'active'
                              ? 'Đang hoạt động'
                              : 'Ngừng hoạt động',
                          color: partner.status == 'active'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerList() {
    return RefreshIndicator(
      color: Colors.green,
      backgroundColor: Colors.white,
      onRefresh: _refreshPartners,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _partners.length,
        itemBuilder: (context, index) {
          return _buildPartnerItem(_partners[index], index);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_partners.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPartnerList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách đối tác',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.green[50],
              radius: 18,
              child: Text(
                _partners.length.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
          // 🔥 Hiện badge admin nếu là admin
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.green[700],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                : Icon(Icons.refresh, color: Colors.green[700]),
            onPressed: _isRefreshing ? null : _refreshPartners,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
