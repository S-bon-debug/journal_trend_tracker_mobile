import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'bookmarks_screen.dart';
import '../../data/services/user_api_service.dart';

import '../../../auth/data/services/auth_api_service.dart';
import '../../../../../core/theme_manager.dart';
import '../../../../admin/presentation/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  String? _customAvatarUrl;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final UserApiService _apiService = UserApiService();
  bool _isLoading = true;
  String? _error;

  // Profile data
  String _name = 'Dr. Alexander Vance';
  String _email = 'alexander.vance@university.edu';
  String _role = 'Senior Researcher';
  String _bio = '';
  String _institution = '';
  String _websiteUrl = '';
  List<String> _interests = [];

  int _bookmarkCount = 0;
  int _followCount = 0;

  // Settings state
  bool _isAdmin = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _institutionController;
  late TextEditingController _websiteController;
  final TextEditingController _interestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _bioController = TextEditingController();
    _institutionController = TextEditingController();
    _websiteController = TextEditingController();
    _loadProfileData();
  }

  String _mapRoleToString(int role) {
    switch (role) {
      case 0:
        return 'Researcher';
      case 1:
        return 'Lecturer';
      case 2:
        return 'Student';
      case 3:
        return 'Admin';
      default:
        return 'User';
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _apiService.getProfile();
      final bookmarks = await _apiService.getBookmarks();
      final follows = await _apiService.getFollows();

      if (!mounted) return;
      setState(() {
        _bio = profile.bio ?? '';
        _institution = profile.institution ?? '';
        _websiteUrl = profile.websiteUrl ?? '';
        _interests = List.from(profile.researchFields);
        _bookmarkCount = bookmarks.length;
        _followCount = follows.length;

        _bioController.text = _bio;
        _institutionController.text = _institution;
        _websiteController.text = _websiteUrl;
      });

      // Fetch Identity Account details (Cross-service call)
      try {
        final account = await _apiService.getAccountDetails(profile.userId);
        if (!mounted) return;
        setState(() {
          _name = account.fullName;
          _email = account.email;
          _role = _mapRoleToString(account.role);
          _isAdmin = (account.role == 3);
          _nameController.text = _name;
          if (account.avatarUrl != null && account.avatarUrl!.isNotEmpty) {
            _customAvatarUrl = account.avatarUrl;
          }
        });
      } catch (innerError) {
        // Fallback gracefully if Identity service lookup fails
        debugPrint('Failed to load identity account details: $innerError');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _websiteController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _apiService.updateProfile(
        fullName: _nameController.text,
        email: null,
        bio: _bioController.text,
        institution: _institutionController.text,
        researchFields: _interests,
        websiteUrl: _websiteController.text,
      );

      if (!mounted) return;
      setState(() {
        _name = _nameController.text;
        _bio = _bioController.text;
        _institution = _institutionController.text;
        _websiteUrl = _websiteController.text;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: GoogleFonts.inter()),
            backgroundColor: Colors.purpleAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addInterest() {
    final text = _interestController.text.trim();
    if (text.isNotEmpty && !_interests.contains(text)) {
      setState(() {
        _interests.add(text);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'My Profile', 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (!_isEditing && !_isLoading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    title: Text('Log out', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold)),
                    content: Text('Are you sure you want to log out of the application?', style: GoogleFonts.inter(color: textColorSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: GoogleFonts.inter(color: textColorSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Log out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthApiService().logout();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.purpleAccent),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else if (_isEditing)
            _isSaving 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent))),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: Colors.greenAccent),
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load profile',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: textColorSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadProfileData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  color: Colors.purpleAccent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 24),
                        _buildQuickStatsCard(),
                        const SizedBox(height: 24),
                        _buildFormSection(),
                        const SizedBox(height: 24),
                        _buildResearchInterestsSection(),
                        const SizedBox(height: 32),
                        // --- Settings Section ---
                        if (!_isEditing) ...[
                          if (_isAdmin) ...[
                            _buildSectionLabel('System Administration'),
                            const SizedBox(height: 8),
                            _buildAdminCard(),
                            const SizedBox(height: 24),
                          ],
                          _buildSectionLabel('General Settings'),
                          const SizedBox(height: 8),
                          _buildGeneralSettingsCard(),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Settings Widgets ────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
    );
  }

  Widget _buildAdminCard() {
    return Container(
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
                        'Admin Dashboard',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage members, sync API & configuration',
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
    );
  }

  Widget _buildGeneralSettingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    Widget _iconBg({required List<Color> colors, required IconData icon}) {
      return Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
                leading: _iconBg(
                  colors: isCurrentDark
                      ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  icon: isCurrentDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                ),
                title: Text('Dark Mode', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
                trailing: Switch.adaptive(
                  value: isCurrentDark,
                  activeColor: const Color(0xFF8B5CF6),
                  onChanged: (val) => ThemeManager.toggleTheme(val),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
          // Help & Support
          ListTile(
            leading: _iconBg(
              colors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
              icon: Icons.help_outline_rounded,
            ),
            title: Text('Help & Support', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subtitleColor),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('If you have any questions or need technical support, please contact:', style: GoogleFonts.inter(color: subtitleColor)),
                      const SizedBox(height: 16),
                      Row(children: [const Icon(Icons.email, size: 18, color: Color(0xFF8B5CF6)), const SizedBox(width: 8), Text('support@trendtracker.com', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500))]),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.phone, size: 18, color: Color(0xFF8B5CF6)), const SizedBox(width: 8), Text('+84 123 456 789', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500))]),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
          // About App
          ListTile(
            leading: _iconBg(
              colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              icon: Icons.info_outline_rounded,
            ),
            title: Text('About Journal Trend Tracker', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subtitleColor),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Journal Trend Tracker',
                applicationVersion: '1.0.0 (Production)',
                applicationIcon: const Icon(Icons.trending_up_rounded, size: 48, color: Color(0xFF8B5CF6)),
                children: [Text('Academic research trend tracking system based on microservices architecture.', style: GoogleFonts.inter(fontSize: 14))],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Profile Widgets ──────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        if (!mounted) return;
        setState(() {
          _pickedImage = image;
          _customAvatarUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final List<String> mockGalleryImages = [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Profile Picture',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
                  title: Text('Choose from photo gallery', style: GoogleFonts.inter(color: textColor, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle, color: Colors.purpleAccent),
                  title: Text('Use default avatar', style: GoogleFonts.inter(color: textColor, fontSize: 15)),
                  onTap: () {
                    setState(() {
                      _customAvatarUrl = null;
                      _pickedImage = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                Divider(color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 10),
                Text(
                  'Quick Avatar Suggestions (Mock)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColorSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mockGalleryImages.length,
                    itemBuilder: (context, index) {
                      final url = mockGalleryImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _customAvatarUrl = url;
                            _pickedImage = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
    final textColorTertiary = isDark ? Colors.white54 : Colors.black45;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _showAvatarPicker : null,
            child: Stack(
              children: [
                // Outer glow ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFEC4899),
                        Color(0xFFEF4444),
                        Color(0xFFF97316),
                        Color(0xFFFBBF24),
                        Color(0xFF10B981),
                        Color(0xFF6366F1),
                        Color(0xFFEC4899),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0B0B0E) : Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                      backgroundImage: _pickedImage != null
                          ? (kIsWeb
                              ? NetworkImage(_pickedImage!.path)
                              : FileImage(File(_pickedImage!.path)) as ImageProvider)
                          : (_customAvatarUrl != null
                              ? NetworkImage(_customAvatarUrl!)
                              : null),
                      child: _pickedImage == null && _customAvatarUrl == null
                          ? ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ).createShader(bounds),
                              child: Text(
                                _nameController.text.isNotEmpty ? _nameController.text[0] : 'U',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            SizedBox(
              width: 250,
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  hintStyle: TextStyle(color: textColorTertiary),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardBorderColor)),
                  filled: false,
                ),
              ),
            )
          else
            Text(_name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 6),
          Text(_email, style: GoogleFonts.inter(fontSize: 14, color: textColorSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              _role,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookmarksScreen()),
            ).then((_) => _loadProfileData());
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                _buildStatItem(Icons.bookmark_rounded, '$_bookmarkCount', 'Bookmarks'),
                Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.3)),
                _buildStatItem(Icons.star_rounded, '$_followCount', 'Followed Topics'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 26),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Institution / Organization',
          controller: _institutionController,
          icon: Icons.business,
          enabled: _isEditing,
          maxLines: 1,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Personal Bio',
          controller: _bioController,
          icon: Icons.description,
          enabled: _isEditing,
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Website URL',
          controller: _websiteController,
          icon: Icons.link,
          enabled: _isEditing,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    required int maxLines,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
    final inputBg = enabled 
        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)) 
        : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01));
    final inputBorder = enabled 
        ? Colors.purpleAccent.withOpacity(0.3) 
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: textColorSecondary
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: inputBorder
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              icon: Icon(icon, color: enabled ? Colors.purpleAccent : (isDark ? Colors.white30 : Colors.black38), size: 20),
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResearchInterestsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
    final cardBorderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Research Interests',
              style: GoogleFonts.inter(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: textColorSecondary
              ),
            ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 22),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      title: Text('Add Interest', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold)),
                      content: TextField(
                        controller: _interestController,
                        autofocus: true,
                        style: GoogleFonts.inter(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'e.g. Computer Vision',
                          hintStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                          filled: false,
                        ),
                        onSubmitted: (val) {
                          _addInterest();
                          Navigator.pop(context);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.inter(color: textColorSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            _addInterest();
                            Navigator.pop(context);
                          },
                          child: Text('Add', style: GoogleFonts.inter(color: Colors.purpleAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _interests.map((interest) {
            return Chip(
              label: Text(interest),
              backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
              labelStyle: GoogleFonts.inter(color: textColor, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cardBorderColor),
              ),
              deleteIcon: _isEditing ? const Icon(Icons.cancel, size: 16, color: Colors.redAccent) : null,
              onDeleted: _isEditing ? () => _removeInterest(interest) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
