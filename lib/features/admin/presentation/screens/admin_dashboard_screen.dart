import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';
import '../../../user/auth/data/services/auth_api_service.dart';
import '../widgets/admin_ui.dart';
import 'sync_manager_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  final Map<String, TextEditingController> _settingControllers = {};

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSavingSettings = false;
  String? _error;

  int _activeSourcesCount = 0;
  int _totalJobsCount = 0;
  int _totalUsersCount = 0;
  int _lockedUsersCount = 0;
  List<SystemSettingDto> _settings = [];
  List<AuditLogDto> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _settingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _apiService.getUsers();
      final sources = await _apiService.getApiSources();
      final jobs = await _apiService.getSyncJobs();
      final settings = await _apiService.getSettings();
      final logs = await _apiService.getLogs();

      for (final setting in settings) {
        _settingControllers.putIfAbsent(setting.key, () => TextEditingController());
        _settingControllers[setting.key]!.text = setting.value;
      }

      setState(() {
        _settings = settings;
        _logs = logs;
        _activeSourcesCount = sources.where((s) => s.isActive).length;
        _totalJobsCount = jobs.length;
        _totalUsersCount = users.length;
        _lockedUsersCount = users.where((u) => u.status == 1).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final updatedSettings = _settings.map((setting) {
        return SystemSettingDto(
          key: setting.key,
          value: _settingControllers[setting.key]?.text ?? setting.value,
          description: setting.description,
          updatedBy: setting.updatedBy,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }).toList();

      final success = await _apiService.updateSettings(updatedSettings);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cấu hình hệ thống'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadDashboardData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được cấu hình: $e'), backgroundColor: const Color(0xFFDC2626), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('Quản trị hệ thống', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: palette.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.text),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = AuthApiService();
              await authService.logout();
            },
          ),
          IconButton(tooltip: 'Làm mới', icon: const Icon(Icons.refresh), onPressed: _loadDashboardData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: palette.muted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Nhật ký'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _loadDashboardData)
              : Column(
                  children: [
                    if (_apiService.isUsingMock) const AdminInfoBanner(message: 'Chưa kết nối được API Admin. Đang hiển thị dữ liệu giả lập.'),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverview(palette),
                          _buildLogs(palette),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverview(AdminPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AdminSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bảng điều khiển vận hành', style: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.w800, color: palette.text)),
                    const SizedBox(height: 4),
                    Text('Theo dõi người dùng, nguồn dữ liệu, cấu hình và lịch sử thay đổi trong một nơi.', style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: palette.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 760 ? 4 : 2;
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: count == 4 ? 1.35 : 1.12,
              children: [
                _statCard('Người dùng', _totalUsersCount.toString(), '$_lockedUsersCount đã khóa', Icons.people_alt_outlined, AppTheme.accentColor),
                _statCard('Nguồn API', _activeSourcesCount.toString(), 'đang hoạt động', Icons.hub_outlined, const Color(0xFF22C55E)),
                _statCard('Lượt sync', _totalJobsCount.toString(), 'job đã ghi nhận', Icons.sync_rounded, const Color(0xFFF59E0B)),
                _statCard('Nhật ký', _logs.length.toString(), 'hoạt động gần đây', Icons.receipt_long_outlined, AppTheme.primaryColor),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Quản lý nhanh', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: palette.text)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _shortcutCard(
                title: 'Người dùng',
                description: 'Tìm kiếm, lọc vai trò, khóa hoặc mở khóa tài khoản',
                icon: Icons.manage_accounts_outlined,
                color: AppTheme.accentColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _shortcutCard(
                title: 'Đồng bộ API',
                description: 'Bật tắt nguồn dữ liệu, chạy sync và xem lịch sử',
                icon: Icons.cloud_sync_outlined,
                color: const Color(0xFF22C55E),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncManagerScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Cấu hình hệ thống', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: palette.text)),
        const SizedBox(height: 10),
        _buildSettings(palette),
      ],
    );
  }

  Widget _statCard(String title, String value, String caption, IconData icon, Color color) {
    final palette = AdminPalette(context);
    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: palette.text)),
          Text(caption, style: GoogleFonts.inter(fontSize: 11, color: palette.muted)),
        ],
      ),
    );
  }

  Widget _shortcutCard({required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    final palette = AdminPalette(context);
    return AdminSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: palette.text)),
          const SizedBox(height: 4),
          Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, height: 1.35, color: palette.muted)),
        ],
      ),
    );
  }

  Widget _buildSettings(AdminPalette palette) {
    return AdminSurface(
      child: Column(
        children: [
          for (final setting in _settings) ...[
            _settingField(setting, palette),
            if (setting != _settings.last) Divider(height: 22, color: palette.border),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingSettings ? null : _saveSettings,
              icon: _isSavingSettings
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_isSavingSettings ? 'Đang lưu...' : 'Lưu cấu hình'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingField(SystemSettingDto setting, AdminPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_settingTitle(setting.key), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: palette.text)),
        if (setting.description != null && setting.description!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(setting.description!, style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _settingControllers[setting.key],
          style: GoogleFonts.inter(color: palette.text),
          decoration: InputDecoration(
            hintText: setting.key,
            prefixIcon: const Icon(Icons.tune),
          ),
        ),
      ],
    );
  }

  Widget _buildLogs(AdminPalette palette) {
    if (_logs.isEmpty) {
      return const AdminEmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có nhật ký', message: 'Các thay đổi quan trọng sẽ xuất hiện tại đây.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final color = _logColor(log.action);
        return AdminSurface(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminStatusPill(label: log.action, color: color),
                  const Spacer(),
                  Text(formatAdminDate(log.createdAt, includeYear: true), style: GoogleFonts.inter(fontSize: 11, color: palette.muted)),
                ],
              ),
              const SizedBox(height: 12),
              if (log.entityType != null)
                Text('${log.entityType} ${log.entityId ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: palette.text)),
              const SizedBox(height: 4),
              Text('Admin: ${log.adminUserId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
              if (log.ipAddress != null) Text('IP: ${log.ipAddress}', style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
              if (log.oldValue != null || log.newValue != null) ...[
                Divider(height: 22, color: palette.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.oldValue != null) Expanded(child: _valueBlock('Cũ', log.oldValue.toString(), const Color(0xFFEF4444), palette)),
                    if (log.oldValue != null && log.newValue != null) const SizedBox(width: 10),
                    if (log.newValue != null) Expanded(child: _valueBlock('Mới', log.newValue.toString(), const Color(0xFF22C55E), palette)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _valueBlock(String label, String value, Color color, AdminPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: palette.muted)),
        const SizedBox(height: 4),
        Text(value, maxLines: 4, overflow: TextOverflow.ellipsis, style: GoogleFonts.firaCode(fontSize: 11, color: color)),
      ],
    );
  }

  Color _logColor(String action) {
    if (action.contains('CREATE')) return const Color(0xFF22C55E);
    if (action.contains('UPDATE')) return AppTheme.accentColor;
    if (action.contains('TOGGLE') || action.contains('LOCK')) return const Color(0xFFF59E0B);
    return AppTheme.primaryColor;
  }

  String _settingTitle(String key) {
    switch (key) {
      case 'max_search_results':
        return 'Số kết quả tìm kiếm tối đa';
      case 'trend_snapshot_schedule':
        return 'Lịch tạo snapshot xu hướng';
      case 'email_from':
        return 'Email gửi thông báo';
      case 'sync_fields':
        return 'Lĩnh vực đồng bộ';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}
