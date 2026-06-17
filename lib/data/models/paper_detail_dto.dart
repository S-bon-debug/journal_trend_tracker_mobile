class PaperDetailDto {
  final String id;
  final String externalId;
  final String source;
  final String title;
  final String? abstractText;
  final int? publicationYear;
  final String? doi;
  final String? url;
  final int citationCount;
  final int referenceCount;
  final List<String>? fieldsOfStudy;
  final JournalDto? journal;
  final List<AuthorDto> authors;
  final List<KeywordDto> keywords;

  PaperDetailDto({
    required this.id,
    required this.externalId,
    required this.source,
    required this.title,
    this.abstractText,
    this.publicationYear,
    this.doi,
    this.url,
    required this.citationCount,
    required this.referenceCount,
    this.fieldsOfStudy,
    this.journal,
    required this.authors,
    required this.keywords,
  });

  factory PaperDetailDto.fromJson(Map<String, dynamic> json) {
    return PaperDetailDto(
      id: json['id'],
      externalId: json['externalId'] ?? '',
      source: json['source'] ?? '',
      title: json['title'] ?? '',
      abstractText: json['abstract'],
      publicationYear: json['publicationYear'],
      doi: json['doi'],
      url: json['url'],
      citationCount: json['citationCount'] ?? 0,
      referenceCount: json['referenceCount'] ?? 0,
      fieldsOfStudy: (json['fieldsOfStudy'] as List?)?.map((e) => e.toString()).toList(),
      journal: json['journal'] != null ? JournalDto.fromJson(json['journal']) : null,
      authors: (json['authors'] as List?)?.map((e) => AuthorDto.fromJson(e)).toList() ?? [],
      keywords: (json['keywords'] as List?)?.map((e) => KeywordDto.fromJson(e)).toList() ?? [],
    );
  }
}

class JournalDto {
  final String id;
  final String name;

  JournalDto({required this.id, required this.name});

  factory JournalDto.fromJson(Map<String, dynamic> json) {
    return JournalDto(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class AuthorDto {
  final String id;
  final String name;
  final String? affiliation;
  final int authorOrder;

  AuthorDto({
    required this.id,
    required this.name,
    this.affiliation,
    required this.authorOrder,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) {
    return AuthorDto(
      id: json['id'],
      name: json['name'] ?? '',
      affiliation: json['affiliation'],
      authorOrder: json['authorOrder'] ?? 0,
    );
  }
}

class KeywordDto {
  final String id;
  final String term;
  final double? relevanceScore;

  KeywordDto({
    required this.id,
    required this.term,
    this.relevanceScore,
  });

  factory KeywordDto.fromJson(Map<String, dynamic> json) {
    return KeywordDto(
      id: json['id'],
      term: json['term'] ?? '',
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble(),
    );
  }
}
