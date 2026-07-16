import 'package:dio/dio.dart';
import '../../../../core/network/api_config.dart';
import '../models/trend_models.dart';

class TrendRepository {
  final Dio dio;

  final String baseUrl = '${ApiConfig.trendUrl}/api/trends';
  
  TrendRepository({required this.dio});

  // 1. GET /api/trends/overview
  Future<TrendOverviewDto> getOverview() async {
    final response = await dio.get('$baseUrl/overview');
    return TrendOverviewDto.fromJson(response.data);
  }

  // 2. GET /api/trends/hot-topics?top=5
  Future<List<TopTopicDto>> getHotTopics() async {
    final response = await dio.get('$baseUrl/hot-topics?top=5');
    final list = response.data as List;
    return list.map((e) => TopTopicDto.fromJson(e)).toList();
  }

  // 3. GET /api/trends/top-keywords?top=10
  Future<List<TopKeywordDto>> getTopKeywords() async {
    final response = await dio.get('$baseUrl/top-keywords?top=10');
    final list = response.data as List;
    return list.map((e) => TopKeywordDto.fromJson(e)).toList();
  }

  // 4. GET /api/trends/keywords/{id}
  Future<KeywordTrendDto> getKeywordTrend(String keywordId) async {
    final response = await dio.get('$baseUrl/keywords/$keywordId');
    return KeywordTrendDto.fromJson(response.data);
  }

  // GET /api/trends/topics/{id}
  Future<TopicTrendDto> getTopicTrend(String topicId) async {
    final response = await dio.get('$baseUrl/topics/$topicId');
    return TopicTrendDto.fromJson(response.data);
  }

  // GET /api/trends/authors/{id}
  Future<AuthorTrendDto> getAuthorTrend(String authorId) async {
    final response = await dio.get('$baseUrl/authors/$authorId');
    return AuthorTrendDto.fromJson(response.data);
  }

  // 5. GET /api/trends/reports/export?keywordId=xxx
  Future<String> downloadReport(String keywordId, String savePath) async {
    // API Export yêu cầu xác thực JWT, cần Dio có gắn Token Header
    await dio.download(
      '$baseUrl/reports/export?keywordId=$keywordId',
      savePath,
    );
    return savePath;
  }

  // Hỗ trợ Web: tải data dưới dạng bytes để gọi trình duyệt lưu file
  Future<List<int>> getReportBytes(String keywordId) async {
    final response = await dio.get(
      '$baseUrl/reports/export?keywordId=$keywordId',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  // 6. GET /api/trends/journals/{id}
  Future<JournalTrendDto> getJournalTrend(String journalId) async {
    final response = await dio.get('$baseUrl/journals/$journalId');
    return JournalTrendDto.fromJson(response.data);
  }

  // 7. GET /api/trends/top-journals?top=10
  Future<List<JournalTrendSummaryDto>> getTopJournals() async {
    final response = await dio.get('$baseUrl/top-journals?top=10');
    final list = response.data as List;
    return list.map((e) => JournalTrendSummaryDto.fromJson(e)).toList();
  }

  // 8. GET /api/trends/top-authors?top=10
  Future<List<TopAuthorDto>> getTopAuthors() async {
    final response = await dio.get('$baseUrl/top-authors?top=10');
    final list = response.data as List;
    return list.map((e) => TopAuthorDto.fromJson(e)).toList();
  }
}
