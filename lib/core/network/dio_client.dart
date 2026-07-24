import 'package:dio/dio.dart';
import 'api_config.dart';
import 'jwt_interceptor.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${ApiConfig.identityUrl}/api/',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _dio.interceptors.add(JwtInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  static Dio get dio {
    _instance ??= DioClient._();
    return _instance!._dio;
  }
}
