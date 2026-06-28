import 'package:flutter/material.dart';
import '../../data/models/paper_summary_dto.dart';
import '../../data/models/paper_filter_dto.dart';
import '../../data/services/paper_api_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../widgets/paper_card.dart';
import 'paper_detail_screen.dart';

class PapersScreen extends StatefulWidget {
  const PapersScreen({Key? key}) : super(key: key);

  @override
  _PapersScreenState createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  final PaperApiService _apiService = PaperApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PaperSummaryDto> _papers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _currentKeyword = '';
  
  int? _userRole;

  // Filters
  int? _selectedYear;
  String? _selectedSource;
  
  String? _error;

  final List<int?> _years = [null, 2024, 2023, 2022, 2021, 2020];
  final List<Map<String, String?>> _sources = [
    {'name': 'All Sources', 'value': null},
    {'name': 'Semantic Scholar', 'value': 'semantic_scholar'},
    {'name': 'OpenAlex', 'value': 'openalex'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchPapers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _fetchPapers(loadMore: true);
        }
      }
    });
  }

  Future<void> _loadUserRole() async {
    final storage = await TokenStorage.instance;
    setState(() {
      _userRole = storage.getUserRole();
    });
  }

  Future<void> _fetchPapers({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!loadMore) {
        _currentPage = 1;
        _papers.clear();
      }

      final filter = PaperFilterDto(
        keyword: _currentKeyword,
        year: _selectedYear,
        source: _selectedSource,
        page: _currentPage,
        pageSize: 10,
      );

      final result = await _apiService.searchPapers(filter);

      setState(() {
        _papers.addAll(result.items);
        _currentPage++;
        _hasMore = _currentPage <= result.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String keyword) {
    _currentKeyword = keyword;
    _fetchPapers();
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                  onPressed: () => _fetchPapers(loadMore: false),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại trang'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'sync_btn',
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang kích hoạt tiến trình lấy bài báo...')),
                    );
                    try {
                      await _apiService.triggerSyncPapers();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thành công! Vui lòng chờ 1-2 phút để bài báo tải về.')),
                      );
                      
                      // Reload list
                      _fetchPapers(); 
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ'),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ],
            )
          : FloatingActionButton.extended(
              heroTag: 'refresh_btn',
              onPressed: () => _fetchPapers(loadMore: false),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại trang'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      color: Colors.white,
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
                  const Text(
                    'Latest Papers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                radius: 24,
                child: Icon(Icons.person, color: Colors.blue[700]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF1A1D1E),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by title, author, keyword...',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF868E96)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF868E96)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    return Container(
      color: Colors.white,
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
                  backgroundColor: const Color(0xFFF1F3F5),
                  selectedColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF495057),
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
                  backgroundColor: const Color(0xFFF1F3F5),
                  selectedColor: const Color(0xFF343A40),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF495057),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? const Color(0xFF343A40) : Colors.transparent),
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

    return RefreshIndicator(
      onRefresh: () => _fetchPapers(loadMore: false),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        itemCount: _papers.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == _papers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final paper = _papers[index];
          return PaperCard(
            paper: paper,
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
    );
  }
}
