class PaperFilterDto {
  final String? keyword;
  final int? year;
  final String? journalId;
  final String? authorId;
  final String? source;
  final int page;
  final int pageSize;

  PaperFilterDto({
    this.keyword,
    this.year,
    this.journalId,
    this.authorId,
    this.source,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
    };

    if (keyword != null && keyword!.isNotEmpty) {
      params['Keyword'] = keyword!;
    }
    if (year != null) {
      params['Year'] = year.toString();
    }
    if (journalId != null && journalId!.isNotEmpty) {
      params['JournalId'] = journalId!;
    }
    if (authorId != null && authorId!.isNotEmpty) {
      params['AuthorId'] = authorId!;
    }
    if (source != null && source!.isNotEmpty) {
      params['Source'] = source!;
    }

    return params;
  }
}
