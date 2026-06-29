import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';
import 'user_management_screen.dart';
import 'sync_manager_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  // Stats
  int _activeSourcesCount = 0;
  int _totalJobsCount = 0;
  int _totalUsersCount = 0;
  int _lockedUsersCount = 0;

  // Lists
  List<SystemSettingDto> _settings = [];
  List<AuditLogDto> _logs = [];

  // Controllers for settings editing
  final Map<String, TextEditingController> _settingControllers = {};
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _settingControllers.values) {
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
      final settingsList = await _apiService.getSettings();
      final auditLogs = await _apiService.getLogs();

      _settings = settingsList;
      _logs = auditLogs;

      // Populate text controllers for settings
      for (var setting in _settings) {
        if (_settingControllers.containsKey(setting.key)) {
          _settingControllers[setting.key]!.text = setting.value;
        } else {
          _settingControllers[setting.key] = TextEditingController(text: setting.value);
        }
      }

      // Compute statistics
      _activeSourcesCount = sources.where((s) => s.isActive).length;
      _totalJobsCount = jobs.length;
      _totalUsersCount = users.length;
      _lockedUsersCount = users.where((u) => u.status == 1).length; // 1 is locked

      setState(() {
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
    setState(() {
      _isSavingSettings = true;
    });

    try {
      final updatedSettings = _settings.map((setting) {
        return SystemSettingDto(
          key: setting.key,
          value: _settingControllers[setting.key]?.text ?? setting.value,
          description: setting.description,
          updatedBy: '11111111-1111-1111-1111-111111111111',
          updatedAt: DateTime.now().toIso8601String(),
        );
      }).toList();

      final success = await _apiService.updateSettings(updatedSettings);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật cấu hình hệ thống thành công!', style: GoogleFonts.inter()),
              backgroundColor: Colors.purpleAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bảng điều khiển Admin',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Tổng quan & Cấu hình'),
            Tab(text: 'Nhật ký hoạt động'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text('Admin API connection error', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white54)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (_apiService.isUsingMock)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.15),
                          border: const Border(bottom: BorderSide(color: Colors.amberAccent, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa kết nối được API Admin. Đang hiển thị dữ liệu giả lập.',
                                style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
                          _buildAuditLogsTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(bool isDark, {required Color cardColor, required Color borderColor, required Color textColor}) {
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Stat Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Người dùng', 'Tổng số: $_totalUsersCount', 'Đã khóa: $_lockedUsersCount', Icons.people, Colors.blueAccent, cardColor, borderColor, textColor, subtitleColor),
              _buildStatCard('Đồng bộ API', 'Hoạt động: $_activeSourcesCount', 'Cấu hình nguồn', Icons.cloud_sync, Colors.greenAccent, cardColor, borderColor, textColor, subtitleColor),
              _buildStatCard('Lịch sử đồng bộ', 'Tổng số: $_totalJobsCount', 'Theo dõi bài báo', Icons.history, Colors.amberAccent, cardColor, borderColor, textColor, subtitleColor),
              _buildStatCard('Nhật ký hệ thống', 'Tổng số: ${_logs.length}', 'Thay đổi gần đây', Icons.assignment, Colors.purpleAccent, cardColor, borderColor, textColor, subtitleColor),
            ],
          ),
          const SizedBox(height: 24),

          // Shortcut Tiles Section
          Text('Quản lý nhanh', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(
                  title: 'Quản lý Người dùng',
                  desc: 'Khóa / Mở khóa tài khoản',
                  icon: Icons.people_outline,
                  color: Colors.blueAccent,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShortcutCard(
                  title: 'Quản lý Đồng bộ API',
                  desc: 'Bật/tắt nguồn API & lịch sử',
                  icon: Icons.cloud_sync_outlined,
                  color: Colors.greenAccent,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncManagerScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // System Settings Editor
          Text('Cấu hình hệ thống', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._settings.map((setting) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              setting.key,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purpleAccent),
                            ),
                            const Spacer(),
                            if (setting.description != null)
                              Tooltip(
                                message: setting.description!,
                                triggerMode: TooltipTriggerMode.tap,
                                child: const Icon(Icons.info_outline, size: 16, color: Colors.white30),
                              )
                          ],
                        ),
                        if (setting.description != null) ...[
                          const SizedBox(height: 4),
                          Text(setting.description!, style: GoogleFonts.inter(fontSize: 11, color: subtitleColor)),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: TextField(
                            controller: _settingControllers[setting.key],
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSavingSettings
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(
                      _isSavingSettings ? 'Đang lưu...' : 'Lưu cấu hình',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onPressed: _isSavingSettings ? null : _saveSettings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String primaryStat,
    String secondaryStat,
    IconData icon,
    Color color,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.7)),
              )
            ],
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: subtitleColor)),
          const SizedBox(height: 4),
          Text(primaryStat, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(secondaryStat, style: GoogleFonts.inter(fontSize: 11, color: subtitleColor)),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: subtitleColor), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogsTab(bool isDark, {required Color cardColor, required Color borderColor, required Color textColor}) {
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    if (_logs.isEmpty) {
      return Center(
        child: Text(
          'Không có nhật ký hoạt động.',
          style: GoogleFonts.inter(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final actionColor = _getLogActionColor(log.action);
        final date = DateTime.tryParse(log.createdAt)?.toLocal() ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: actionColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      log.action,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 11, color: actionColor),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (log.entityType != null)
                Text(
                  'Đối tượng: ${log.entityType} (${log.entityId ?? 'Không có'})',
                  style: GoogleFonts.inter(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 4),
              Text(
                'Mã Admin: ${log.adminUserId}',
                style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
              ),
              if (log.ipAddress != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Địa chỉ IP: ${log.ipAddress}',
                  style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
                ),
              ],
              if (log.oldValue != null || log.newValue != null) ...[
                const Divider(height: 24, color: Colors.white10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.oldValue != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá trị cũ', style: GoogleFonts.inter(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(log.oldValue.toString(), style: GoogleFonts.firaCode(fontSize: 10, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    if (log.oldValue != null && log.newValue != null)
                      const SizedBox(width: 16),
                    if (log.newValue != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá trị mới', style: GoogleFonts.inter(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(log.newValue.toString(), style: GoogleFonts.firaCode(fontSize: 10, color: Colors.greenAccent)),
                          ],
                        ),
                      ),
                  ],
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Color _getLogActionColor(String action) {
    if (action.contains('CREATE')) return Colors.greenAccent;
    if (action.contains('UPDATE')) return Colors.blueAccent;
    if (action.contains('TOGGLE') || action.contains('LOCK')) return Colors.amberAccent;
    return Colors.purpleAccent;
  }
}
