import 'package:flutter/material.dart';
import '../../data/models/paper_summary_dto.dart';
import 'dart:math';

class PaperCard extends StatelessWidget {
  final PaperSummaryDto paper;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const PaperCard({
    Key? key, 
    required this.paper, 
    required this.onTap,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  }) : super(key: key);

  Color _getRandomColor(String text) {
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.deepOrange,
    ];
    final index = text.length % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = _getRandomColor(paper.title);
    final cardBg = isDark ? const Color(0xFF16161E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF212529);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF868E96);
    final labelBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100];
    final labelColor = isDark ? Colors.white70 : const Color(0xFF495057);
    final yearColor = isDark ? Colors.white54 : const Color(0xFF868E96);
    final calendarIconColor = isDark ? Colors.white30 : const Color(0xFFADB5BD);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Abstract visual placeholder for paper
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [avatarColor.withOpacity(0.6), avatarColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      paper.title.isNotEmpty ? paper.title[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              paper.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: titleColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onBookmarkToggle != null)
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: isBookmarked ? Colors.blue[700] : (isDark ? Colors.white54 : Colors.grey[400]),
                              ),
                              onPressed: onBookmarkToggle,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 8),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (paper.authors.isNotEmpty) ...[
                        Text(
                          paper.authors.join(', '),
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (paper.journalName != null && paper.journalName!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: labelBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paper.journalName!,
                            style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        const SizedBox(height: 4),
                      ],
                      
                      // Bottom Row: Year & Citations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (paper.publicationYear != null) ...[
                                Icon(Icons.calendar_month, size: 14, color: calendarIconColor),
                                const SizedBox(width: 4),
                                Text(
                                  paper.publicationYear.toString(),
                                  style: TextStyle(color: yearColor, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (paper.source.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: paper.source.toLowerCase().contains('openalex') 
                                        ? Colors.purple.withOpacity(0.1) 
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: paper.source.toLowerCase().contains('openalex')
                                          ? Colors.purple.withOpacity(0.3)
                                          : Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    paper.source,
                                    style: TextStyle(
                                      color: paper.source.toLowerCase().contains('openalex')
                                          ? Colors.purple[700]
                                          : Colors.blue[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                            
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  '${paper.citationCount}', 
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
