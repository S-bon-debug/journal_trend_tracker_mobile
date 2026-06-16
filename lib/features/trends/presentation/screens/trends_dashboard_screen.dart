import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
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
  Future<List<HotTopicDto>>? _hotTopicsFuture;
  Future<List<TopAuthorDto>>? _topAuthorsFuture;
  Future<List<JournalTrendSummaryDto>>? _topJournalsFuture;
  Future<List<TopKeywordDto>>? _topKeywordsFuture;

  // Trạng thái theo dõi biểu đồ
  Future<KeywordTrendDto>? _trendFuture;
  String? _selectedKeywordId;

  @override
  void initState() {
    super.initState();
    _repository = TrendRepository(dio: Dio());
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Trends Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Publication Trends'),
            const SizedBox(height: 16),
            _buildTrendChartSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Top 10 Keywords'),
            const SizedBox(height: 16),
            _buildTopKeywordsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Trending Research Topics'),
            const SizedBox(height: 16),
            _buildTrendingTopicsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Top Authors'),
            const SizedBox(height: 16),
            _buildTopAuthorsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Top Journals'),
            const SizedBox(height: 16),
            _buildTopJournalsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  Widget _buildOverviewSection() {
    return FutureBuilder<TrendOverviewDto>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error loading overview: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return Row(
            children: [
              Expanded(child: _buildStatCard('Total Papers', '${data.totalPapers}', Colors.blueAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total Authors', '${data.totalAuthors}', Colors.purpleAccent)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartSection() {
    return FutureBuilder<KeywordTrendDto>(
      key: ValueKey(_selectedKeywordId ?? 'default'),
      future: _trendFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return SizedBox(height: 300, child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
        } else if (snapshot.hasData) {
          final trend = snapshot.data!;
          if (trend.stats.isEmpty) {
            return const SizedBox(height: 300, child: Center(child: Text('No trend data available.', style: TextStyle(color: Colors.white))));
          }
          
          final spots = trend.stats.map((e) => FlSpot(e.year.toDouble(), e.paperCount.toDouble())).toList();
          
          return Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trend.keywordTerm, style: GoogleFonts.inter(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                          )
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                          )
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.purpleAccent,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: Colors.purpleAccent.withOpacity(0.2)),
                          dotData: const FlDotData(show: false),
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

  Widget _buildTopKeywordsSection() {
    return FutureBuilder<List<TopKeywordDto>>(
      future: _topKeywordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: snapshot.data!.map((keyword) {
                  final isSelected = _selectedKeywordId == keyword.keywordId;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.purpleAccent : Colors.grey[800],
                      foregroundColor: Colors.white,
                      elevation: isSelected ? 4 : 0,
                    ),
                    onPressed: () {
                      _onKeywordSelected(keyword.keywordId);
                    },
                    child: Text(keyword.keywordTerm),
                  );
                }).toList(),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTrendingTopicsSection() {
    return FutureBuilder<List<HotTopicDto>>(
      future: _hotTopicsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error loading topics: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        } else if (snapshot.hasData) {
          final topics = snapshot.data!;
          return Column(
            children: topics.map((topic) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.greenAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      topic.query,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Text('${topic.searchCount} searches', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
            )).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTopAuthorsSection() {
    return FutureBuilder<List<TopAuthorDto>>(
      future: _topAuthorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final author = snapshot.data![index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(author.name[0], style: const TextStyle(color: Colors.blueAccent)),
                      ),
                      const Spacer(),
                      Text(author.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${author.paperCount} papers', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
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

  Widget _buildTopJournalsSection() {
    return FutureBuilder<List<JournalTrendSummaryDto>>(
      future: _topJournalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return Column(
            children: snapshot.data!.map((journal) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, color: Colors.orangeAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      journal.journalName,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text('${journal.paperCount} papers', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
            )).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
