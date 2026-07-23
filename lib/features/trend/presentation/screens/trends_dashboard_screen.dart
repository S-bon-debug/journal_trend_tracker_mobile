import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/trend_models.dart';
import '../../data/repositories/trend_repository.dart';

class TrendsDashboardScreen extends StatefulWidget {
  const TrendsDashboardScreen({super.key});

  @override
  State<TrendsDashboardScreen> createState() => _TrendsDashboardScreenState();
}

class _TrendsDashboardScreenState extends State<TrendsDashboardScreen> {
  late TrendRepository _repository;
  
  Future<TrendOverviewDto>? _overviewFuture;
  Future<List<TopTopicDto>>? _hotTopicsFuture;
  Future<List<TopAuthorDto>>? _topAuthorsFuture;
  Future<List<JournalTrendSummaryDto>>? _topJournalsFuture;
  Future<List<TopKeywordDto>>? _topKeywordsFuture;

  Future<KeywordTrendDto>? _trendFuture;
  String? _selectedKeywordId;

  @override
  void initState() {
    super.initState();
    _repository = TrendRepository(dio: DioClient.dio);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _overviewFuture = _repository.getOverview();
      _hotTopicsFuture = _repository.getHotTopics();
      _topAuthorsFuture = _repository.getTopAuthors();
      _topJournalsFuture = _repository.getTopJournals();
      _topKeywordsFuture = _repository.getTopKeywords();
    });

    try {
      final keywords = await _topKeywordsFuture!;
      if (keywords.isNotEmpty && mounted) {
        setState(() {
          _selectedKeywordId ??= keywords.first.keywordId;
          _trendFuture = _repository.getKeywordTrend(_selectedKeywordId!);
        });
      }
    } catch (e) {
      // Ignored for now
    }
  }

  void _onKeywordSelected(String keywordId) {
    setState(() {
      _selectedKeywordId = keywordId;
      _trendFuture = _repository.getKeywordTrend(keywordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isDark = false; // Force light theme
    final textColor = isDark ? Colors.white : Colors.black87;
    
    // Background gradient for a modern feel
    final bgGradient = LinearGradient(
      colors: isDark 
        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
        : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Analytics Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: (isDark ? Colors.black : Colors.white).withOpacity(0.5)),
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: textColor),
            onPressed: () => context.push('/export'),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _loadInitialData,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Publication Trend Analysis', Icons.insights_rounded),
                    const SizedBox(height: 16),
                    _buildTrendChartSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Trending Research Topics', Icons.local_fire_department_rounded, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    _buildTrendingTopicsSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Top 10 Keywords', Icons.tag_rounded),
                    const SizedBox(height: 16),
                    _buildTopKeywordsSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Leading Authors', Icons.school_rounded),
                    const SizedBox(height: 16),
                    _buildTopAuthorsSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Top Journals', Icons.menu_book_rounded),
                    const SizedBox(height: 16),
                    _buildTopJournalsSection(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    const isDark = false; // Force light theme
    return Row(
      children: [
        Icon(icon, size: 22, color: color ?? (isDark ? Colors.blueAccent : Colors.blue)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
        ),
      ],
    );
  }

  // --- OVERVIEW SECTION ---
  Widget _buildOverviewSection() {
    return FutureBuilder<TrendOverviewDto>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 2.0 : 1.5,
                children: [
                  _buildStatCard('Total Papers', '${data.totalPapers}', Icons.article_rounded, const [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  _buildStatCard('Authors', '${data.totalAuthors}', Icons.people_rounded, const [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  _buildStatCard('Keywords', '${data.totalKeywords}', Icons.tag_rounded, const [Color(0xFF10B981), Color(0xFF059669)]),
                  _buildStatCard('Journals', '${data.totalJournals}', Icons.menu_book_rounded, const [Color(0xFFF59E0B), Color(0xFFD97706)]),
                ],
              );
            }
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradientColors[1].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // --- CHART SECTION ---
  Widget _buildTrendChartSection() {
    return FutureBuilder<KeywordTrendDto>(
      key: ValueKey(_selectedKeywordId ?? 'default'),
      future: _trendFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          final trend = snapshot.data!;
          if (trend.stats.isEmpty) {
            return const SizedBox(height: 320, child: Center(child: Text('No data')));
          }
          
          final List<FlSpot> actualSpots = [];
          final List<FlSpot> forecastSpots = [];
          for (int i = 0; i < trend.stats.length; i++) {
            final stat = trend.stats[i];
            actualSpots.add(FlSpot(stat.year.toDouble(), stat.paperCount.toDouble()));
            if (i == trend.stats.length - 1 && stat.forecastPaperCount != null) {
              forecastSpots.add(FlSpot(stat.year.toDouble(), stat.paperCount.toDouble()));
              forecastSpots.add(FlSpot(stat.year.toDouble() + 1, stat.forecastPaperCount!.toDouble()));
            }
          }
          const isDark = false; // Force light theme
          final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
          final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
          
          return Container(
            height: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trend.keywordTerm, style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('Keyword Trend', style: GoogleFonts.inter(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)))),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)))),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: actualSpots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent.withOpacity(0.5), Colors.blueAccent.withOpacity(0.0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        if (forecastSpots.isNotEmpty)
                          LineChartBarData(
                            spots: forecastSpots,
                            isCurved: false,
                            color: Colors.orangeAccent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dashArray: [8, 4],
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => 
                                FlDotCirclePainter(radius: 4, color: Colors.orangeAccent, strokeWidth: 2, strokeColor: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- TRENDING TOPICS ---
  Widget _buildTrendingTopicsSection() {
    return FutureBuilder<List<TopTopicDto>>(
      future: _hotTopicsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final topics = snapshot.data!;
          return Column(
            children: topics.map((topic) {
              const isDark = false; // Force light theme
              final growth = topic.growthRate ?? 0.0;
              final isPositive = growth >= 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isPositive ? Colors.green : Colors.red, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.topicName, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${topic.paperCount} recent publications', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (topic.trendStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: topic.trendStatus!.contains('Hot') ? Colors.redAccent.withOpacity(0.15) 
                                   : (topic.trendStatus!.contains('Stable') ? Colors.blueAccent.withOpacity(0.15) 
                                   : Colors.grey.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              topic.trendStatus!,
                              style: GoogleFonts.inter(
                                color: topic.trendStatus!.contains('Hot') ? Colors.redAccent 
                                     : (topic.trendStatus!.contains('Stable') ? Colors.blueAccent : Colors.grey),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(color: isPositive ? Colors.green : Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text('Growth', style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- KEYWORDS ---
  Widget _buildTopKeywordsSection() {
    return FutureBuilder<List<TopKeywordDto>>(
      future: _topKeywordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: snapshot.data!.map((keyword) {
              final isSelected = _selectedKeywordId == keyword.keywordId;
              const isDark = false; // Force light theme
              return InkWell(
                onTap: () => _onKeywordSelected(keyword.keywordId),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.white24 : Colors.black12)),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        keyword.keywordTerm,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (keyword.trendStatus != null && keyword.trendStatus!.contains('Hot')) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 14),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- AUTHORS ---
  Widget _buildTopAuthorsSection() {
    return FutureBuilder<List<TopAuthorDto>>(
      future: _topAuthorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final author = snapshot.data![index];
                const isDark = false; // Force light theme
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16, bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                        child: Text(author.name[0], style: GoogleFonts.inter(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Text(author.name, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${author.paperCount} Publications', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- JOURNALS ---
  Widget _buildTopJournalsSection() {
    return FutureBuilder<List<JournalTrendSummaryDto>>(
      future: _topJournalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final journal = snapshot.data![index];
                const isDark = false; // Force light theme
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 16, bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.library_books_rounded, color: Colors.orangeAccent.withOpacity(0.8), size: 28),
                      Text(journal.journalName, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Year: ${journal.year}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                          Text('${journal.paperCount} Papers', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
