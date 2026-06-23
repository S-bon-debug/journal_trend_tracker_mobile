import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'bookmarks_screen.dart';
import '../../data/services/user_api_service.dart';
import '../../data/models/user_models.dart';
import '../../../../settings/presentation/screens/settings_screen.dart';

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
      case 1:
        return 'Lecturer';
      case 2:
        return 'Student';
      case 3:
        return 'Researcher';
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
        setState(() {
          _name = account.fullName;
          _email = account.email;
          _role = _mapRoleToString(account.role);
          _nameController.text = _name;
          if (account.avatarUrl != null && account.avatarUrl!.isNotEmpty) {
            _customAvatarUrl = account.avatarUrl;
          }
        });
      } catch (innerError) {
        // Fallback gracefully if Identity service lookup fails
        debugPrint('Failed to load identity account details: $innerError');
      }

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

    // Simulate API call to update profile
    await Future.delayed(const Duration(seconds: 1));

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'My Profile', 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.purpleAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ).then((_) {
                  // Reload profile on return to check if anything updated (e.g. role change)
                  _loadProfileData();
                });
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
                          'Lỗi tải thông tin hồ sơ',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadProfileData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
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
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _customAvatarUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
                  'Cập nhật ảnh đại diện',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
                  title: Text('Chọn từ thư viện điện thoại', style: GoogleFonts.inter(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle, color: Colors.purpleAccent),
                  title: Text('Sử dụng Avatar mặc định', style: GoogleFonts.inter(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    setState(() {
                      _customAvatarUrl = null;
                      _pickedImage = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Text(
                  'Gợi ý ảnh đại diện nhanh (Mô phỏng)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
                            border: Border.all(color: Colors.white24),
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
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _showAvatarPicker : null,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purpleAccent, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFF1E1E1E),
                    backgroundImage: _pickedImage != null
                        ? (kIsWeb
                            ? NetworkImage(_pickedImage!.path)
                            : FileImage(File(_pickedImage!.path)) as ImageProvider)
                        : (_customAvatarUrl != null
                            ? NetworkImage(_customAvatarUrl!)
                            : null),
                    child: _pickedImage == null && _customAvatarUrl == null
                        ? Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0] : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.purpleAccent,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
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
                style: GoogleFonts.inter(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter name',
                  hintStyle: TextStyle(color: Colors.white24),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
            )
          else
            Text(
              _name,
              style: GoogleFonts.inter(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
          const SizedBox(height: 6),
          Text(
            _email,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
            ),
            child: Text(
              _role,
              style: GoogleFonts.inter(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: Colors.purpleAccent
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookmarksScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatItem(Icons.bookmark, '$_bookmarkCount', 'Bookmarks'),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white10,
                ),
                _buildStatItem(Icons.star, '$_followCount', 'Followed Topics'),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withOpacity(0.3)),
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
          Icon(icon, color: Colors.purpleAccent, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: Colors.white70
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.purpleAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              icon: Icon(icon, color: enabled ? Colors.purpleAccent : Colors.white30, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResearchInterestsSection() {
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
                color: Colors.white70
              ),
            ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 22),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: Text('Add Interest', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: TextField(
                        controller: _interestController,
                        autofocus: true,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. Computer Vision',
                          hintStyle: GoogleFonts.inter(color: Colors.white24),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                        ),
                        onSubmitted: (val) {
                          _addInterest();
                          Navigator.pop(context);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
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
              backgroundColor: Colors.white.withOpacity(0.04),
              labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
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
