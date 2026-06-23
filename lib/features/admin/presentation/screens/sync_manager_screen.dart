import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';

class SyncManagerScreen extends StatefulWidget {
  const SyncManagerScreen({super.key});

  @override
  State<SyncManagerScreen> createState() => _SyncManagerScreenState();
}

class _SyncManagerScreenState extends State<SyncManagerScreen> with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  bool _isTriggeringSync = false;
  bool _isWipingData = false;

  List<ApiSourceDto> _sources = [];
  List<ApiSyncJobDto> _syncJobs = [];

  // Tracks which source IDs are currently toggling
  final Set<String> _togglingSourceIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSyncData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSyncData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sourcesList = await _apiService.getApiSources();
      final jobsList = await _apiService.getSyncJobs();

      setState(() {
        _sources = sourcesList;
        _syncJobs = jobsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSource(ApiSourceDto source) async {
    final sourceId = source.id;
    if (_togglingSourceIds.contains(sourceId)) return;

    setState(() {
      _togglingSourceIds.add(sourceId);
    });

    try {
      final updatedSource = await _apiService.toggleApiSource(sourceId);
      final index = _sources.indexWhere((s) => s.id == sourceId);
      if (index != -1) {
        setState(() {
          _sources[index] = updatedSource;
        });

        if (mounted) {
          final statusString = updatedSource.isActive ? 'Bật' : 'Tắt';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$statusString đồng bộ từ nguồn ${updatedSource.name} thành công!', style: GoogleFonts.inter()),
              backgroundColor: updatedSource.isActive ? Colors.greenAccent : Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi bật/tắt nguồn đồng bộ: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingSourceIds.remove(sourceId);
        });
      }
    }
  }

  Future<void> _triggerSync() async {
    setState(() {
      _isTriggeringSync = true;
    });

    try {
      final success = await _apiService.triggerSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã kích hoạt đồng bộ dữ liệu! Job đang chạy nền.' : 'Kích hoạt đồng bộ thất bại.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: success ? Colors.greenAccent.shade700 : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) await _loadSyncData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kích hoạt đồng bộ: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringSync = false;
        });
      }
    }
  }

  Future<void> _wipeData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Xác nhận xóa dữ liệu', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Hành động này sẽ XÓA TOÀN BỘ dữ liệu mock trong hệ thống và không thể khôi phục.\n\nBạn có chắc chắn muốn tiếp tục?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Xóa tất cả', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isWipingData = true;
    });

    try {
      final success = await _apiService.wipeMockData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã xóa toàn bộ dữ liệu mock thành công!' : 'Xóa dữ liệu thất bại.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: success ? Colors.greenAccent.shade700 : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) await _loadSyncData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa dữ liệu: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWipingData = false;
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
          'Quản lý Đồng bộ API',
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
            Tab(text: 'Nguồn API'),
            Tab(text: 'Lịch sử Đồng bộ'),
          ],
        ),
        actions: [
          // Nút Đồng bộ ngay
          _isTriggeringSync
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded, color: Colors.greenAccent),
                  tooltip: 'Đồng bộ ngay',
                  onPressed: _triggerSync,
                ),
          // Nút Xóa dữ liệu mock
          _isWipingData
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  tooltip: 'Xóa dữ liệu mock',
                  onPressed: _wipeData,
                ),
          // Nút Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncData,
          ),
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
                        Text('Lỗi tải cấu hình đồng bộ', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white54)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadSyncData,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('Thử lại'),
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
                          _buildSourcesTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
                          _buildHistoryTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSourcesTab(bool isDark, {required Color cardColor, required Color borderColor, required Color textColor}) {
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _sources.length,
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isToggling = _togglingSourceIds.contains(source.id);
        final syncDate = source.lastSyncedAt != null ? DateTime.tryParse(source.lastSyncedAt!)?.toLocal() : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name, toggling status & switch
              Row(
                children: [
                  Icon(Icons.cloud_queue, color: source.isActive ? Colors.greenAccent : Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                        Text(
                          source.baseUrl,
                          style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  isToggling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                        )
                      : Switch(
                          value: source.isActive,
                          activeColor: Colors.purpleAccent,
                          onChanged: (_) => _toggleSource(source),
                        ),
                ],
              ),
              const Divider(height: 24, color: Colors.white10),

              // Detail Grid: rates, interval, last sync
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem('Giới hạn Tốc độ', '${source.rateLimitPerSec}/giây', subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildDetailItem('Chu kỳ', '${source.syncIntervalHours} giờ', subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Đồng bộ gần nhất',
                      syncDate != null
                          ? '${syncDate.day}/${syncDate.month} ${syncDate.hour}:${syncDate.minute.toString().padLeft(2, '0')}'
                          : 'Chưa bao giờ',
                      subtitleColor,
                      textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supported Fields Chip Row
              Text('Lĩnh vực hỗ trợ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: source.supportedFields.map((field) {
                  return Chip(
                    label: Text(field, style: GoogleFonts.inter(fontSize: 10, color: textColor)),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: labelColor)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildHistoryTab(bool isDark, {required Color cardColor, required Color borderColor, required Color textColor}) {
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    if (_syncJobs.isEmpty) {
      return Center(
        child: Text(
          'Không có lịch sử đồng bộ dữ liệu.',
          style: GoogleFonts.inter(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _syncJobs.length,
      itemBuilder: (context, index) {
        final job = _syncJobs[index];
        final isSuccess = job.status.toLowerCase() == 'success';
        final isFailed = job.status.toLowerCase() == 'failed';
        final statusColor = isSuccess
            ? Colors.greenAccent
            : (isFailed ? Colors.redAccent : Colors.amberAccent);
        final statusText = isSuccess ? 'THÀNH CÔNG' : (isFailed ? 'THẤT BẠI' : job.status.toUpperCase());
        
        final started = job.startedAt != null ? DateTime.tryParse(job.startedAt!)?.toLocal() : null;
        final finished = job.finishedAt != null ? DateTime.tryParse(job.finishedAt!)?.toLocal() : null;
        
        // Calculate duration in seconds
        String duration = 'N/A';
        if (started != null && finished != null) {
          final diff = finished.difference(started);
          duration = '${diff.inSeconds} giây';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Job Status & Source Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    job.sourceName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                  ),
                  const Spacer(),
                  if (started != null)
                    Text(
                      '${started.day}/${started.month} ${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (job.queryParams != null)
                Text(
                  'Truy vấn: ${job.queryParams}',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
              const Divider(height: 24, color: Colors.white10),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCol('Đã lấy', job.papersFetched, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Đã thêm', job.papersInserted, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Đã cập nhật', job.papersUpdated, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Thời gian', duration, subtitleColor, textColor),
                  ),
                ],
              ),

              // Error messages if failed
              if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.errorMessage!,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCol(String label, dynamic value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: labelColor)),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
