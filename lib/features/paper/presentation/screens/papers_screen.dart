import 'package:flutter/material.dart';
import '../../data/services/paper_api_service.dart';
import '../../data/models/gap_matrix_response_dto.dart';
import '../../data/models/paper_summary_dto.dart';
import '../../data/models/paper_filter_dto.dart';
import 'paper_detail_screen.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

// Temporary variable to preserve the idea input across tab switches
String _globalIdeaText = '';

class PapersScreen extends StatefulWidget {
  final String? initialKeyword;
  final String? initialJournalId;

  const PapersScreen({
    Key? key,
    this.initialKeyword,
    this.initialJournalId,
  }) : super(key: key);

  @override
  _PapersScreenState createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  final PaperApiService _apiService = PaperApiService();
  final TextEditingController _ideaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _error;
  GapMatrixResponseDto? _result;
  
  List<PaperSummaryDto> _trendingPapers = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null) {
      _ideaController.text = widget.initialKeyword!;
    } else {
      _ideaController.text = _globalIdeaText;
    }
    
    _ideaController.addListener(() {
      _globalIdeaText = _ideaController.text;
    });
    
    _loadTrendingPapers();
  }

  Future<void> _loadTrendingPapers() async {
    try {
      final result = await _apiService.searchPapers(
        PaperFilterDto(page: 1, pageSize: 5)
      );
      if (mounted) {
        setState(() {
          _trendingPapers = result.items;
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
      }
    }
  }

  Future<void> _analyzeIdea() async {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your research idea')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _apiService.generateGapMatrix(idea);
      setState(() {
        _result = result;
        _isLoading = false;
      });
      
      // Scroll to result after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            300, 
            duration: const Duration(milliseconds: 500), 
            curve: Curves.easeOut,
          );
        }
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
    _ideaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_result == null && !_isLoading && _error == null)
                        _buildSuggestionsBox(),
                      _buildIdeaInputBox(),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        _buildLoadingIndicator()
                      else if (_error != null)
                        _buildErrorBox()
                      else if (_result != null)
                        _buildResultSection()
                      else
                        _buildTrendingPapersBox(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF16161E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D1E);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      color: headerBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hybrid AI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Research Gap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.auto_awesome, color: Colors.amber[600], size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaInputBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your idea?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ideaController,
            maxLines: 4,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Ứng dụng AI Generative vào hỗ trợ sinh viên tự học lập trình tại trường đại học...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzeIdea,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Analyze Research Gap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final suggestions = [
      "AI support for student job seeking in university",
      "Applying Generative AI for personalized learning",
      "Impact of machine learning on medical diagnosis",
      "Blockchain technology in supply chain transparency"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need some inspiration? Try these:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions.map((idea) {
            return Material(
              color: isDark ? const Color(0xFF2A2A35) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _ideaController.text = idea;
                  _analyzeIdea();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          idea,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrendingPapersBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingTrending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trendingPapers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          '🔥 Top Trending Papers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._trendingPapers.map((paper) => InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaperDetailScreen(paperId: paper.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E28) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.format_quote, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${paper.citationCount} Citations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'AI is gathering papers & analyzing...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take 10-20 seconds',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        _buildMatrixTitle(),
        const SizedBox(height: 16),
        _buildMatrixTable(),
        const SizedBox(height: 24),
        _buildPapersList(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF232536), const Color(0xFF1E1E28)]
              : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _result!.summary,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixTitle() {
    return const Text(
      'Gap Matrix Comparison',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMatrixTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              isDark ? const Color(0xFF2A2A35) : Colors.grey[50],
            ),
            dataRowMinHeight: 60,
            dataRowMaxHeight: 80,
            horizontalMargin: 16,
            columnSpacing: 24,
            columns: [
              const DataColumn(
                label: Text(
                  'Paper / Idea',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              ..._result!.cores.map((core) => DataColumn(
                label: SizedBox(
                  width: 150,
                  child: Text(
                    core,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )),
            ],
            rows: _result!.matrix.map((row) {
              final isMyIdea = row.paper.toLowerCase().contains('my proposed idea');
              return DataRow(
                color: isMyIdea 
                    ? MaterialStateProperty.all(
                        isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50)
                    : null,
                cells: [
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        row.paper,
                        style: TextStyle(
                          fontWeight: isMyIdea ? FontWeight.bold : FontWeight.w500,
                          color: isMyIdea ? Colors.blue[600] : null,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ...row.ticks.map((tick) => DataCell(
                    Center(
                      child: Icon(
                        tick ? Icons.check_circle : Icons.remove,
                        color: tick 
                            ? Colors.green 
                            : (isDark ? Colors.white24 : Colors.black12),
                        size: 24,
                      ),
                    ),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPapersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyzed Papers (${_result!.papersAnalyzed.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._result!.papersAnalyzed.map((paper) => _buildPaperCard(paper)).toList(),
      ],
    );
  }

  Widget _buildPaperCard(GapMatrixPaperDto paper) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaperDetailScreen(
              paperId: paper.id,
              fallbackPdfUrl: paper.pdfUrl,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paper.source,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                if (paper.pdfUrl != null && paper.pdfUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(paper.pdfUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 12, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (paper.hasFullText) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Full Text',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              paper.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
