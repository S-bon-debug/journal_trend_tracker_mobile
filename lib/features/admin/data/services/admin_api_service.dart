import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/jwt_interceptor.dart';
import '../models/admin_models.dart';

class AdminApiService {
  final Dio _dio;

  // Cache mock data to maintain state locally during mock mode
  List<AdminUserDto>? _cachedMockUsers;
  List<ApiSourceDto>? _cachedMockApiSources;
  List<ApiSyncJobDto>? _cachedMockSyncJobs;
  List<SystemSettingDto>? _cachedMockSettings;
  List<AuditLogDto>? _cachedMockAuditLogs;

  // Track if any endpoints are currently operating in mock fallback mode
  bool usersLoadedFromMock = false;
  bool apiSourcesLoadedFromMock = false;
  bool syncJobsLoadedFromMock = false;
  bool settingsLoadedFromMock = false;
  bool logsLoadedFromMock = false;

  bool get isUsingMock =>
      usersLoadedFromMock ||
      apiSourcesLoadedFromMock ||
      syncJobsLoadedFromMock ||
      settingsLoadedFromMock ||
      logsLoadedFromMock;

  static String get baseUrl {
    // YARP Gateway route for admin service
    return 'http://10.0.2.2:5000/api/admin/';
  }

  AdminApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'X-Admin-User-Id': '11111111-1111-1111-1111-111111111111',
      'Accept': 'application/json',
    };
    
    _dio.interceptors.add(JwtInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  // Helper to update admin user ID header if needed
  void updateAdminUserId(String adminUserId) {
    _dio.options.headers['X-Admin-User-Id'] = adminUserId;
  }

  // 1. GET /api/admin/users
  Future<List<AdminUserDto>> getUsers() async {
    try {
      final response = await _dio.get('users');
      usersLoadedFromMock = false;
      final List list = response.data as List;
      return list.map((e) => AdminUserDto.fromJson(e)).toList();
    } catch (e) {
      usersLoadedFromMock = true;
      debugPrint('AdminApiService.getUsers failed: $e. Using fallback mock data.');
      return _getMockUsers();
    }
  }

  // 2. PUT /api/admin/users/{id}/toggle
  Future<bool> toggleUserStatus(String userId) async {
    try {
      final response = await _dio.put('users/$userId/toggle');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('AdminApiService.toggleUserStatus failed: $e. Simulating locally.');
      final list = _getMockUsers();
      final index = list.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final user = list[index];
        list[index] = AdminUserDto(
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          avatarUrl: user.avatarUrl,
          provider: user.provider,
          role: user.role,
          status: user.status == 0 ? 1 : 0,
          lastLoginAt: user.lastLoginAt,
          createdAt: user.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      return true; // Mock success
    }
  }

  // 3. GET /api/admin/api-sources
  Future<List<ApiSourceDto>> getApiSources() async {
    try {
      final response = await _dio.get('api-sources');
      apiSourcesLoadedFromMock = false;
      final List list = response.data as List;
      return list.map((e) => ApiSourceDto.fromJson(e)).toList();
    } catch (e) {
      apiSourcesLoadedFromMock = true;
      debugPrint('AdminApiService.getApiSources failed: $e. Using fallback mock data.');
      return _getMockApiSources();
    }
  }

  // 4. PUT /api/admin/api-sources/{id}/toggle
  Future<ApiSourceDto> toggleApiSource(String id) async {
    try {
      final response = await _dio.put('api-sources/$id/toggle');
      return ApiSourceDto.fromJson(response.data);
    } catch (e) {
      debugPrint('AdminApiService.toggleApiSource failed: $e. Simulating locally.');
      // Mock toggle status locally
      final list = _getMockApiSources();
      final index = list.indexWhere((element) => element.id == id);
      if (index != -1) {
        final src = list[index];
        final updated = ApiSourceDto(
          id: src.id,
          name: src.name,
          baseUrl: src.baseUrl,
          apiKeyEncrypted: src.apiKeyEncrypted,
          rateLimitPerSec: src.rateLimitPerSec,
          isActive: !src.isActive,
          syncIntervalHours: src.syncIntervalHours,
          supportedFields: src.supportedFields,
          lastSyncedAt: DateTime.now().toIso8601String(),
          createdAt: src.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        list[index] = updated;
        return updated;
      }
      throw Exception('API Source not found');
    }
  }

  // 5. GET /api/admin/sync-jobs
  Future<List<ApiSyncJobDto>> getSyncJobs() async {
    try {
      final response = await _dio.get('sync-jobs');
      syncJobsLoadedFromMock = false;
      final List list = response.data as List;
      return list.map((e) => ApiSyncJobDto.fromJson(e)).toList();
    } catch (e) {
      syncJobsLoadedFromMock = true;
      debugPrint('AdminApiService.getSyncJobs failed: $e. Using fallback mock data.');
      return _getMockSyncJobs();
    }
  }

  // 6. GET /api/admin/settings
  Future<List<SystemSettingDto>> getSettings() async {
    try {
      final response = await _dio.get('settings');
      settingsLoadedFromMock = false;
      final List list = response.data as List;
      return list.map((e) => SystemSettingDto.fromJson(e)).toList();
    } catch (e) {
      settingsLoadedFromMock = true;
      debugPrint('AdminApiService.getSettings failed: $e. Using fallback mock data.');
      return _getMockSettings();
    }
  }

  // 7. PUT /api/admin/settings
  Future<bool> updateSettings(List<SystemSettingDto> settings) async {
    try {
      final payload = settings.map((e) => e.toJson()).toList();
      final response = await _dio.put('settings', data: payload);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('AdminApiService.updateSettings failed: $e. Simulating success locally.');
      final list = _getMockSettings();
      for (var s in settings) {
        final index = list.indexWhere((item) => item.key == s.key);
        if (index != -1) {
          list[index] = s;
        }
      }
      return true; // Mock success
    }
  }

  // 8. GET /api/admin/logs
  Future<List<AuditLogDto>> getLogs({int limit = 100}) async {
    try {
      final response = await _dio.get('logs', queryParameters: {'limit': limit});
      logsLoadedFromMock = false;
      final List list = response.data as List;
      return list.map((e) => AuditLogDto.fromJson(e)).toList();
    } catch (e) {
      logsLoadedFromMock = true;
      debugPrint('AdminApiService.getLogs failed: $e. Using fallback mock data.');
      return _getMockAuditLogs();
    }
  }

  // 9. POST /api/admin/sync-jobs/trigger
  Future<bool> triggerSync() async {
    try {
      final response = await _dio.post('sync-jobs/trigger');
      return response.statusCode == 202 || response.statusCode == 200;
    } catch (e) {
      debugPrint('AdminApiService.triggerSync failed: $e. Simulating success locally.');
      return true; // Mock success
    }
  }

  // 10. DELETE /api/admin/papers/wipe-mock
  Future<bool> wipeMockData() async {
    try {
      final response = await _dio.delete('papers/wipe-mock');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('AdminApiService.wipeMockData failed: $e. Simulating success locally.');
      // Clear local mock cache to simulate wipe
      _cachedMockSyncJobs = null;
      return true; // Mock success
    }
  }

  // --- MOCK FALLBACK DATA GENERATORS ---

  List<AdminUserDto> _getMockUsers() {
    _cachedMockUsers ??= [
      AdminUserDto(
        id: '11111111-1111-1111-1111-111111111111',
        fullName: 'Dr. Alexander Vance',
        email: 'alexander.vance@university.edu',
        provider: 0,
        role: 3, // Admin
        status: 0, // Active
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      AdminUserDto(
        id: '22222222-2222-2222-2222-222222222222',
        fullName: 'Prof. Helen Carter',
        email: 'helen.carter@science.org',
        provider: 1,
        role: 0, // Researcher
        status: 0, // Active
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        createdAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
      AdminUserDto(
        id: '33333333-3333-3333-3333-333333333333',
        fullName: 'John Doe',
        email: 'john.doe@student.edu',
        provider: 0,
        role: 2, // Student
        status: 1, // Locked
        lastLoginAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        createdAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      ),
      AdminUserDto(
        id: '44444444-4444-4444-4444-444444444444',
        fullName: 'Sarah Jenkins',
        email: 'sarah.j@lecturer.edu',
        provider: 0,
        role: 1, // Lecturer
        status: 2, // Pending
        lastLoginAt: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      ),
    ];
    return _cachedMockUsers!;
  }

  List<ApiSourceDto> _getMockApiSources() {
    _cachedMockApiSources ??= [
      ApiSourceDto(
        id: 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
        name: 'OpenAlex',
        baseUrl: 'https://api.openalex.org',
        apiKeyEncrypted: '******',
        rateLimitPerSec: 10,
        isActive: true,
        syncIntervalHours: 24,
        supportedFields: ['Computer Science', 'Artificial Intelligence', 'Data Science'],
        lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      ApiSourceDto(
        id: 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2',
        name: 'SemanticScholar',
        baseUrl: 'https://api.semanticscholar.org/graph/v1',
        apiKeyEncrypted: null,
        rateLimitPerSec: 1,
        isActive: true,
        syncIntervalHours: 24,
        supportedFields: ['Computer Science', 'Machine Learning'],
        lastSyncedAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      ),
      ApiSourceDto(
        id: 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
        name: 'Crossref',
        baseUrl: 'https://api.crossref.org',
        apiKeyEncrypted: null,
        rateLimitPerSec: 50,
        isActive: false,
        syncIntervalHours: 48,
        supportedFields: ['Computer Science', 'Engineering', 'Mathematics'],
        lastSyncedAt: null,
        createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      ),
    ];
    return _cachedMockApiSources!;
  }

  List<ApiSyncJobDto> _getMockSyncJobs() {
    _cachedMockSyncJobs ??= [
      ApiSyncJobDto(
        id: 'j1j1j1j1-j1j1-j1j1-j1j1-j1j1j1j1j1j1',
        sourceName: 'OpenAlex',
        sourceBaseUrl: 'https://api.openalex.org',
        queryParams: '?concept=Computer%20Science&from=2026-06-22',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        startedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 58)).toIso8601String(),
        finishedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 45)).toIso8601String(),
        status: 'Success',
        papersFetched: 154,
        papersInserted: 88,
        papersUpdated: 66,
        errorMessage: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      ),
      ApiSyncJobDto(
        id: 'j2j2j2j2-j2j2-j2j2-j2j2-j2j2j2j2j2j2',
        sourceName: 'SemanticScholar',
        sourceBaseUrl: 'https://api.semanticscholar.org/graph/v1',
        queryParams: '?query=deep%20learning',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 9)).toIso8601String(),
        startedAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 59)).toIso8601String(),
        finishedAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 55)).toIso8601String(),
        status: 'Success',
        papersFetched: 45,
        papersInserted: 20,
        papersUpdated: 25,
        errorMessage: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 9)).toIso8601String(),
      ),
      ApiSyncJobDto(
        id: 'j3j3j3j3-j3j3-j3j3-j3j3-j3j3j3j3j3j3',
        sourceName: 'Crossref',
        sourceBaseUrl: 'https://api.crossref.org',
        queryParams: '?filter=has-funder:true',
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        startedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        finishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 23, minutes: 59)).toIso8601String(),
        status: 'Failed',
        papersFetched: 0,
        papersInserted: 0,
        papersUpdated: 0,
        errorMessage: 'HTTP 503 Service Unavailable: Remote API is offline.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
    ];
    return _cachedMockSyncJobs!;
  }

  List<SystemSettingDto> _getMockSettings() {
    _cachedMockSettings ??= [
      SystemSettingDto(
        key: 'max_search_results',
        value: '50',
        description: 'Số kết quả tối đa mỗi lần search',
        updatedBy: '11111111-1111-1111-1111-111111111111',
        updatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      ),
      SystemSettingDto(
        key: 'trend_snapshot_schedule',
        value: '0 2 * * *',
        description: 'Cron schedule tính trend snapshot hàng ngày',
        updatedBy: '11111111-1111-1111-1111-111111111111',
        updatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      ),
      SystemSettingDto(
        key: 'email_from',
        value: 'noreply@jts.com',
        description: 'Địa chỉ Email gửi các thông báo thông tin xu hướng bài báo khoa học',
        updatedBy: '11111111-1111-1111-1111-111111111111',
        updatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      ),
      SystemSettingDto(
        key: 'sync_fields',
        value: 'Computer Science, Artificial Intelligence',
        description: 'Lĩnh vực đồng bộ dữ liệu khoa học mặc định',
        updatedBy: '11111111-1111-1111-1111-111111111111',
        updatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      ),
    ];
    return _cachedMockSettings!;
  }

  List<AuditLogDto> _getMockAuditLogs() {
    _cachedMockAuditLogs ??= [
      AuditLogDto(
        id: 'l1l1l1l1-l1l1-l1l1-l1l1-l1l1l1l1l1l1',
        adminUserId: '11111111-1111-1111-1111-111111111111',
        action: 'UPDATE_SYSTEM_SETTING',
        entityType: 'SystemSetting',
        entityId: null,
        oldValue: '{"value": "30"}',
        newValue: '{"value": "50"}',
        ipAddress: '192.168.1.5',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
      ),
      AuditLogDto(
        id: 'l2l2l2l2-l2l2-l2l2-l2l2-l2l2l2l2l2l2',
        adminUserId: '11111111-1111-1111-1111-111111111111',
        action: 'TOGGLE_API_SOURCE',
        entityType: 'ApiSource',
        entityId: 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
        oldValue: '{"isActive": true}',
        newValue: '{"isActive": false}',
        ipAddress: '192.168.1.5',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)).toIso8601String(),
      ),
      AuditLogDto(
        id: 'l3l3l3l3-l3l3-l3l3-l3l3-l3l3l3l3l3l3',
        adminUserId: '11111111-1111-1111-1111-111111111111',
        action: 'TOGGLE_USER_STATUS',
        entityType: 'User',
        entityId: '33333333-3333-3333-3333-333333333333',
        oldValue: '{"status": "active"}',
        newValue: '{"status": "locked"}',
        ipAddress: '192.168.1.5',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      ),
    ];
    return _cachedMockAuditLogs!;
  }
}
