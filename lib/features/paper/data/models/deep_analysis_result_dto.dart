class DeepAnalysisResultDto {
  final String summary;
  final String methodology;
  final String findings;
  final String limitations;

  DeepAnalysisResultDto({
    required this.summary,
    required this.methodology,
    required this.findings,
    required this.limitations,
  });

  factory DeepAnalysisResultDto.fromJson(Map<String, dynamic> json) {
    return DeepAnalysisResultDto(
      summary: json['summary'] as String? ?? '',
      methodology: json['methodology'] as String? ?? '',
      findings: json['findings'] as String? ?? '',
      limitations: json['limitations'] as String? ?? '',
    );
  }
}
