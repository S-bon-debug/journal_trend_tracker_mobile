import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/paper_detail_dto.dart';
import '../../data/services/paper_api_service.dart';
import '../../../user/profile/data/services/user_api_service.dart';
import '../../../user/profile/data/models/user_models.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;

  const PaperDetailScreen({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperDetailScreenState createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final PaperApiService _apiService = PaperApiService();
  final UserApiService _userApiService = UserApiService();
  PaperDetailDto? _paper;
  bool _isLoading = true;
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
                if (_paper!.pdfUrl != null && _paper!.pdfUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(_paper!.pdfUrl!);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open the PDF link')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download / View PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                ],

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
