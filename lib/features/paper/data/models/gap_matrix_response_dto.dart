class GapMatrixResponseDto {
  final String matrixId;
  final List<String> cores;
  final List<GapMatrixRowDto> matrix;
  final String summary;
  final List<GapMatrixPaperDto> papersAnalyzed;
  final DateTime createdAt;

  GapMatrixResponseDto({
    required this.matrixId,
    required this.cores,
    required this.matrix,
    required this.summary,
    required this.papersAnalyzed,
    required this.createdAt,
  });

  factory GapMatrixResponseDto.fromJson(Map<String, dynamic> json) {
    return GapMatrixResponseDto(
      matrixId: json['matrixId'] as String,
      cores: (json['cores'] as List).map((e) => e as String).toList(),
      matrix: (json['matrix'] as List)
          .map((e) => GapMatrixRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String,
      papersAnalyzed: (json['papersAnalyzed'] as List)
          .map((e) => GapMatrixPaperDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GapMatrixRowDto {
  final String paper;
  final List<bool> ticks;

  GapMatrixRowDto({
    required this.paper,
    required this.ticks,
  });

  factory GapMatrixRowDto.fromJson(Map<String, dynamic> json) {
    return GapMatrixRowDto(
      paper: json['paper'] as String,
      ticks: (json['ticks'] as List).map((e) => e as bool).toList(),
    );
  }
}

class GapMatrixPaperDto {
  final String id;
  final String title;
  final String source;
  final bool hasFullText;
  final String? pdfUrl;

  GapMatrixPaperDto({
    required this.id,
    required this.title,
    required this.source,
    required this.hasFullText,
    this.pdfUrl,
  });

  factory GapMatrixPaperDto.fromJson(Map<String, dynamic> json) {
    return GapMatrixPaperDto(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String,
      hasFullText: json['hasFullText'] as bool,
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}
