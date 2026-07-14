import 'package:flutter/material.dart';
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
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            title: const Text(
              'Paper Detail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paper!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Publication Info Row
                Row(
                  children: [
                    if (_paper!.publicationYear != null) ...[
                      _buildInfoBadge(Icons.calendar_today, _paper!.publicationYear.toString(), Colors.blue),
                      const SizedBox(width: 12),
                    ],
                    _buildInfoBadge(Icons.format_quote, '${_paper!.citationCount} Citations', Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),

                if (_paper!.authors.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.people_outline, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text('Authors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.authors.map((a) => Chip(
                      label: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_paper!.journal != null) ...[
                  const Row(
                    children: [
                      Icon(Icons.library_books_outlined, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text('Journal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _paper!.journal!.name,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _toggleFollowJournal,
                          icon: Icon(
                            _isFollowingJournal ? Icons.star : Icons.star_border,
                            color: Colors.purpleAccent,
                          ),
                          label: Text(
                            _isFollowingJournal ? 'Following' : 'Follow',
                            style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_paper!.abstractText != null) ...[
                  const Row(
                    children: [
                      Icon(Icons.article_outlined, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text('Abstract', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _paper!.abstractText!,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_paper!.keywords.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.tag, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text('Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
