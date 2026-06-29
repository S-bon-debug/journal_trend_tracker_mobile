import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/user_api_service.dart';
import '../../data/models/user_models.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final UserApiService _apiService = UserApiService();
  bool _isLoading = true;
  String? _error;

  List<BookmarkDto> _bookmarkedPapers = [];
  List<FollowDto> _followedKeywords = [];
  List<FollowDto> _followedJournals = [];

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookmarks = await _apiService.getBookmarks();
      final follows = await _apiService.getFollows();

      setState(() {
        _bookmarkedPapers = bookmarks.where((e) => e.entityType == 'paper').toList();
        _followedKeywords = follows.where((e) => e.followType == 'keyword').toList();
        _followedJournals = follows.where((e) => e.followType == 'journal').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _removeBookmark(int index) async {
    final removedPaper = _bookmarkedPapers[index];
    setState(() {
      _bookmarkedPapers.removeAt(index);
    });

    try {
      await _apiService.deleteBookmark(removedPaper.id);
    } catch (e) {
      debugPrint('Failed to delete bookmark: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${removedPaper.entityTitle}" from bookmarks.', style: GoogleFonts.inter()),
          backgroundColor: Colors.purpleAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _bookmarkedPapers.insert(index, removedPaper);
              });
              try {
                await _apiService.addBookmark(
                  entityType: removedPaper.entityType,
                  entityId: removedPaper.entityId,
                  entityTitle: removedPaper.entityTitle,
                  note: removedPaper.note,
                );
              } catch (e) {
                debugPrint('Failed to re-add bookmark: $e');
              }
            },
          ),
        ),
      );
    }
  }

  void _unfollowKeyword(int index) async {
    final removed = _followedKeywords[index];
    setState(() {
      _followedKeywords.removeAt(index);
    });

    try {
      await _apiService.unfollow(removed.id);
    } catch (e) {
      debugPrint('Failed to unfollow keyword: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed topic "${removed.targetName}"', style: GoogleFonts.inter()),
          backgroundColor: Colors.purpleAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _followedKeywords.insert(index, removed);
              });
              try {
                await _apiService.followKeyword(removed.targetId);
              } catch (e) {
                debugPrint('Failed to re-follow keyword: $e');
              }
            },
          ),
        ),
      );
    }
  }

  void _unfollowJournal(int index) async {
    final removed = _followedJournals[index];
    setState(() {
      _followedJournals.removeAt(index);
    });

    try {
      await _apiService.unfollow(removed.id);
    } catch (e) {
      debugPrint('Failed to unfollow journal: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed "${removed.targetName}"', style: GoogleFonts.inter()),
          backgroundColor: Colors.purpleAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _followedJournals.insert(index, removed);
              });
              try {
                await _apiService.followJournal(removed.targetId);
              } catch (e) {
                debugPrint('Failed to re-follow journal: $e');
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white54 : Colors.black54;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Bookmarks & Follows',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.purpleAccent,
            unselectedLabelColor: textColorSecondary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Bookmarked Papers'),
              Tab(text: 'Followed Topics'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
            : _error != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Connection error: $_error', 
                            style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87), 
                            textAlign: TextAlign.center
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildPapersTab(),
                      _buildFollowsTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPapersTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorTertiary = isDark ? Colors.white30 : Colors.black38;

    if (_bookmarkedPapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border, 
              size: 64, 
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarked papers yet.',
              style: GoogleFonts.inter(color: textColorTertiary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _bookmarkedPapers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final paper = _bookmarkedPapers[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
        final textColorTertiary = isDark ? Colors.white30 : Colors.black38;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        paper.entityTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: Colors.purpleAccent),
                      onPressed: () => _removeBookmark(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  paper.note ?? 'No details available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: textColorSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                      ),
                      child: Text(
                        paper.entityType.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saved on ${_formatDate(paper.createdAt)}',
                      style: GoogleFonts.inter(fontSize: 12, color: textColorTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
    final textColorTertiary = isDark ? Colors.white30 : Colors.black38;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Followed Keywords',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_followedKeywords.isEmpty)
            Text('Not following any keywords.', style: GoogleFonts.inter(color: textColorTertiary, fontSize: 14))
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_followedKeywords.length, (index) {
                final keyword = _followedKeywords[index];
                return InputChip(
                  label: Text(keyword.targetName),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  labelStyle: GoogleFonts.inter(color: textColor, fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  ),
                  deleteIcon: Icon(Icons.cancel, size: 16, color: textColorSecondary),
                  onDeleted: () => _unfollowKeyword(index),
                );
              }),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.book, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Followed Journals',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_followedJournals.isEmpty)
            Text('Not following any journals.', style: GoogleFonts.inter(color: textColorTertiary, fontSize: 14))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _followedJournals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final journal = _followedJournals[index];
                final abbr = journal.targetName.length >= 3 
                    ? journal.targetName.substring(0, 3).toUpperCase() 
                    : journal.targetName.toUpperCase();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          abbr,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          journal.targetName,
                          style: GoogleFonts.inter(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.star, color: Colors.purpleAccent),
                        onPressed: () => _unfollowJournal(index),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
