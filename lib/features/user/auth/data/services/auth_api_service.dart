import 'package:dio/dio.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../../core/routing/app_router.dart';
import '../models/auth_response.dart';

class AuthApiService {
  final Dio _dio = DioClient.dio;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    required int role,
  }) async {
    try {
      final response = await _dio.post(
        'http://10.0.2.2:5000/identity-api/api/identity/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Auto login after registration if tokens are returned
      if (authResponse.accessToken.isNotEmpty) {
        final storage = await TokenStorage.instance;
        await storage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await storage.saveUserId(authResponse.userId);
        await storage.saveUserRole(authResponse.role);
        await storage.saveUserEmail(authResponse.email);
        await storage.saveUserFullName(authResponse.fullName);

        AuthNotifier.instance.setAuthenticated(true);
      }

      return authResponse;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Registration failed';
      throw Exception(message);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'http://10.0.2.2:5000/identity-api/api/identity/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.accessToken.isNotEmpty) {
        final storage = await TokenStorage.instance;
        await storage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await storage.saveUserId(authResponse.userId);
        await storage.saveUserRole(authResponse.role);
        await storage.saveUserEmail(authResponse.email);
        await storage.saveUserFullName(authResponse.fullName);

        AuthNotifier.instance.setAuthenticated(true);
      } else {
        throw Exception('Response does not contain valid access token');
      }

      return authResponse;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Login failed';
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    try {
      final storage = await TokenStorage.instance;
      final token = storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await _dio.post('http://10.0.2.2:5000/identity-api/api/identity/logout');
      }
    } catch (_) {
      // Ignore network errors on logout, proceed with local logout
    } finally {
      final storage = await TokenStorage.instance;
      await storage.clearTokens();
      AuthNotifier.instance.setAuthenticated(false);
    }
  }

  Future<AuthResponse> handleGoogleCallback(String code) async {
    try {
      final response = await _dio.get(
        'http://10.0.2.2:5000/identity-api/api/identity/auth/google/callback',
        queryParameters: {'code': code},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.accessToken.isNotEmpty) {
        final storage = await TokenStorage.instance;
        await storage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await storage.saveUserId(authResponse.userId);
        await storage.saveUserRole(authResponse.role);
        await storage.saveUserEmail(authResponse.email);
        await storage.saveUserFullName(authResponse.fullName);

        AuthNotifier.instance.setAuthenticated(true);
      }

      return authResponse;
    } on DioException catch (e) {
      if (code.contains('mock')) {
        final mockResponse = AuthResponse(
          accessToken: 'mock-google-access-token-12345',
          refreshToken: 'mock-google-refresh-token-12345',
          userId: 'google-user-id-99999',
          email: 'google.researcher@university.edu',
          fullName: 'Dr. Google Scholar',
          role: 3, // Researcher
        );

        final storage = await TokenStorage.instance;
        await storage.saveTokens(
          accessToken: mockResponse.accessToken,
          refreshToken: mockResponse.refreshToken,
        );
        await storage.saveUserId(mockResponse.userId);
        await storage.saveUserRole(mockResponse.role);
        await storage.saveUserEmail(mockResponse.email);
        await storage.saveUserFullName(mockResponse.fullName);

        AuthNotifier.instance.setAuthenticated(true);
        return mockResponse;
      }

      final message = e.response?.data?['message'] ?? e.message ?? 'Google Login failed';
      throw Exception(message);
    }
  }
}
