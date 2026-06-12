class TrendOverviewDto {
  final int totalPapers;
  final int totalKeywords;
  final int totalJournals;
  final int totalAuthors;

  TrendOverviewDto({
    required this.totalPapers,
    required this.totalKeywords,
    required this.totalJournals,
    required this.totalAuthors,
  });

  factory TrendOverviewDto.fromJson(Map<String, dynamic> json) {
    return TrendOverviewDto(
      totalPapers: json['totalPapers'] ?? 0,
      totalKeywords: json['totalKeywords'] ?? 0,
      totalJournals: json['totalJournals'] ?? 0,
      totalAuthors: json['totalAuthors'] ?? 0,
    );
  }
}

class YearlyStatDto {
  final int year;
  final int paperCount;

  YearlyStatDto({required this.year, required this.paperCount});

  factory YearlyStatDto.fromJson(Map<String, dynamic> json) {
    return YearlyStatDto(
      year: json['year'] ?? 0,
      paperCount: json['paperCount'] ?? 0,
    );
  }
}

class TopKeywordDto {
  final String keywordId;
  final String keywordTerm;

  TopKeywordDto({required this.keywordId, required this.keywordTerm});

  factory TopKeywordDto.fromJson(Map<String, dynamic> json) {
    return TopKeywordDto(
      keywordId: json['keywordId'] ?? '',
      keywordTerm: json['keywordTerm'] ?? '',
    );
  }
}

class HotTopicDto {
  final String query;
  final int searchCount;

  HotTopicDto({required this.query, required this.searchCount});

  factory HotTopicDto.fromJson(Map<String, dynamic> json) {
    return HotTopicDto(
      query: json['query'] ?? '',
      searchCount: json['searchCount'] ?? 0,
    );
  }
}

class KeywordTrendDto {
  final String keywordId;
  final String keywordTerm;
  final List<YearlyStatDto> stats;

  KeywordTrendDto({
    required this.keywordId,
    required this.keywordTerm,
    required this.stats,
  });

  factory KeywordTrendDto.fromJson(Map<String, dynamic> json) {
    var statsList = json['stats'] as List? ?? [];
    return KeywordTrendDto(
      keywordId: json['keywordId'] ?? '',
      keywordTerm: json['keywordTerm'] ?? '',
      stats: statsList.map((e) => YearlyStatDto.fromJson(e)).toList(),
    );
  }
}

class TopAuthorDto {
  final String authorId;
  final String name;
  final String? affiliation;
  final int paperCount;

  TopAuthorDto({
    required this.authorId,
    required this.name,
    this.affiliation,
    required this.paperCount,
  });

  factory TopAuthorDto.fromJson(Map<String, dynamic> json) {
    return TopAuthorDto(
      authorId: json['authorId'] ?? '',
      name: json['name'] ?? '',
      affiliation: json['affiliation'],
      paperCount: json['paperCount'] ?? 0,
    );
  }
}

class JournalTrendSummaryDto {
  final String journalId;
  final String journalName;
  final int paperCount;
  final int year;

  JournalTrendSummaryDto({
    required this.journalId,
    required this.journalName,
    required this.paperCount,
    required this.year,
  });

  factory JournalTrendSummaryDto.fromJson(Map<String, dynamic> json) {
    return JournalTrendSummaryDto(
      journalId: json['journalId'] ?? '',
      journalName: json['journalName'] ?? '',
      paperCount: json['paperCount'] ?? 0,
      year: json['year'] ?? 0,
    );
  }
}

class JournalTrendDto {
  final String journalId;
  final String journalName;
  final List<YearlyStatDto> stats;

  JournalTrendDto({
    required this.journalId,
    required this.journalName,
    required this.stats,
  });

  factory JournalTrendDto.fromJson(Map<String, dynamic> json) {
    var statsList = json['stats'] as List? ?? [];
    return JournalTrendDto(
      journalId: json['journalId'] ?? '',
      journalName: json['journalName'] ?? '',
      stats: statsList.map((e) => YearlyStatDto.fromJson(e)).toList(),
    );
  }
}
