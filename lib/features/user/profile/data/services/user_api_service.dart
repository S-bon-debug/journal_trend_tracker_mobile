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

  // 6. PUT /api/users/profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? bio,
    String? institution,
    List<String>? researchFields,
    String? websiteUrl,
  }) async {
    try {
      final payload = {
        'fullName': fullName,
        'email': email,
        'bio': bio,
        'institution': institution,
        'researchFields': researchFields,
        'websiteUrl': websiteUrl,
      };
      await _dio.put(
        '${ApiConfig.userUrl}/api/users/profile',
        data: payload,
      );
    } on DioException catch (e) {
      throw Exception('Failed to update user profile: ${e.response?.data ?? e.message}');
    }
  }

  // 7. POST /api/users/bookmarks
  Future<void> addBookmark({
    required String entityType,
    required String entityId,
    required String entityTitle,
    String? note,
  }) async {
    try {
      final payload = {
        'entityType': entityType,
        'entityId': entityId,
        'entityTitle': entityTitle,
        'note': note,
      };
      await _dio.post(
        '${ApiConfig.userUrl}/api/users/bookmarks',
        data: payload,
      );
    } on DioException catch (e) {
      throw Exception('Failed to add bookmark: ${e.response?.data ?? e.message}');
    }
  }

  // 8. DELETE /api/users/bookmarks/{id}
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _dio.delete(
        '${ApiConfig.userUrl}/api/users/bookmarks/$bookmarkId',
      );
    } on DioException catch (e) {
      throw Exception('Failed to delete bookmark: ${e.response?.data ?? e.message}');
    }
  }

  // 9. POST /api/users/follows/keywords/{keywordId}
  Future<void> followKeyword(String keywordId) async {
    try {
      await _dio.post(
        '${ApiConfig.userUrl}/api/users/follows/keywords/$keywordId',
      );
    } on DioException catch (e) {
      throw Exception('Failed to follow keyword: ${e.response?.data ?? e.message}');
    }
  }

  // 10. POST /api/users/follows/journals/{journalId}
  Future<void> followJournal(String journalId) async {
    try {
      await _dio.post(
        '${ApiConfig.userUrl}/api/users/follows/journals/$journalId',
      );
    } on DioException catch (e) {
      throw Exception('Failed to follow journal: ${e.response?.data ?? e.message}');
    }
  }

  // 11. DELETE /api/users/follows/{id}
  Future<void> unfollow(String followId) async {
    try {
      await _dio.delete(
        '${ApiConfig.userUrl}/api/users/follows/$followId',
      );
    } on DioException catch (e) {
      throw Exception('Failed to unfollow: ${e.response?.data ?? e.message}');
    }
  }

  // 12. PUT /api/users/notifications/{id}/read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put(
        '${ApiConfig.userUrl}/api/users/notifications/$notificationId/read',
      );
    } on DioException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.response?.data ?? e.message}');
    }
  }

  // 13. PUT /api/users/notifications/read-all
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put(
        '${ApiConfig.userUrl}/api/users/notifications/read-all',
      );
    } on DioException catch (e) {
      throw Exception('Failed to mark all notifications as read: ${e.response?.data ?? e.message}');
    }
  }
}
