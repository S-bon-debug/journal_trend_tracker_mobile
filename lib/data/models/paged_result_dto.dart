class PagedResultDto<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedResultDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResultDto.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PagedResultDto<T>(
      items: (json['items'] as List).map((i) => fromJsonT(i)).toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
