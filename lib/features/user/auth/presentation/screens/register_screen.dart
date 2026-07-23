import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/auth_api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApiService = AuthApiService();

  int _selectedRole = 2; // Default to Student (2)
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _authApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );

      if (res.accessToken.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Go back to login screen
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildRoleCard(int roleVal, String title, String desc, IconData icon) {
    final isSelected = _selectedRole == roleVal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : const Color(0xFF8B5CF6).withValues(alpha: 0.08);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final borderColor = isSelected 
        ? const Color(0xFF8B5CF6) 
        : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08));

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleVal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.white38 : Colors.black38),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final fieldBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final fieldBorder = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0B0B0E), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join academic research trend tracking system',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: subtextColor),
                    ),
                    const SizedBox(height: 28),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name
                    Container(
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: fieldBorder),
                      ),
                      child: TextFormField(
                        controller: _fullNameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: subtextColor, fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    Container(
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: fieldBorder),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: subtextColor, fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8B5CF6), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    Container(
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: fieldBorder),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: subtextColor, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: subtextColor,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selection Header
                    Text(
                      'Select your role',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 12),

                    // Role Cards row
                    Row(
                      children: [
                        _buildRoleCard(2, 'Student', 'Search papers', Icons.school_outlined),
                        const SizedBox(width: 12),
                        _buildRoleCard(1, 'Lecturer', 'Teaching & Res.', Icons.co_present_outlined),
                        const SizedBox(width: 12),
                        _buildRoleCard(3, 'Researcher', 'Publish papers', Icons.science_outlined),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                              : const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login navigation fallback
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: subtextColor, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ).createShader(bounds),
                            child: const Text(
                              'Login now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
