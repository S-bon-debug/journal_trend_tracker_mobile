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
  final int? forecastPaperCount;

  YearlyStatDto({required this.year, required this.paperCount, this.forecastPaperCount});

  factory YearlyStatDto.fromJson(Map<String, dynamic> json) {
    return YearlyStatDto(
      year: json['year'] ?? 0,
      paperCount: json['paperCount'] ?? 0,
      forecastPaperCount: json['forecastPaperCount'],
    );
  }
}

class TopKeywordDto {
  final String keywordId;
  final String keywordTerm;
  final String? trendStatus;

  TopKeywordDto({required this.keywordId, required this.keywordTerm, this.trendStatus});

  factory TopKeywordDto.fromJson(Map<String, dynamic> json) {
    return TopKeywordDto(
      keywordId: json['keywordId'] ?? '',
      keywordTerm: json['keywordTerm'] ?? '',
      trendStatus: json['trendStatus'],
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

class TopTopicDto {
  final String topicId;
  final String topicName;
  final int paperCount;
  final double? growthRate;
  final String? trendStatus;

  TopTopicDto({
    required this.topicId,
    required this.topicName,
    required this.paperCount,
    this.growthRate,
    this.trendStatus,
  });

  factory TopTopicDto.fromJson(Map<String, dynamic> json) {
    return TopTopicDto(
      topicId: json['topicId'] ?? '',
      topicName: json['topicName'] ?? '',
      paperCount: json['paperCount'] ?? 0,
      growthRate: json['growthRate']?.toDouble(),
      trendStatus: json['trendStatus'],
    );
  }
}

class TopicTrendDto {
  final String topicId;
  final String topicName;
  final List<YearlyStatDto> stats;

  TopicTrendDto({
    required this.topicId,
    required this.topicName,
    required this.stats,
  });

  factory TopicTrendDto.fromJson(Map<String, dynamic> json) {
    var statsList = json['stats'] as List? ?? [];
    return TopicTrendDto(
      topicId: json['topicId'] ?? '',
      topicName: json['topicName'] ?? '',
      stats: statsList.map((e) => YearlyStatDto.fromJson(e)).toList(),
    );
  }
}

class AuthorTrendDto {
  final String authorId;
  final String authorName;
  final List<YearlyStatDto> stats;

  AuthorTrendDto({
    required this.authorId,
    required this.authorName,
    required this.stats,
  });

  factory AuthorTrendDto.fromJson(Map<String, dynamic> json) {
    var statsList = json['stats'] as List? ?? [];
    return AuthorTrendDto(
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      stats: statsList.map((e) => YearlyStatDto.fromJson(e)).toList(),
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
  final String? trendStatus;

  TopAuthorDto({
    required this.authorId,
    required this.name,
    this.affiliation,
    required this.paperCount,
    this.trendStatus,
  });

  factory TopAuthorDto.fromJson(Map<String, dynamic> json) {
    return TopAuthorDto(
      authorId: json['authorId'] ?? '',
      name: json['name'] ?? '',
      affiliation: json['affiliation'],
      paperCount: json['paperCount'] ?? 0,
      trendStatus: json['trendStatus'],
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
