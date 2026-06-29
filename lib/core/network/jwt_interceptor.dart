import 'package:dio/dio.dart';
import 'api_config.dart';
import '../storage/token_storage.dart';

class JwtInterceptor extends Interceptor {
  final Dio _refreshDio;

  JwtInterceptor({Dio? refreshDio}) : _refreshDio = refreshDio ?? Dio() {
    _refreshDio.options.baseUrl = '${ApiConfig.identityUrl}/api/';
    _refreshDio.options.connectTimeout = const Duration(seconds: 60);
    _refreshDio.options.receiveTimeout = const Duration(seconds: 60);
  }

  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _failedRequestsQueue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = await TokenStorage.instance;
    final token = storage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Attach X-User-Id fallback if required by other services during development
    final userId = storage.getUserId();
    if (userId != null && userId.isNotEmpty) {
      options.headers['X-User-Id'] = userId;
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Check if error is 401 and not already a retry or refresh call
    if (err.response?.statusCode == 401 && !requestOptions.path.contains('identity/refresh') && !requestOptions.path.contains('identity/login')) {
      final storage = await TokenStorage.instance;
      final refreshToken = storage.getRefreshToken();
      final accessToken = storage.getAccessToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        // Queue the request
        _failedRequestsQueue.add({
          'options': requestOptions,
          'handler': handler,
        });
        return;
      }

      _isRefreshing = true;

      try {
        final response = await _refreshDio.post(
          'identity/refresh',
          data: {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          final newAccessToken = data['accessToken'] ?? data['token'];
          final newRefreshToken = data['refreshToken'] ?? refreshToken;

          if (newAccessToken != null) {
            await storage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Re-execute current request
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            
            // Re-request using standard Dio option
            final dio = Dio(); // local simple dio to perform retry
            final retryUrl = requestOptions.path.startsWith('http')
                ? requestOptions.path
                : '${requestOptions.baseUrl}${requestOptions.path}';
            final retryResponse = await dio.request(
              retryUrl,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );
            
            handler.resolve(retryResponse);

            // Re-execute queued requests
            for (var request in _failedRequestsQueue) {
              final opt = request['options'] as RequestOptions;
              final hnd = request['handler'] as ErrorInterceptorHandler;
              
              opt.headers['Authorization'] = 'Bearer $newAccessToken';
              
              try {
                final queuedUrl = opt.path.startsWith('http')
                    ? opt.path
                    : '${opt.baseUrl}${opt.path}';
                final retryRes = await dio.request(
                  queuedUrl,
                  options: Options(
                    method: opt.method,
                    headers: opt.headers,
                  ),
                  data: opt.data,
                  queryParameters: opt.queryParameters,
                );
                hnd.resolve(retryRes);
              } catch (retryErr) {
                if (retryErr is DioException) {
                  hnd.next(retryErr);
                } else {
                  hnd.next(DioException(requestOptions: opt, error: retryErr));
                }
              }
            }
            _failedRequestsQueue.clear();
            return;
          }
        }
        
        // Refresh token failed, clear credentials and bubble error
        await storage.clearTokens();
      } catch (refreshErr) {
        await storage.clearTokens();
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }
}
