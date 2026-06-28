import 'package:dio/dio.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../models/user_models.dart';

class UserApiService {
  final Dio _dio;

  static String get baseUrl => '${ApiConfig.userUrl}/api/';

  UserApiService({Dio? dio}) : _dio = dio ?? DioClient.dio;

  // 1. GET /api/users/profile
  Future<UserProfileDto> getProfile() async {
    try {
      final response = await _dio.get('${ApiConfig.userUrl}/api/users/profile');
      return UserProfileDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final storage = await TokenStorage.instance;
        final userId = storage.getUserId() ?? '';
        return UserProfileDto(
          userId: userId,
          bio: '',
          institution: '',
          researchFields: [],
          websiteUrl: '',
        );
      }
      throw Exception('Failed to load user profile: ${e.message}');
    }
  }

  // 2. GET /api/users/bookmarks
  Future<List<BookmarkDto>> getBookmarks() async {
    try {
      final response = await _dio.get('${ApiConfig.userUrl}/api/users/bookmarks');
      final List list = response.data as List;
      return list.map((e) => BookmarkDto.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load bookmarks: ${e.message}');
    }
  }

  // 3. GET /api/users/follows
  Future<List<FollowDto>> getFollows() async {
    try {
      final response = await _dio.get('${ApiConfig.userUrl}/api/users/follows');
      final List list = response.data as List;
      return list.map((e) => FollowDto.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load follows: ${e.message}');
    }
  }

  // 4. GET /api/users/notifications
  Future<List<NotificationDto>> getNotifications() async {
    try {
      final response = await _dio.get('${ApiConfig.userUrl}/api/users/notifications');
      final List list = response.data as List;
      return list.map((e) => NotificationDto.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load notifications: ${e.message}');
    }
  }

  // 5. GET Identity Account details (Cross-service call)
  Future<UserAccountDto> getAccountDetails(String userId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.identityUrl}/api/identity/users/$userId',
      );
      return UserAccountDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load identity account: ${e.message}');
    }
  }
}
