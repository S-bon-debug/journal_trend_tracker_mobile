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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'API Sync Manager',
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
            Tab(text: 'API Sources'),
            Tab(text: 'Sync History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncData,
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSourcesTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
                    _buildHistoryTab(isDark, cardColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white, borderColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!, textColor: textColor),
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
                    child: _buildDetailItem('Rate Limit', '${source.rateLimitPerSec}/sec', subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildDetailItem('Interval', '${source.syncIntervalHours} hrs', subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Last Synced',
                      syncDate != null
                          ? '${syncDate.day}/${syncDate.month} ${syncDate.hour}:${syncDate.minute.toString().padLeft(2, '0')}'
                          : 'Never',
                      subtitleColor,
                      textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supported Fields Chip Row
              Text('Supported Concepts', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
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
        final statusColor = isSuccess
            ? Colors.greenAccent
            : (job.status.toLowerCase() == 'failed' ? Colors.redAccent : Colors.amberAccent);
        
        final started = job.startedAt != null ? DateTime.tryParse(job.startedAt!)?.toLocal() : null;
        final finished = job.finishedAt != null ? DateTime.tryParse(job.finishedAt!)?.toLocal() : null;
        
        // Calculate duration in seconds
        String duration = 'N/A';
        if (started != null && finished != null) {
          final diff = finished.difference(started);
          duration = '${diff.inSeconds}s';
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
                      job.status.toUpperCase(),
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
                  'Query: ${job.queryParams}',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
              const Divider(height: 24, color: Colors.white10),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCol('Fetched', job.papersFetched, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Inserted', job.papersInserted, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Updated', job.papersUpdated, subtitleColor, textColor),
                  ),
                  Expanded(
                    child: _buildMetricCol('Duration', duration, subtitleColor, textColor),
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
