import 'package:flutter/material.dart';

class AuthDesktopPanel extends StatelessWidget {
  const AuthDesktopPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF080711), Color(0xFF140C29), Color(0xFF0F0B1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo + Name
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'TREND TRACKER',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Hero Title
              Text(
                'Discover where\nacademic research\nis heading next.',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -1,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analyze millions of publications, track rising keywords, and uncover hidden connections across scientific disciplines.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 50),

              // Trend Visual Card Mockup
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trending Research Topics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Live Data',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildTrendItem('Artificial Intelligence & LLMs', 0.85, const Color(0xFF8B5CF6), '+142%', isDark),
                    const SizedBox(height: 14),
                    _buildTrendItem('Quantum Machine Learning', 0.62, const Color(0xFF06B6D4), '+85%', isDark),
                    const SizedBox(height: 14),
                    _buildTrendItem('Biotechnology & Gene Editing', 0.48, const Color(0xFFEC4899), '+64%', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Tag cloud / quick stats
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag('#DeepLearning', isDark),
                  _buildTag('#CRISPR', isDark),
                  _buildTag('#QuantumComputing', isDark),
                  _buildTag('#NLP', isDark),
                  _buildTag('#ClimateTech', isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendItem(String name, double progress, Color color, String percent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            Text(percent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}
