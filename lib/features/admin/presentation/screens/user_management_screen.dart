import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/admin_api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<AdminUserDto> _allUsers = [];
  List<AdminUserDto> _filteredUsers = [];

  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  int _selectedRoleFilter = -1; // -1 means All roles
  int _selectedStatusFilter = -1; // -1 means All statuses

  // Tracks which user IDs are currently toggling status (loading state)
  final Set<String> _togglingUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usersList = await _apiService.getUsers();
      setState(() {
        _allUsers = usersList;
        _applyFiltersAndSearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSearch() {
    _filteredUsers = _allUsers.where((user) {
      // 1. Search Query Match
      final query = _searchQuery.toLowerCase();
      final nameMatches = user.fullName.toLowerCase().contains(query);
      final emailMatches = user.email.toLowerCase().contains(query);
      final idMatches = user.id.toLowerCase().contains(query);
      final matchesSearch = nameMatches || emailMatches || idMatches;

      // 2. Role Filter Match
      final matchesRole = _selectedRoleFilter == -1 || user.role == _selectedRoleFilter;

      // 3. Status Filter Match
      final matchesStatus = _selectedStatusFilter == -1 || user.status == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _toggleUserStatus(AdminUserDto user) async {
    final userId = user.id;
    if (_togglingUserIds.contains(userId)) return;

    setState(() {
      _togglingUserIds.add(userId);
    });

    try {
      final success = await _apiService.toggleUserStatus(userId);
      if (success) {
        // Find user index and update status locally
        final userIndex = _allUsers.indexWhere((u) => u.id == userId);
        if (userIndex != -1) {
          final currentUser = _allUsers[userIndex];
          // In C# UserStatus enum: active=0, locked=1, pending=2
          final nextStatus = currentUser.status == 0 ? 1 : 0;
          
          setState(() {
            _allUsers[userIndex] = AdminUserDto(
              id: currentUser.id,
              fullName: currentUser.fullName,
              email: currentUser.email,
              avatarUrl: currentUser.avatarUrl,
              provider: currentUser.provider,
              role: currentUser.role,
              status: nextStatus,
              lastLoginAt: currentUser.lastLoginAt,
              createdAt: currentUser.createdAt,
              updatedAt: DateTime.now().toIso8601String(),
            );
            _applyFiltersAndSearch();
          });

          if (mounted) {
            final nextStatusString = nextStatus == 0 ? 'Mở khóa' : 'Khóa';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$nextStatusString tài khoản ${currentUser.fullName} thành công!', style: GoogleFonts.inter()),
                backgroundColor: nextStatus == 0 ? Colors.greenAccent : Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thay đổi trạng thái: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingUserIds.remove(userId);
        });
      }
    }
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
          'User Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
                        Text('Lỗi tải danh sách người dùng', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: subtitleColor)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('Thử lại'),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Search and filters bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Search Input
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: TextField(
                              style: GoogleFonts.inter(color: textColor),
                              decoration: InputDecoration(
                                icon: Icon(Icons.search, color: subtitleColor, size: 20),
                                hintText: 'Tìm kiếm theo tên, email, uuid...',
                                hintStyle: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                  _applyFiltersAndSearch();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filter Selectors Row
                          Row(
                            children: [
                              // Role filter
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedRoleFilter,
                                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      style: GoogleFonts.inter(color: textColor, fontSize: 13),
                                      icon: Icon(Icons.arrow_drop_down, color: subtitleColor),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedRoleFilter = val ?? -1;
                                          _applyFiltersAndSearch();
                                        });
                                      },
                                      items: const [
                                        DropdownMenuItem(value: -1, child: Text('All Roles')),
                                        DropdownMenuItem(value: 0, child: Text('Researcher')),
                                        DropdownMenuItem(value: 1, child: Text('Lecturer')),
                                        DropdownMenuItem(value: 2, child: Text('Student')),
                                        DropdownMenuItem(value: 3, child: Text('Admin')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Status filter
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedStatusFilter,
                                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      style: GoogleFonts.inter(color: textColor, fontSize: 13),
                                      icon: Icon(Icons.arrow_drop_down, color: subtitleColor),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedStatusFilter = val ?? -1;
                                          _applyFiltersAndSearch();
                                        });
                                      },
                                      items: const [
                                        DropdownMenuItem(value: -1, child: Text('All Statuses')),
                                        DropdownMenuItem(value: 0, child: Text('Active')),
                                        DropdownMenuItem(value: 1, child: Text('Locked')),
                                        DropdownMenuItem(value: 2, child: Text('Pending')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // User List
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                'Không tìm thấy người dùng phù hợp.',
                                style: GoogleFonts.inter(color: subtitleColor),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isToggling = _togglingUserIds.contains(user.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      // Circle Avatar with initials
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: _getRoleColor(user.role).withOpacity(0.15),
                                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                        child: user.avatarUrl == null
                                            ? Text(
                                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  color: _getRoleColor(user.role),
                                                  fontSize: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      // User Info Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.fullName,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              user.email,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: subtitleColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),

                                            // Badges Row
                                            Row(
                                              children: [
                                                // Role badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getRoleColor(user.role).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    user.roleString,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getRoleColor(user.role),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Status badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(user.status).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    user.statusString,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getStatusColor(user.status),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Actions Panel (Lock / Unlock Switch)
                                      isToggling
                                          ? const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.purpleAccent,
                                              ),
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    // In C# UserStatus enum: active=0, locked=1
                                                    user.status == 0 ? Icons.lock_open : Icons.lock,
                                                    color: user.status == 0 ? Colors.greenAccent : Colors.redAccent,
                                                  ),
                                                  tooltip: user.status == 0 ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                                                  onPressed: () => _toggleUserStatus(user),
                                                ),
                                                Text(
                                                  user.status == 0 ? 'Lock' : 'Unlock',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: user.status == 0 ? Colors.greenAccent : Colors.redAccent,
                                                  ),
                                                )
                                              ],
                                            ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Color _getRoleColor(int role) {
    switch (role) {
      case 3: // Admin
        return Colors.purpleAccent;
      case 1: // Lecturer
        return Colors.blueAccent;
      case 0: // Researcher
        return Colors.greenAccent;
      case 2: // Student
      default:
        return Colors.orangeAccent;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: // Active
        return Colors.greenAccent;
      case 1: // Locked
        return Colors.redAccent;
      case 2: // Pending
      default:
        return Colors.amberAccent;
    }
  }
}
