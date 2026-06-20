import 'package:flutter/material.dart';
import '../../data/models/paper_summary_dto.dart';
import 'dart:math';

class PaperCard extends StatelessWidget {
  final PaperSummaryDto paper;
  final VoidCallback onTap;

  const PaperCard({Key? key, required this.paper, required this.onTap}) : super(key: key);

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
    final avatarColor = _getRandomColor(paper.title);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                      Text(
                        paper.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Color(0xFF212529),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      if (paper.authors.isNotEmpty) ...[
                        Text(
                          paper.authors.join(', '),
                          style: const TextStyle(color: Color(0xFF868E96), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (paper.journalName != null && paper.journalName!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paper.journalName!,
                            style: const TextStyle(color: Color(0xFF495057), fontSize: 12, fontWeight: FontWeight.w500),
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
                          if (paper.publicationYear != null)
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 14, color: Color(0xFFADB5BD)),
                                const SizedBox(width: 4),
                                Text(
                                  paper.publicationYear.toString(),
                                  style: const TextStyle(color: Color(0xFF868E96), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            )
                          else
                            const SizedBox(),
                            
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
