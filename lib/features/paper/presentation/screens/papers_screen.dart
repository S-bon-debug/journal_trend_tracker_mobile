import 'package:flutter/material.dart';
import '../../data/models/paper_summary_dto.dart';
import '../../data/models/paper_filter_dto.dart';
import '../../data/services/paper_api_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../user/profile/data/services/user_api_service.dart';
import '../widgets/paper_card.dart';
import 'paper_detail_screen.dart';

class PapersScreen extends StatefulWidget {
  const PapersScreen({Key? key}) : super(key: key);

  @override
  _PapersScreenState createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  final PaperApiService _apiService = PaperApiService();
  final UserApiService _userService = UserApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PaperSummaryDto> _papers = [];
  Map<String, String> _bookmarks = {};
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String _currentKeyword = '';
  
  int? _userRole;

  // Filters
  int? _selectedYear;
  String? _selectedSource;
  
  String? _error;

  final List<int?> _years = [null, 2026];
  final List<Map<String, String?>> _sources = [
    {'name': 'All Sources', 'value': null},
    {'name': 'Semantic Scholar', 'value': 'SemanticScholar'},
    {'name': 'OpenAlex', 'value': 'OpenAlex'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchBookmarks();
    _fetchPapers();
  }

  Future<void> _fetchBookmarks() async {
    try {
      final bookmarks = await _userService.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarks = {
            for (var b in bookmarks.where((b) => b.entityType == 'paper'))
              b.entityId: b.id
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch bookmarks: $e');
    }
  }

  Future<void> _toggleBookmark(PaperSummaryDto paper) async {
    final isBookmarked = _bookmarks.containsKey(paper.id);
    try {
      if (isBookmarked) {
        final bookmarkId = _bookmarks[paper.id]!;
        await _userService.deleteBookmark(bookmarkId);
        setState(() {
          _bookmarks.remove(paper.id);
        });
      } else {
        await _userService.addBookmark(
          entityType: 'paper',
          entityId: paper.id,
          entityTitle: paper.title,
        );
        await _fetchBookmarks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bookmark: $e')),
        );
      }
    }
  }

  Future<void> _loadUserRole() async {
    final storage = await TokenStorage.instance;
    setState(() {
      _userRole = storage.getUserRole();
    });
  }

  Future<void> _fetchPapers({int? targetPage}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pageToFetch = targetPage ?? 1;

      final filter = PaperFilterDto(
        keyword: _currentKeyword,
        year: _selectedYear,
        source: _selectedSource,
        page: pageToFetch,
        pageSize: 10,
      );

      final result = await _apiService.searchPapers(filter);

      setState(() {
        _papers = result.items;
        _currentPage = result.page;
        _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
        _isLoading = false;
      });
      
      if (targetPage != null && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String keyword) {
    _currentKeyword = keyword;
    _fetchPapers(targetPage: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
            _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _userRole == 3 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'refresh_btn',
                  onPressed: () => _fetchPapers(targetPage: _currentPage),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'sync_btn',
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Triggering paper sync process...')),
                    );
                    try {
                      await _apiService.triggerSyncPapers();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Success! Please wait 1-2 minutes for papers to download.')),
                      );
                      
                      // Reload list
                      _fetchPapers(targetPage: 1); 
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync'),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ],
            )
          : FloatingActionButton.extended(
              heroTag: 'refresh_btn',
              onPressed: () => _fetchPapers(targetPage: _currentPage),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF16161E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D1E);
    final searchBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F3F5);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      color: headerBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latest Papers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.blue[50],
                radius: 24,
                child: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.blue[700]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by title, author, keyword...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFADB5BD)),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white30 : const Color(0xFF868E96)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: isDark ? Colors.white30 : const Color(0xFF868E96)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: false,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: _onSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterBg = isDark ? const Color(0xFF16161E) : Colors.white;
    final chipBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F3F5);
    final unselectedTextColor = isDark ? Colors.white70 : const Color(0xFF495057);

    return Container(
      color: filterBg,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _years.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final year = _years[index];
                final isSelected = _selectedYear == year;
                return ChoiceChip(
                  label: Text(year == null ? 'All Years' : year.toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedYear = year;
                      _fetchPapers();
                    });
                  },
                  backgroundColor: chipBg,
                  selectedColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.blue[700]! : Colors.transparent),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Source Filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _sources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final source = _sources[index];
                final isSelected = _selectedSource == source['value'];
                return ChoiceChip(
                  label: Text(source['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSource = source['value'];
                      _fetchPapers();
                    });
                  },
                  backgroundColor: chipBg,
                  selectedColor: isDark ? Colors.purpleAccent : const Color(0xFF343A40),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? (isDark ? Colors.purpleAccent : const Color(0xFF343A40)) : Colors.transparent),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_papers.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_papers.isEmpty && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off, size: 64, color: Colors.red[300]),
              ),
              const SizedBox(height: 24),
              Text(
                'Connection Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _fetchPapers(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_papers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No papers found.', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchPapers(targetPage: _currentPage),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(20.0),
              itemCount: _papers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final paper = _papers[index];
                return PaperCard(
                  paper: paper,
                  isBookmarked: _bookmarks.containsKey(paper.id),
                  onBookmarkToggle: () => _toggleBookmark(paper),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaperDetailScreen(paperId: paper.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _fetchPapers(targetPage: _currentPage - 1) : null,
            color: _currentPage > 1 ? Colors.blue[700] : Colors.grey,
          ),
          const SizedBox(width: 16),
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _fetchPapers(targetPage: _currentPage + 1) : null,
            color: _currentPage < _totalPages ? Colors.blue[700] : Colors.grey,
          ),
        ],
      ),
    );
  }
}
