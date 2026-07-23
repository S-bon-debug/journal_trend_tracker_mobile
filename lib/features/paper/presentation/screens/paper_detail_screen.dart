import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/paper_detail_dto.dart';
import '../../data/models/deep_analysis_result_dto.dart';
import '../../data/services/paper_api_service.dart';
import '../../../user/profile/data/services/user_api_service.dart';
import '../../../user/profile/data/models/user_models.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;
  final String? fallbackPdfUrl;

  const PaperDetailScreen({
    Key? key,
    required this.paperId,
    this.fallbackPdfUrl,
  }) : super(key: key);

  @override
  _PaperDetailScreenState createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final PaperApiService _apiService = PaperApiService();
  final UserApiService _userApiService = UserApiService();
  PaperDetailDto? _paper;
  bool _isLoading = true;
  bool _isExtracting = false;
  String? _error;

  List<FollowDto> _follows = [];
  List<BookmarkDto> _bookmarks = [];
  bool _isFollowingJournal = false;
  bool _isBookmarked = false;
  String? _journalFollowId;
  String? _bookmarkId;

  @override
  void initState() {
    super.initState();
    _fetchPaperDetail();
  }

  Future<void> _fetchPaperDetail() async {
    try {
      final paper = await _apiService.getPaperDetail(widget.paperId);
      
      List<FollowDto> follows = [];
      List<BookmarkDto> bookmarks = [];
      try {
        follows = await _userApiService.getFollows();
        bookmarks = await _userApiService.getBookmarks();
      } catch (e) {
        debugPrint('Failed to load user follows/bookmarks: $e');
      }

      final isFollowingJournal = paper.journal != null &&
          follows.any((f) => f.followType == 'journal' && f.targetId == paper.journal!.id);
          
      final journalFollow = paper.journal != null
          ? follows.firstWhere(
              (f) => f.followType == 'journal' && f.targetId == paper.journal!.id,
              orElse: () => FollowDto(id: '', followType: '', targetId: '', targetName: '', notifyEmail: false, notifyInapp: false, createdAt: ''),
            )
          : null;

      final bookmark = bookmarks.firstWhere(
        (b) => b.entityId == paper.id,
        orElse: () => BookmarkDto(id: '', entityType: '', entityId: '', entityTitle: '', createdAt: ''),
      );

      setState(() {
        _paper = paper;
        _follows = follows;
        _bookmarks = bookmarks;
        _isFollowingJournal = isFollowingJournal;
        _journalFollowId = (journalFollow != null && journalFollow.id.isNotEmpty) ? journalFollow.id : null;
        _isBookmarked = bookmark.id.isNotEmpty;
        _bookmarkId = bookmark.id.isNotEmpty ? bookmark.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_paper == null) return;
    setState(() => _isLoading = true);

    try {
      if (_isBookmarked && _bookmarkId != null) {
        await _userApiService.deleteBookmark(_bookmarkId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã bỏ lưu bài báo')),
          );
        }
      } else {
        await _userApiService.addBookmark(
          entityType: 'paper',
          entityId: _paper!.id,
          entityTitle: _paper!.title,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu bài báo thành công!')),
          );
        }
      }
      await _fetchPaperDetail();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thao tác thất bại: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollowJournal() async {
    if (_paper == null || _paper!.journal == null) return;
    
    final journalId = _paper!.journal!.id;
    final journalName = _paper!.journal!.name;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowingJournal) {
        if (_journalFollowId != null) {
          await _userApiService.unfollow(_journalFollowId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã bỏ theo dõi tạp chí "$journalName"')),
            );
          }
        }
      } else {
        await _userApiService.followJournal(journalId, targetName: journalName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đang theo dõi tạp chí "$journalName"')),
          );
        }
      }
      await _fetchPaperDetail();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      }
    }
  }

  void _onKeywordChipTapped(KeywordDto keyword) async {
    final keywordFollow = _follows.firstWhere(
      (f) => f.followType == 'keyword' && f.targetId == keyword.id,
      orElse: () => FollowDto(id: '', followType: '', targetId: '', targetName: '', notifyEmail: false, notifyInapp: false, createdAt: ''),
    );
    final isFollowing = keywordFollow.id.isNotEmpty;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFollowing ? 'Bỏ theo dõi chủ đề' : 'Theo dõi chủ đề'),
        content: Text(
          isFollowing 
              ? 'Bạn có chắc chắn muốn bỏ theo dõi chủ đề "${keyword.term}"?' 
              : 'Bạn có muốn theo dõi "${keyword.term}" để nhận thông báo khi có bài báo mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isFollowing ? 'Bỏ theo dõi' : 'Theo dõi', style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (isFollowing) {
          await _userApiService.unfollow(keywordFollow.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã bỏ theo dõi chủ đề "${keyword.term}"')),
            );
          }
        } else {
          await _userApiService.followKeyword(keyword.id, targetName: keyword.term);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đang theo dõi chủ đề "${keyword.term}"')),
            );
          }
        }
        await _fetchPaperDetail();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleManualUpload() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    SizedBox(height: 16),
                    Text('Đang tải và phân tích PDF...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );

        final platformFile = result.files.single;
        dynamic apiResult;
        
        if (platformFile.bytes != null) {
          apiResult = await _apiService.uploadPdfBytesForDeepAnalysis(widget.paperId, platformFile.bytes!, platformFile.name);
        } else if (platformFile.path != null) {
          apiResult = await _apiService.uploadPdfForDeepAnalysis(widget.paperId, platformFile.path!);
        } else {
          throw Exception("Không thể đọc được file.");
        }

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        
        final dto = DeepAnalysisResultDto.fromJson(apiResult);
        _showDeepAnalysisResultDialog(dto);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showDeepAnalysisResultDialog(DeepAnalysisResultDto dto) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14141F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ).createShader(bounds),
                  child: Text(
                    '✨ Kết quả phân tích chuyên sâu',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisSection('Tóm tắt (Summary)', dto.summary, Icons.article_rounded),
                    _buildAnalysisSection('Phương pháp (Methodology)', dto.methodology, Icons.science_rounded),
                    _buildAnalysisSection('Kết quả cốt lõi (Findings)', dto.findings, Icons.lightbulb_rounded),
                    _buildAnalysisSection('Hạn chế (Limitations)', dto.limitations, Icons.warning_amber_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, String content, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3E8FF);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9D5FF);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              content.isEmpty ? 'Không có thông tin.' : content,
              style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPaperDetail,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                        child: const Text('Thử lại'),
                      )
                    ],
                  ),
                )
              : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_paper == null) return const SizedBox.shrink();

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 60.0,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: IconThemeData(color: textColor),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Chi tiết bài báo',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: const Color(0xFFEC4899),
              ),
              onPressed: _toggleBookmark,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Journal & Year Row
                if (_paper!.journal != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _paper!.journal!.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleFollowJournal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isFollowingJournal
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                : isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isFollowingJournal ? const Color(0xFF8B5CF6) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFollowingJournal ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14,
                                color: const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isFollowingJournal ? 'Đã theo dõi' : 'Theo dõi tạp chí',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isFollowingJournal ? const Color(0xFF8B5CF6) : subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_paper!.publicationYear != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${_paper!.publicationYear}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  _paper!.title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Authors
                if (_paper!.authors.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _paper!.authors.map((a) {
                      final isLast = a == _paper!.authors.last;
                      return Text(
                        a.name + (isLast ? '' : ','),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Divider
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 16),

                // Stats Badges (DOI, Citations, Source)
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    if (_paper!.doi != null && _paper!.doi!.isNotEmpty)
                      _buildMiniBadge(Icons.link_rounded, _paper!.doi!, isDark),
                    _buildMiniBadge(Icons.format_quote_rounded, '${_paper!.citationCount} Citations', isDark, isAccent: true),
                    if (_paper!.source.isNotEmpty)
                      _buildMiniBadge(Icons.language_rounded, _paper!.source, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Column(
                  children: [
                    // Deep analysis button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _handleManualUpload,
                          icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            '✨ Phân tích chuyên sâu (Upload PDF)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full text button
                    if (_paper!.url != null && _paper!.url!.isNotEmpty || _paper!.doi != null && _paper!.doi!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            var urlString = _paper!.url != null && _paper!.url!.isNotEmpty ? _paper!.url! : _paper!.doi!;
                            if (!urlString.startsWith('http')) {
                              urlString = 'https://doi.org/$urlString';
                            }
                            final uri = Uri.parse(urlString);
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không thể mở liên kết')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Đọc toàn văn bài báo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // Abstract Card
                if (_paper!.abstractText != null && _paper!.abstractText!.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Abstract',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _paper!.abstractText!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.7,
                        color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Fields of Study
                if (_paper!.fieldsOfStudy != null && _paper!.fieldsOfStudy!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.category_rounded, color: Color(0xFF8B5CF6), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lĩnh vực nghiên cứu',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.fieldsOfStudy!.map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF059669).withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Keywords
                Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, color: Color(0xFFEC4899), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Từ khóa',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_paper!.keywords.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.keywords.map((k) {
                      final isFollowing = _follows.any(
                        (f) => f.followType == 'keyword' && f.targetId == k.id,
                      );
                      return GestureDetector(
                        onTap: () => _onKeywordChipTapped(k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isFollowing
                                ? const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  )
                                : null,
                            color: isFollowing
                                ? null
                                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(20),
                            border: isFollowing
                                ? null
                                : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                            boxShadow: isFollowing
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFollowing) ...[
                                const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                k.term,
                                style: TextStyle(
                                  color: isFollowing ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontSize: 13,
                                  fontWeight: isFollowing ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, bool isDark, {bool isAccent = false}) {
    final bg = isAccent
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04));
    final fg = isAccent ? const Color(0xFF8B5CF6) : (isDark ? Colors.white70 : Colors.black54);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccent ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
