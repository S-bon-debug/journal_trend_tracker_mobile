import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/storage/token_storage.dart';
import '../models/paged_result_dto.dart';
import '../models/paper_summary_dto.dart';
import '../models/paper_detail_dto.dart';
import '../models/paper_filter_dto.dart';

class PaperApiService {
  // If running on Android emulator, use 10.0.2.2 to access host localhost.
  // Otherwise (iOS simulator, Web, Desktop), use localhost.
  static String get baseUrl {
    // Deployed Backend (Render API Gateway)
    return 'http://10.0.2.2:5000/api';

    // Local Backend (Direct Service)
    // if (!kIsWeb && Platform.isAndroid) {
    //   return 'http://10.0.2.2:5145/api';
    // }
    // return 'http://localhost:5145/api';
  }

  Future<PagedResultDto<PaperSummaryDto>> searchPapers(PaperFilterDto filter) async {
    final uri = Uri.parse('$baseUrl/papers').replace(queryParameters: filter.toQueryParameters());
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        return PagedResultDto.fromJson(
          jsonMap,
          (item) => PaperSummaryDto.fromJson(item as Map<String, dynamic>),
        );
      } else {
        throw Exception('Failed to load papers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching papers: $e');
    }
  }

  Future<PaperDetailDto> getPaperDetail(String id) async {
    final uri = Uri.parse('$baseUrl/papers/$id');
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        return PaperDetailDto.fromJson(jsonMap);
      } else if (response.statusCode == 404) {
        throw Exception('Paper not found');
      } else {
        throw Exception('Failed to load paper details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching paper details: $e');
    }
  }
  Future<void> triggerSyncPapers() async {
    final uri = Uri.parse('http://10.0.2.2:5000/api/admin/sync-jobs/trigger');
    try {
      final storage = await TokenStorage.instance;
      final token = storage.getAccessToken();

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 202 || response.statusCode == 200) {
        print('✅ Đã ra lệnh đồng bộ thành công! Backend đang chạy ngầm kéo dữ liệu.');
      } else {
        throw Exception('Lỗi kích hoạt đồng bộ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi mạng: $e');
    }
  }
}
