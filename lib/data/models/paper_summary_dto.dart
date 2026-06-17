class PaperSummaryDto {
  final String id;
  final String title;
  final String? abstractText;
  final int? publicationYear;
  final String? journalName;
  final String source;
  final int citationCount;
  final List<String> authors;
  final List<String> keywords;

  PaperSummaryDto({
    required this.id,
    required this.title,
    this.abstractText,
    this.publicationYear,
    this.journalName,
    required this.source,
    required this.citationCount,
    required this.authors,
    required this.keywords,
  });

  factory PaperSummaryDto.fromJson(Map<String, dynamic> json) {
    return PaperSummaryDto(
      id: json['id'],
      title: json['title'] ?? '',
      abstractText: json['abstract'],
      publicationYear: json['publicationYear'],
      journalName: json['journalName'],
      source: json['source'] ?? '',
      citationCount: json['citationCount'] ?? 0,
      authors: (json['authors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
