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
          title: '[Giả lập] Bài báo mới được xuất bản',
          body: 'Một bài báo mới phù hợp với từ khóa bạn đang theo dõi "Machine Learning" đã được xuất bản: "Optimizing Neural Network Architectures via Evolutionary Algorithms".',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        ),
        NotificationDto(
          id: 'mock_2',
          type: 'sync',
          title: '[Giả lập] Đồng bộ dữ liệu thành công',
          body: 'Cơ sở dữ liệu xu hướng tạp chí khoa học đã được cập nhật thành công với 12 xu hướng mới được phân tích.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        ),
        NotificationDto(
          id: 'mock_3',
          type: 'default',
          title: '[Giả lập] Cập nhật thông tin hệ thống',
          body: 'Thông tin tùy chọn nghiên cứu ưu tiên của bạn đã được lưu lại thành công. Bạn sẽ nhận được các bài báo liên quan nhất.',
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

    // Show details dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                      item.title,
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
    IconData icon;
    Color color;
    switch (type) {
      case 'paper':
      case 'new_paper':
        icon = Icons.description;
        color = Colors.blueAccent;
        break;
      case 'sync':
        icon = Icons.sync_outlined;
        color = Colors.greenAccent;
        break;
      default:
        icon = Icons.notifications_none_outlined;
        color = Colors.orangeAccent;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
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
    const isDark = false; // Force light theme
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (!_isLoading && _error == null)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18, color: Colors.purpleAccent),
              label: Text('Mark all read', style: GoogleFonts.inter(color: Colors.purpleAccent, fontWeight: FontWeight.w600)),
              onPressed: _markAllAsRead,
            ),
        ],
      ),      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : _error != null
              ? Center(
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
                          textAlign: TextAlign.center
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No notifications found.',
                                        style: GoogleFonts.inter(
                                          color: isDark ? Colors.white38 : Colors.black38, 
                                          fontSize: 16
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
                                  
                                  const isDark = false; // Force light theme
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
                                                              item.title,
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
                ),
    );
  }

  Widget _buildFilterChip(String value) {
    final isSelected = _filter == value;
    const isDark = false; // Force light theme
    final chipBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
    final chipSelectedBg = Colors.purpleAccent.withOpacity(0.15);
    final labelColor = isSelected 
        ? Colors.purpleAccent 
        : (isDark ? Colors.white70 : Colors.black87);
    final chipBorder = isSelected 
        ? Colors.purpleAccent 
        : (isDark ? Colors.transparent : Colors.black.withOpacity(0.1));

    return ChoiceChip(
      label: Text(value),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      backgroundColor: chipBg,
      selectedColor: chipSelectedBg,
      labelStyle: GoogleFonts.inter(
        color: labelColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: chipBorder),
      ),
      showCheckmark: false,
    );
  }
}
