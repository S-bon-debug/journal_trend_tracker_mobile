import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/paper_detail_dto.dart';
import '../../data/services/paper_api_service.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;

  const PaperDetailScreen({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperDetailScreenState createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final PaperApiService _apiService = PaperApiService();
  PaperDetailDto? _paper;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPaperDetail();
  }

  Future<void> _fetchPaperDetail() async {
    try {
      final paper = await _apiService.getPaperDetail(widget.paperId);
      setState(() {
        _paper = paper;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_paper!.publicationYear != null)
                      _buildInfoBadge(Icons.calendar_today, _paper!.publicationYear.toString(), Colors.blue),
                    _buildInfoBadge(Icons.format_quote, '${_paper!.citationCount} Citations', Colors.orange),
                    _buildInfoBadge(Icons.library_books, '${_paper!.referenceCount} References', Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_paper!.source.isNotEmpty)
                      _buildInfoBadge(Icons.source, 'Source: ${_paper!.source}', Colors.teal),
                    if (_paper!.doi != null && _paper!.doi!.isNotEmpty)
                      _buildInfoBadge(Icons.link, 'DOI: ${_paper!.doi}', Colors.indigo),
                  ],
                ),
                const SizedBox(height: 24),

                if (_paper!.url != null && _paper!.url!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(_paper!.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
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

                const Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Authors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_paper!.authors.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.authors.map((a) => Chip(
                      label: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )).toList(),
                  )
                else
                  const Text('No author information available', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),

                const Row(
                  children: [
                    Icon(Icons.library_books_outlined, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Journal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_paper!.journal != null)
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
                      _paper!.journal!.name,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  )
                else
                  const Text('No journal information available', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),

                const Row(
                  children: [
                    Icon(Icons.article_outlined, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Abstract', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_paper!.abstractText != null && _paper!.abstractText!.isNotEmpty)
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
                  )
                else
                  const Text('No abstract available', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),

                const Row(
                  children: [
                    Icon(Icons.category_outlined, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Fields of Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_paper!.fieldsOfStudy != null && _paper!.fieldsOfStudy!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paper!.fieldsOfStudy!.map((f) => Chip(
                      label: Text(f, style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList(),
                  )
                else
                  const Text('No fields of study specified', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),

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
                    children: _paper!.keywords.map((k) => Chip(
                      label: Text(k.term, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                      backgroundColor: Colors.grey.shade200,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList(),
                  )
                else
                  const Text('No keywords available', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 32),
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
