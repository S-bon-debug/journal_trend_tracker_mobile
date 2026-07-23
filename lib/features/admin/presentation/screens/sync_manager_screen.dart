import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';
import '../widgets/admin_ui.dart';

class SyncManagerScreen extends StatefulWidget {
  const SyncManagerScreen({super.key});

  @override
  State<SyncManagerScreen> createState() => _SyncManagerScreenState();
}

class _SyncManagerScreenState extends State<SyncManagerScreen> with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  final Set<String> _togglingSourceIds = {};

  late TabController _tabController;
  bool _isLoading = true;
  bool _isTriggeringSync = false;
  bool _isWipingData = false;
  String? _error;
  List<ApiSourceDto> _sources = [];
  List<ApiSyncJobDto> _syncJobs = [];

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
      final sources = await _apiService.getApiSources();
      final jobs = await _apiService.getSyncJobs();
      setState(() {
        _sources = sources;
        _syncJobs = jobs;
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
    if (_togglingSourceIds.contains(source.id)) return;

    setState(() => _togglingSourceIds.add(source.id));
    try {
      final updated = await _apiService.toggleApiSource(source.id);
      final index = _sources.indexWhere((s) => s.id == source.id);
      if (index != -1) setState(() => _sources[index] = updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.isActive ? 'Enabled source ${updated.name}' : 'Disabled source ${updated.name}'),
          backgroundColor: updated.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change API source: $e'), backgroundColor: const Color(0xFFDC2626), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _togglingSourceIds.remove(source.id));
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isTriggeringSync = true);
    try {
      final success = await _apiService.triggerSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync request submitted. Job will run in the background.' : 'Could not trigger sync.'),
          backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) await _loadSyncData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error triggering sync: $e'), backgroundColor: const Color(0xFFDC2626), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isTriggeringSync = false);
    }
  }

  Future<void> _wipeData() async {
    final palette = AdminPalette(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(child: Text('Delete mock data?', style: GoogleFonts.inter(color: palette.text, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Text(
          'This action will delete all mock data and cannot be undone. Only proceed if you are sure this is not real data.',
          style: GoogleFonts.inter(color: palette.muted, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isWipingData = true);
    try {
      final success = await _apiService.wipeMockData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Mock data deleted' : 'Could not delete mock data'),
          backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) await _loadSyncData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting data: $e'), backgroundColor: const Color(0xFFDC2626), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isWipingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text('API Sync', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: palette.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.text),
        actions: [
          _actionButton(
            tooltip: 'Sync Now',
            icon: Icons.sync_rounded,
            color: const Color(0xFF22C55E),
            loading: _isTriggeringSync,
            onPressed: _triggerSync,
          ),
          _actionButton(
            tooltip: 'Delete mock data',
            icon: Icons.delete_sweep_rounded,
            color: const Color(0xFFEF4444),
            loading: _isWipingData,
            onPressed: _wipeData,
          ),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _loadSyncData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: palette.muted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'API Sources'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _loadSyncData)
              : Column(
                  children: [
                    if (_apiService.isUsingMock) const AdminInfoBanner(message: 'Could not connect to Admin API. Displaying mock data.'),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSourcesTab(palette),
                          _buildHistoryTab(palette),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton({required String tooltip, required IconData icon, required Color color, required bool loading, required VoidCallback onPressed}) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
      );
    }
    return IconButton(tooltip: tooltip, icon: Icon(icon, color: color), onPressed: onPressed);
  }

  Widget _buildSourcesTab(AdminPalette palette) {
    if (_sources.isEmpty) {
      return const AdminEmptyState(icon: Icons.hub_outlined, title: 'No API sources yet', message: 'Synchronization sources will appear when the backend returns data.');
    }

    final activeSources = _sources.where((s) => s.isActive).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        AdminSurface(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cloud_sync_outlined, color: Color(0xFF22C55E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$activeSources/${_sources.length} sources active', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: palette.text)),
                    const SizedBox(height: 3),
                    Text('Toggle data sources and check sync limits.', style: GoogleFonts.inter(fontSize: 13, color: palette.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._sources.map((source) => _sourceCard(source, palette)),
      ],
    );
  }

  Widget _statusIndicator(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
    );
  }

  Widget _sourceCard(ApiSourceDto source, AdminPalette palette) {
    final isToggling = _togglingSourceIds.contains(source.id);
    final color = source.isActive ? const Color(0xFF22C55E) : palette.muted;

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_queue_outlined, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(source.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: palette.text)),
                        const SizedBox(width: 8),
                        _statusIndicator(source.isActive),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(source.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: palette.muted)),
                  ],
                ),
              ),
              isToggling
                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                  : Switch(value: source.isActive, activeColor: AppTheme.primaryColor, onChanged: (_) => _toggleSource(source)),
            ],
          ),
          Divider(height: 24, color: palette.border),
          Row(
            children: [
              _detail('Limit', '${source.rateLimitPerSec}/sec', palette),
              _detail('Interval', '${source.syncIntervalHours} hours', palette),
              _detail('Last Synced', formatAdminDate(source.lastSyncedAt), palette),
            ],
          ),
          if (source.supportedFields.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Supported Fields', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: palette.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: source.supportedFields.map((field) => AdminStatusPill(label: field, color: AppTheme.primaryColor)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value, AdminPalette palette) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: palette.muted)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: palette.text)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AdminPalette palette) {
    if (_syncJobs.isEmpty) {
      return const AdminEmptyState(icon: Icons.history_outlined, title: 'No sync history yet', message: 'Sync jobs will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _syncJobs.length,
      itemBuilder: (context, index) => _jobCard(_syncJobs[index], palette),
    );
  }

  Widget _jobCard(ApiSyncJobDto job, AdminPalette palette) {
    final status = job.status.toLowerCase();
    final statusColor = status == 'success'
        ? const Color(0xFF22C55E)
        : status == 'failed'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final started = job.startedAt == null ? null : DateTime.tryParse(job.startedAt!)?.toLocal();
    final finished = job.finishedAt == null ? null : DateTime.tryParse(job.finishedAt!)?.toLocal();
    final duration = started != null && finished != null ? '${finished.difference(started).inSeconds} seconds' : 'Pending';

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminStatusPill(label: _statusText(job.status), color: statusColor),
              const SizedBox(width: 10),
              Expanded(child: Text(job.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: palette.text))),
              Text(formatAdminDate(job.startedAt), style: GoogleFonts.inter(fontSize: 11, color: palette.muted)),
            ],
          ),
          if (job.queryParams != null && job.queryParams!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(job.queryParams!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.firaCode(fontSize: 11, color: palette.muted)),
          ],
          Divider(height: 24, color: palette.border),
          Row(
            children: [
              _metric('Fetched', job.papersFetched.toString(), palette),
              _metric('Added', job.papersInserted.toString(), palette),
              _metric('Updated', job.papersUpdated.toString(), palette),
              _metric('Duration', duration, palette),
            ],
          ),
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(job.errorMessage!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, AdminPalette palette) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: palette.muted)),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: palette.text)),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Success';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}
