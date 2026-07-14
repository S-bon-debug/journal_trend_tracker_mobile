import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';
import '../widgets/admin_ui.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  final Set<String> _togglingUserIds = {};

  List<AdminUserDto> _allUsers = [];
  List<AdminUserDto> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _selectedRoleFilter = -1;
  int _selectedStatusFilter = -1;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _apiService.getUsers();
      setState(() {
        _allUsers = users;
        _applyFiltersAndSearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSearch() {
    final query = _searchQuery.trim().toLowerCase();
    _filteredUsers = _allUsers.where((user) {
      final matchesSearch = query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query);
      final matchesRole = _selectedRoleFilter == -1 || user.role == _selectedRoleFilter;
      final matchesStatus = _selectedStatusFilter == -1 || user.status == _selectedStatusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _toggleUserStatus(AdminUserDto user) async {
    if (_togglingUserIds.contains(user.id)) return;

    setState(() => _togglingUserIds.add(user.id));

    try {
      final success = await _apiService.toggleUserStatus(user.id);
      if (!success) return;

      final index = _allUsers.indexWhere((u) => u.id == user.id);
      if (index == -1) return;

      final current = _allUsers[index];
      final nextStatus = current.status == 0 ? 1 : 0;
      setState(() {
        _allUsers[index] = AdminUserDto(
          id: current.id,
          fullName: current.fullName,
          email: current.email,
          avatarUrl: current.avatarUrl,
          provider: current.provider,
          role: current.role,
          status: nextStatus,
          lastLoginAt: current.lastLoginAt,
          createdAt: current.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        _applyFiltersAndSearch();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextStatus == 0 ? 'Đã mở khóa ${current.fullName}' : 'Đã khóa ${current.fullName}'),
          backgroundColor: nextStatus == 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đổi được trạng thái: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingUserIds.remove(user.id));
    }
  }

  Future<void> _confirmDeactivateUser(AdminUserDto user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vô hiệu hóa tài khoản', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc chắn muốn vô hiệu hóa tài khoản của ${user.fullName} (${user.email}) không? Người dùng này sẽ không thể đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deactivateUser(user);
    }
  }

  Future<void> _deactivateUser(AdminUserDto user) async {
    if (_togglingUserIds.contains(user.id)) return;

    setState(() => _togglingUserIds.add(user.id));

    try {
      final success = await _apiService.deleteUser(user.id);
      if (!success) return;

      final index = _allUsers.indexWhere((u) => u.id == user.id);
      if (index == -1) return;

      final current = _allUsers[index];
      setState(() {
        _allUsers[index] = AdminUserDto(
          id: current.id,
          fullName: current.fullName,
          email: current.email,
          avatarUrl: current.avatarUrl,
          provider: current.provider,
          role: current.role,
          status: 1, // Locked / Deactivated
          lastLoginAt: current.lastLoginAt,
          createdAt: current.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        _applyFiltersAndSearch();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã vô hiệu hóa tài khoản ${current.fullName}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể vô hiệu hóa tài khoản: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingUserIds.remove(user.id));
    }
  }

  void _showUserDetails(AdminUserDto user) {
    final palette = AdminPalette(context);
    
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'Chưa đăng nhập';
      try {
        final date = DateTime.parse(dateStr).toLocal();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return dateStr;
      }
    }

    String getProviderLabel(int provider) {
      switch (provider) {
        case 1:
          return 'Google OAuth';
        case 2:
          return 'GitHub';
        default:
          return 'Email & Mật khẩu';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(user.role).withOpacity(0.14),
              backgroundImage: user.avatarUrl == null ? null : NetworkImage(user.avatarUrl!),
              child: user.avatarUrl == null
                  ? Text(_initials(user.fullName), style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chi tiết tài khoản',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: palette.text, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _detailRow('Họ và tên', user.fullName, palette),
              _detailRow('Email', user.email, palette),
              _detailRow('Vai trò', _roleLabel(user.role), palette, customColor: _getRoleColor(user.role)),
              _detailRow('Trạng thái', _statusLabel(user.status), palette, customColor: _getStatusColor(user.status)),
              _detailRow('Hình thức đăng ký', getProviderLabel(user.provider), palette),
              _detailRow('Đăng nhập cuối', formatDate(user.lastLoginAt), palette),
              _detailRow('Ngày tham gia', formatDate(user.createdAt), palette),
              _detailRow('Cập nhật cuối', formatDate(user.updatedAt), palette),
              _detailRow('Mã người dùng (UUID)', user.id, palette, isSelectable: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, AdminPalette palette, {Color? customColor, bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: palette.muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          isSelectable
              ? SelectableText(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: customColor ?? palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: customColor ?? palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette(context);
    final activeUsers = _allUsers.where((u) => u.status == 0).length;
    final lockedUsers = _allUsers.where((u) => u.status == 1).length;
    final adminUsers = _allUsers.where((u) => u.role == 3).length;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('Người dùng', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: palette.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.text),
        actions: [
          IconButton(tooltip: 'Làm mới', icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _loadUsers)
              : Column(
                  children: [
                    if (_apiService.isUsingMock) const AdminInfoBanner(message: 'Chưa kết nối được API Admin. Đang hiển thị dữ liệu giả lập.'),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        children: [
                          _buildHeader(palette, activeUsers, lockedUsers, adminUsers),
                          const SizedBox(height: 12),
                          _buildFilters(palette),
                          const SizedBox(height: 12),
                          _filteredUsers.isEmpty
                              ? const SizedBox(
                                  height: 300,
                                  child: AdminEmptyState(
                                    icon: Icons.person_search_outlined,
                                    title: 'Không tìm thấy người dùng',
                                    message: 'Thử đổi từ khóa, vai trò hoặc trạng thái lọc.',
                                  ),
                                )
                              : Column(
                                  children: _filteredUsers.map((user) {
                                    return _buildUserCard(user, palette);
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(AdminPalette palette, int activeUsers, int lockedUsers, int adminUsers) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.manage_accounts_outlined, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quản lý tài khoản', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: palette.text)),
                    const SizedBox(height: 3),
                    Text('${_filteredUsers.length}/${_allUsers.length} người dùng phù hợp bộ lọc', style: GoogleFonts.inter(fontSize: 13, color: palette.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Hoạt động', activeUsers.toString(), const Color(0xFF22C55E), palette),
              _metric('Đã khóa', lockedUsers.toString(), const Color(0xFFEF4444), palette),
              _metric('Admin', adminUsers.toString(), AppTheme.primaryColor, palette),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color, AdminPalette palette) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(AdminPalette palette) {
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            style: GoogleFonts.inter(color: palette.text),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: palette.muted),
              hintText: 'Tìm theo tên, email hoặc UUID',
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _applyFiltersAndSearch();
                        });
                      },
                    ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFiltersAndSearch();
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _filterDropdown(palette, _selectedRoleFilter, _roleItems(), (value) => _selectedRoleFilter = value)),
              const SizedBox(width: 10),
              Expanded(child: _filterDropdown(palette, _selectedStatusFilter, _statusItems(), (value) => _selectedStatusFilter = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(AdminPalette palette, int value, List<DropdownMenuItem<int>> items, ValueChanged<int> update) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items,
      dropdownColor: palette.card,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
      style: GoogleFonts.inter(color: palette.text, fontSize: 13),
      onChanged: (next) {
        setState(() {
          update(next ?? -1);
          _applyFiltersAndSearch();
        });
      },
    );
  }

  List<DropdownMenuItem<int>> _roleItems() => const [
        DropdownMenuItem(value: -1, child: Text('Tất cả vai trò')),
        DropdownMenuItem(value: 0, child: Text('Nhà nghiên cứu')),
        DropdownMenuItem(value: 1, child: Text('Giảng viên')),
        DropdownMenuItem(value: 2, child: Text('Sinh viên')),
        DropdownMenuItem(value: 3, child: Text('Quản trị viên')),
      ];

  List<DropdownMenuItem<int>> _statusItems() => const [
        DropdownMenuItem(value: -1, child: Text('Tất cả trạng thái')),
        DropdownMenuItem(value: 0, child: Text('Đang hoạt động')),
        DropdownMenuItem(value: 1, child: Text('Đã khóa')),
        DropdownMenuItem(value: 2, child: Text('Chờ duyệt')),
      ];

  Widget _getProviderPill(int provider) {
    switch (provider) {
      case 1:
        return const AdminStatusPill(label: 'Google', color: Color(0xFFEA4335), icon: Icons.g_mobiledata_rounded);
      case 2:
        return const AdminStatusPill(label: 'GitHub', color: Color(0xFF9E9E9E), icon: Icons.code_rounded);
      default:
        return const AdminStatusPill(label: 'Email', color: Color(0xFF8B5CF6), icon: Icons.mail_outline_rounded);
    }
  }

  Widget _buildUserCard(AdminUserDto user, AdminPalette palette) {
    final isToggling = _togglingUserIds.contains(user.id);
    final roleColor = _getRoleColor(user.role);
    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.35), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 23,
              backgroundColor: roleColor.withOpacity(0.12),
              backgroundImage: user.avatarUrl == null ? null : NetworkImage(user.avatarUrl!),
              child: user.avatarUrl == null
                  ? Text(
                      _initials(user.fullName),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: roleColor, fontSize: 15),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w800, color: palette.text),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.5, color: palette.muted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminStatusPill(label: _roleLabel(user.role), color: roleColor),
                    AdminStatusPill(label: _statusLabel(user.status), color: _getStatusColor(user.status)),
                    _getProviderPill(user.provider),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Xem chi tiết',
                onPressed: () => _showUserDetails(user),
                icon: const Icon(Icons.info_outline_rounded),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              isToggling
                  ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                  : user.status == 1
                      ? IconButton.filledTonal(
                          tooltip: 'Mở khóa tài khoản',
                          onPressed: () => _toggleUserStatus(user),
                          icon: const Icon(Icons.lock_open_rounded),
                          color: const Color(0xFF16A34A),
                        )
                      : IconButton.filledTonal(
                          tooltip: 'Vô hiệu hóa tài khoản',
                          onPressed: () => _confirmDeactivateUser(user),
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: const Color(0xFFDC2626),
                        ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  String _roleLabel(int role) {
    switch (role) {
      case 3:
        return 'Admin';
      case 1:
        return 'Giảng viên';
      case 0:
        return 'Nghiên cứu';
      default:
        return 'Sinh viên';
    }
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0:
        return 'Hoạt động';
      case 1:
        return 'Đã khóa';
      default:
        return 'Chờ duyệt';
    }
  }

  Color _getRoleColor(int role) {
    switch (role) {
      case 3:
        return AppTheme.primaryColor;
      case 1:
        return AppTheme.accentColor;
      case 0:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return const Color(0xFF22C55E);
      case 1:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
