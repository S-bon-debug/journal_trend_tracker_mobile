import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme_manager.dart';
import '../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../user/profile/data/services/user_api_service.dart';
import '../../user/profile/data/models/user_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserApiService _apiService = UserApiService();
  final TextEditingController _devTokenController = TextEditingController();
  bool _isLoading = true;
  bool _isAdmin = false;
  String _name = 'User';
  String _email = '';
  String? _avatarUrl;
  String _language = 'English'; // English, Tiếng Việt

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    // Load language from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _language = prefs.getString('app_language') ?? 'English';
        _devTokenController.text = prefs.getString('dev_jwt_token') ?? '';
      });
    } catch (e) {
      debugPrint('Error loading language setting: $e');
    }

    // Load profile and verify admin role
    try {
      final profile = await _apiService.getProfile();
      try {
        final account = await _apiService.getAccountDetails(profile.userId);
        setState(() {
          _name = account.fullName;
          _email = account.email;
          _avatarUrl = account.avatarUrl;
          _isAdmin = (account.role == 3); // 3 corresponds to Admin in C# enum UserRole
        });
      } catch (innerError) {
        debugPrint('Failed to load identity details in settings: $innerError');
      }
    } catch (e) {
      debugPrint('Failed to load profile in settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeLanguage(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
      setState(() {
        _language = lang;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'English' ? 'Language changed to English' : 'Đã đổi ngôn ngữ sang Tiếng Việt',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.purpleAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save language setting: $e');
    }
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text(
          _language == 'English' ? 'Select Language' : 'Chọn ngôn ngữ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: GoogleFonts.inter()),
              trailing: _language == 'English' ? const Icon(Icons.check, color: Colors.purpleAccent) : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('English');
              },
            ),
            ListTile(
              title: Text('Tiếng Việt', style: GoogleFonts.inter()),
              trailing: _language == 'Tiếng Việt' ? const Icon(Icons.check, color: Colors.purpleAccent) : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('Tiếng Việt');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _devTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _language == 'English' ? 'App Settings' : 'Cài đặt ứng dụng',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Quick View Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.purpleAccent.withOpacity(0.15),
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? Text(
                                  _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purpleAccent),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                        if (_isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purpleAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admin Action Section
                  if (_isAdmin) ...[
                    Text(
                      _language == 'English' ? 'Administration' : 'Quản trị hệ thống',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.purpleAccent, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _language == 'English' ? 'Admin Dashboard' : 'Bảng điều khiển Admin',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _language == 'English'
                                            ? 'Manage users, API sync, and settings'
                                            : 'Quản lý thành viên, đồng bộ API & cấu hình',
                                        style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Developer Settings Section
                  Text(
                    _language == 'English' ? 'Developer Testing Settings' : 'Cấu hình kiểm thử (Developer)',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
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
                        Text(
                          _language == 'English'
                              ? 'Paste Admin JWT Access Token to test live backend APIs:'
                              : 'Dán Access Token JWT Admin để kiểm thử API live:',
                          style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _devTokenController,
                            maxLines: 3,
                            style: GoogleFonts.firaCode(fontSize: 11, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Bearer eyJhbGciOiJIUzI1Ni...',
                              hintStyle: TextStyle(color: subtitleColor.withOpacity(0.3)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.save, size: 16),
                                label: Text(_language == 'English' ? 'Save Token' : 'Lưu Token'),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('dev_jwt_token', _devTokenController.text.trim());
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã lưu Token kiểm thử! Hãy chuyển sang tab Admin để reload.', style: GoogleFonts.inter()),
                                        backgroundColor: Colors.greenAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.clear, size: 16),
                              label: Text(_language == 'English' ? 'Clear' : 'Xóa'),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('dev_jwt_token');
                                _devTokenController.clear();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã xóa Token kiểm thử.', style: GoogleFonts.inter()),
                                      backgroundColor: Colors.purpleAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings options
                  Text(
                    _language == 'English' ? 'General Settings' : 'Cài đặt chung',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // Dark Mode Toggle
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeManager.themeModeNotifier,
                          builder: (context, themeMode, _) {
                            final isCurrentDark = themeMode == ThemeMode.dark;
                            return ListTile(
                              leading: Icon(
                                isCurrentDark ? Icons.dark_mode : Icons.light_mode,
                                color: Colors.purpleAccent,
                              ),
                              title: Text(
                                _language == 'English' ? 'Dark Theme' : 'Chế độ tối',
                                style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500),
                              ),
                              trailing: Switch(
                                value: isCurrentDark,
                                activeColor: Colors.purpleAccent,
                                onChanged: (val) {
                                  ThemeManager.toggleTheme(val);
                                },
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        // Language Selector
                        ListTile(
                          leading: const Icon(Icons.language, color: Colors.purpleAccent),
                          title: Text(
                            _language == 'English' ? 'App Language' : 'Ngôn ngữ ứng dụng',
                            style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _language,
                                style: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios, size: 14, color: subtitleColor),
                            ],
                          ),
                          onTap: _showLanguageSelector,
                        ),
                        Divider(height: 1, color: borderColor),
                        // About App
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.purpleAccent),
                          title: Text(
                            _language == 'English' ? 'About Journal Trend Tracker' : 'Về ứng dụng',
                            style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subtitleColor),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Journal Trend Tracker',
                              applicationVersion: '1.0.0 (Production)',
                              applicationIcon: const Icon(Icons.trending_up, size: 48, color: Colors.purpleAccent),
                              children: [
                                Text(
                                  _language == 'English'
                                      ? 'A microservices-based academic research trend tracking system.'
                                      : 'Hệ thống theo dõi xu hướng nghiên cứu học thuật dựa trên kiến trúc microservices.',
                                  style: GoogleFonts.inter(fontSize: 14),
                                )
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        _language == 'English' ? 'Log Out' : 'Đăng xuất',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        // Confirm logout
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            title: Text(
                              _language == 'English' ? 'Confirm Log Out' : 'Xác nhận Đăng xuất',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              _language == 'English'
                                  ? 'Are you sure you want to sign out?'
                                  : 'Bạn có chắc chắn muốn đăng xuất tài khoản?',
                              style: GoogleFonts.inter(),
                            ),
                            actions: [
                              TextButton(
                                child: Text(_language == 'English' ? 'Cancel' : 'Hủy bỏ',
                                    style: GoogleFonts.inter(color: subtitleColor)),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: Text(_language == 'English' ? 'Log Out' : 'Đăng xuất',
                                    style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Pop SettingsScreen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _language == 'English' ? 'Logged out successfully (Mock)' : 'Đăng xuất thành công (Mô phỏng)',
                                        style: GoogleFonts.inter(),
                                      ),
                                      backgroundColor: Colors.purpleAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
