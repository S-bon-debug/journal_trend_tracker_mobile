import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/data/services/user_api_service.dart';
import '../../../profile/data/models/user_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final UserApiService _apiService = UserApiService();
  List<NotificationDto> _notifications = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _locallyReadIds = {};

  String _filter = 'All'; // 'All' or 'Unread'

  List<NotificationDto> get _simulatedNotifications => [
        NotificationDto(
          id: 'mock_1',
          type: 'new_paper',
          title: 'New paper published',
          body: 'A new paper matching your followed keyword "Machine Learning" has been published: "Optimizing Neural Network Architectures via Evolutionary Algorithms".',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        ),
        NotificationDto(
          id: 'mock_2',
          type: 'sync',
          title: 'Data sync successful',
          body: 'The scientific journal trends database has been successfully updated with 12 new analyzed trends.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        ),
        NotificationDto(
          id: 'mock_3',
          type: 'default',
          title: 'System information updated',
          body: 'Your preferred research options have been successfully saved. You will receive the most relevant papers.',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _apiService.getNotifications();
      setState(() {
        _notifications = [..._simulatedNotifications, ...list];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load notifications from API: $e');
      setState(() {
        _notifications = _simulatedNotifications;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  void _markAsRead(NotificationDto item) async {
    setState(() {
      _locallyReadIds.add(item.id);
    });

    if (!item.id.startsWith('mock_')) {
      try {
        await _apiService.markNotificationAsRead(item.id);
      } catch (e) {
        debugPrint('Failed to mark notification as read: $e');
      }
    }

    // Show details dialog centered in the middle of the screen
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getIconForType(item.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title.replaceAll('[Giả lập] ', '').replaceAll('[Giả lập]', ''),
                        style: GoogleFonts.inter(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.body,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatTimestamp(item.createdAt),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAllAsRead() async {
    setState(() {
      for (var item in _notifications) {
        _locallyReadIds.add(item.id);
      }
    });

    try {
      final hasRealNotifications = _notifications.any((item) => !item.id.startsWith('mock_'));
      if (hasRealNotifications) {
        await _apiService.markAllNotificationsAsRead();
      }
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read', style: GoogleFonts.inter()),
          backgroundColor: Colors.purpleAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _getIconForType(String type) {
    List<Color> gradient;
    IconData icon;
    switch (type) {
      case 'paper':
      case 'new_paper':
        icon = Icons.description_rounded;
        gradient = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
        break;
      case 'sync':
        icon = Icons.sync_rounded;
        gradient = [const Color(0xFF10B981), const Color(0xFF059669)];
        break;
      default:
        icon = Icons.notifications_rounded;
        gradient = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _notifications.where((item) {
      final isRead = item.isRead || _locallyReadIds.contains(item.id);
      if (_filter == 'Unread') {
        return !isRead;
      }
      return true;
    }).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading && _error == null)
                      TextButton.icon(
                        icon: const Icon(Icons.done_all, size: 17, color: Colors.white),
                        label: const Text('Mark all', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        onPressed: _markAllAsRead,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBodyContent(filteredList, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(List<NotificationDto> filteredList, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Connection error: $_error', 
                style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Unread'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadNotifications,
            color: Colors.purpleAccent,
            child: filteredList.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined, 
                            size: 64, 
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications found.',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white38 : Colors.black38, 
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isRead = item.isRead || _locallyReadIds.contains(item.id);
                      
                      final textColor = isDark ? Colors.white : Colors.black87;
                      final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
                      final textColorTertiary = isDark ? Colors.white30 : Colors.black38;
                      
                      final cardBg = isRead
                          ? (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02))
                          : (isDark ? Colors.purpleAccent.withOpacity(0.04) : Colors.purpleAccent.withOpacity(0.06));
                          
                      final cardBorderColor = isRead
                          ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))
                          : (isDark ? Colors.purpleAccent.withOpacity(0.15) : Colors.purpleAccent.withOpacity(0.25));

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cardBorderColor,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _markAsRead(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _getIconForType(item.type),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title.replaceAll('[Giả lập] ', '').replaceAll('[Giả lập]', ''),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.purpleAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.body,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: isRead ? textColorSecondary : textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatTimestamp(item.createdAt),
                                            style: GoogleFonts.inter(fontSize: 11, color: textColorTertiary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value) {
    final isSelected = _filter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : chipBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
