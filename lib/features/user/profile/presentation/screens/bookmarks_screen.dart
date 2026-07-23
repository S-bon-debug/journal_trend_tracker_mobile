import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/user_api_service.dart';
import '../../data/models/user_models.dart';
import '../../../../paper/presentation/screens/paper_detail_screen.dart';
import '../../../../paper/presentation/screens/papers_screen.dart';

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
          content: Text('Removed "${removedPaper.entityTitle}" from bookmarks', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF8B5CF6),
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
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _followedKeywords.insert(index, removed);
              });
              try {
                await _apiService.followKeyword(removed.targetId, targetName: removed.targetName);
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
          content: Text('Unfollowed journal "${removed.targetName}"', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                _followedJournals.insert(index, removed);
              });
              try {
                await _apiService.followJournal(removed.targetId, targetName: removed.targetName);
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
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF8B5CF6),
            indicatorWeight: 3,
            labelColor: const Color(0xFF8B5CF6),
            unselectedLabelColor: textColorSecondary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Saved Papers'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Followed Topics'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
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
              Icons.bookmark_border_rounded, 
              size: 64, 
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved papers yet.',
              style: GoogleFonts.inter(color: textColorTertiary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _bookmarkedPapers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final paper = _bookmarkedPapers[index];
        final textColor = isDark ? Colors.white : Colors.black87;
        final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
        final textColorTertiary = isDark ? Colors.white30 : Colors.black38;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaperDetailScreen(paperId: paper.entityId),
              ),
            ).then((_) => _loadData());
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.1 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left gradient accent bar
                    Container(
                      width: 5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Expanded(
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFEC4899)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.15), const Color(0xFFEC4899).withValues(alpha: 0.1)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    paper.entityType.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Saved on ${_formatDate(paper.createdAt)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: textColorTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorTertiary = isDark ? Colors.white30 : Colors.black38;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Followed Keywords',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_followedKeywords.isEmpty)
            Text('No followed keywords yet.', style: GoogleFonts.inter(color: textColorTertiary, fontSize: 14))
          else
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: List.generate(_followedKeywords.length, (index) {
                final keyword = _followedKeywords[index];
                final displayName = keyword.targetName.trim().isNotEmpty
                    ? keyword.targetName.trim()
                    : 'Topic ${keyword.targetId}';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PapersScreen(initialKeyword: displayName),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.1),
                          const Color(0xFFEC4899).withValues(alpha: isDark ? 0.12 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _unfollowKeyword(index),
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.library_books_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Followed Journals',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_followedJournals.isEmpty)
            Text('No followed journals yet.', style: GoogleFonts.inter(color: textColorTertiary, fontSize: 14))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _followedJournals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final journal = _followedJournals[index];
                final itemTextColor = isDark ? Colors.white : Colors.black87;
                final displayName = journal.targetName.trim().isNotEmpty
                    ? journal.targetName.trim()
                    : 'Journal ${journal.targetId}';
                final abbr = displayName.length >= 3 
                    ? displayName.substring(0, 3).toUpperCase() 
                    : displayName.toUpperCase();
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PapersScreen(
                          initialJournalId: journal.targetId,
                          initialKeyword: displayName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.08 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              abbr,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(fontSize: 14, color: itemTextColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                          onPressed: () => _unfollowJournal(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
