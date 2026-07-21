import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
  bool _isFollowingJournal = false;
  String? _journalFollowId;

  @override
  void initState() {
    super.initState();
    _fetchPaperDetail();
  }

  Future<void> _fetchPaperDetail() async {
    try {
      final paper = await _apiService.getPaperDetail(widget.paperId);
      
      List<FollowDto> follows = [];
      try {
        follows = await _userApiService.getFollows();
      } catch (e) {
        debugPrint('Failed to load user follows: $e');
      }

      final isFollowingJournal = paper.journal != null &&
          follows.any((f) => f.followType == 'journal' && f.targetId == paper.journal!.id);
          
      final journalFollow = paper.journal != null
          ? follows.firstWhere(
              (f) => f.followType == 'journal' && f.targetId == paper.journal!.id,
              orElse: () => FollowDto(id: '', followType: '', targetId: '', targetName: '', notifyEmail: false, notifyInapp: false, createdAt: ''),
            )
          : null;

      setState(() {
        _paper = paper;
        _follows = follows;
        _isFollowingJournal = isFollowingJournal;
        _journalFollowId = (journalFollow != null && journalFollow.id.isNotEmpty) ? journalFollow.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed journal "$journalName"')),
          );
        }
      } else {
        await _userApiService.followJournal(journalId, targetName: journalName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Following journal "$journalName"')),
        );
      }
      await _fetchPaperDetail();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow: $e')),
      );
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
        title: Text(isFollowing ? 'Unfollow Topic' : 'Follow Topic'),
        content: Text(
          isFollowing 
              ? 'Are you sure you want to unfollow "${keyword.term}"?' 
              : 'Do you want to follow "${keyword.term}" to receive notifications when new papers are added?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isFollowing ? 'Unfollow' : 'Follow'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed topic "${keyword.term}"')),
          );
        } else {
          await _userApiService.followKeyword(keyword.id, targetName: keyword.term);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Following topic "${keyword.term}"')),
          );
        }
        await _fetchPaperDetail();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showDeepAnalysisBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to exceed half screen
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.deepPurple, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Phân tích chuyên sâu PDF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn cách bạn muốn cung cấp file PDF để AI có thể đọc và phân tích sâu toàn bộ bài báo.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // Option 1: Auto Extract
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleAutoExtract();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.deepPurple.shade50,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tự động tải từ Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                              SizedBox(height: 4),
                              Text('Hệ thống tự tải PDF từ nhà xuất bản (có thể bị chặn nếu bảo mật cao).', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Option 2: Manual Upload
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleManualUpload();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tải lên thủ công (Khuyên dùng)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              SizedBox(height: 4),
                              Text('Tự tải PDF về máy và Upload. Tỉ lệ thành công 100%.', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAutoExtract() async {
    if (_isExtracting) return;
    
    final pdfUrlToUse = (_paper?.pdfUrl != null && _paper!.pdfUrl!.isNotEmpty) 
        ? _paper!.pdfUrl 
        : (widget.fallbackPdfUrl != null && widget.fallbackPdfUrl!.isNotEmpty) 
            ? widget.fallbackPdfUrl 
            : null;
            
    if (pdfUrlToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bài báo này không có link PDF để tải tự động. Vui lòng tìm và tải thủ công!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExtracting = true;
    });

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Đang tải và phân tích PDF...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(Uri.parse(pdfUrlToUse));
      if (response.statusCode != 200) {
        throw Exception('Lỗi khi tải PDF (HTTP ${response.statusCode})');
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('text/html')) {
        throw Exception('Link này là trang web, không phải file PDF trực tiếp. Vui lòng nhấn vào "Read Full Paper", tải file PDF về máy, sau đó dùng tính năng Tải lên (Manual Upload) trong mục Phân tích chuyên sâu!');
      }

      final apiResult = await _apiService.uploadPdfBytesForDeepAnalysis(widget.paperId, response.bodyBytes, 'temp_paper_${widget.paperId}.pdf');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
      setState(() {
        _isExtracting = false;
      });

      final dto = DeepAnalysisResultDto.fromJson(apiResult);
      _showDeepAnalysisResultDialog(dto);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
      setState(() {
        _isExtracting = false;
      });
      
      String errorMessage = e.toString();
      if (errorMessage.contains("Could not extract text from PDF")) {
        errorMessage = "Hệ thống không thể trích xuất chữ từ PDF này (có thể file bị lỗi, hoặc là trang web chứ không phải PDF). Vui lòng tự tải PDF chuẩn về máy rồi dùng Manual Upload!";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleManualUpload() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Need this for Flutter Web
      );

      if (result != null && result.files.single != null) {
        if (!mounted) return;
        
        // Show processing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.deepPurple),
                SizedBox(height: 16),
                Text('Đã nhận file. AI đang phân tích...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );

        final platformFile = result.files.single;
        dynamic apiResult;
        
        if (platformFile.bytes != null) {
          // Web (and Mobile if withData: true)
          apiResult = await _apiService.uploadPdfBytesForDeepAnalysis(widget.paperId, platformFile.bytes!, platformFile.name);
        } else if (platformFile.path != null) {
          // Fallback for Mobile if bytes is null
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
      Navigator.of(context, rootNavigator: true).pop(); // Try close dialog if error occurs during upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeepAnalysisResultDialog(DeepAnalysisResultDto dto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('✨ Kết quả phân tích', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisSection('Tóm tắt (Summary)', dto.summary, Icons.article),
                    _buildAnalysisSection('Phương pháp (Methodology)', dto.methodology, Icons.science),
                    _buildAnalysisSection('Kết quả cốt lõi (Findings)', dto.findings, Icons.lightbulb),
                    _buildAnalysisSection('Hạn chế (Limitations)', dto.limitations, Icons.warning_amber),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
            ),
            child: Text(
              content.isEmpty ? 'Không có thông tin.' : content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPaperDetail,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_paper == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 60.0,
          floating: true,
          pinned: true,
          elevation: 1,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Article',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_paper!.journal != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _paper!.journal!.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (_paper!.publicationYear != null)
                        Text(
                          '${_paper!.publicationYear}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  _paper!.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontFamily: 'Georgia', // Elegant serif font
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (_paper!.authors.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _paper!.authors.map((a) {
                      final isLast = a == _paper!.authors.last;
                      return Text(
                        a.name + (isLast ? '' : ','),
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Metadata Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Stats Row (DOI, Citations, Source)
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (_paper!.doi != null && _paper!.doi!.isNotEmpty)
                      _buildMiniBadge(Icons.link, _paper!.doi!),
                    _buildMiniBadge(Icons.format_quote, '${_paper!.citationCount} Citations'),
                    if (_paper!.source.isNotEmpty)
                      _buildMiniBadge(Icons.language, _paper!.source),
                  ],
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final pdfUrlToUse = (_paper!.pdfUrl != null && _paper!.pdfUrl!.isNotEmpty) 
                        ? _paper!.pdfUrl 
                        : (widget.fallbackPdfUrl != null && widget.fallbackPdfUrl!.isNotEmpty) 
                            ? widget.fallbackPdfUrl 
                            : null;

                    if (pdfUrlToUse != null) {
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleAutoExtract,
                              icon: const Icon(Icons.analytics),
                              label: const Text('Download & Deep Analyze PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showDeepAnalysisBottomSheet,
                      icon: const Icon(Icons.analytics),
                      label: const Text('✨ Phân tích chuyên sâu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                if (_paper!.url != null && _paper!.url!.isNotEmpty || _paper!.doi != null && _paper!.doi!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                              const SnackBar(content: Text('Could not open the link')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Read Full Paper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // We replaced Journal and Authors to the top. Just hiding the old blocks.

                if (_paper!.abstractText != null && _paper!.abstractText!.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.blueGrey, size: 24),
                      SizedBox(width: 8),
                      Text('Abstract', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      _paper!.abstractText!,
                      style: TextStyle(
                        fontSize: 16, 
                        height: 1.8, 
                        color: Colors.blueGrey.shade800,
                        letterSpacing: 0.2,
                        fontStyle: FontStyle.normal,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (_paper!.fieldsOfStudy != null && _paper!.fieldsOfStudy!.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.category_outlined, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text('Fields of Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.fieldsOfStudy!.map((f) => Chip(
                      label: Text(f, style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                const Row(
                  children: [
                    Icon(Icons.tag, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                      return InputChip(
                        label: Text(k.term),
                        labelStyle: TextStyle(
                          color: isFollowing ? Colors.purple[800] : Colors.grey[800],
                          fontSize: 13,
                          fontWeight: isFollowing ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isFollowing ? Colors.purple.shade50 : Colors.grey.shade200,
                        selectedColor: Colors.purple.shade100,
                        side: isFollowing ? BorderSide(color: Colors.purple.shade200) : BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () => _onKeywordChipTapped(k),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
