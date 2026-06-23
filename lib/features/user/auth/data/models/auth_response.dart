import 'dart:convert';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String fullName;
  final int role;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory AuthResponse.fromJson(dynamic jsonInput) {
    Map<String, dynamic> jsonMap;
    if (jsonInput is String) {
      try {
        jsonMap = jsonDecode(jsonInput) as Map<String, dynamic>;
      } catch (_) {
        jsonMap = {};
      }
    } else if (jsonInput is Map<String, dynamic>) {
      jsonMap = jsonInput;
    } else {
      jsonMap = {};
    }

    final data = (jsonMap['data'] is Map<String, dynamic>) ? jsonMap['data'] : jsonMap;
    final token = data['accessToken'] ?? data['token'] ?? '';
    
    Map<String, dynamic> decoded = {};
    if (token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          String payload = parts[1];
          payload = payload.replaceAll('-', '+').replaceAll('_', '/');
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final bytes = base64.decode(payload);
          decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        }
      } catch (_) {
        // Ignored, fallback to response body fields
      }
    }

    final userId = data['userId'] ?? data['id'] ??
        decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
        decoded['nameid'] ??
        decoded['sub'] ?? '';

    final email = data['email'] ??
        decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
        decoded['email'] ?? '';

    final rawRole = data['role'] ??
        decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        decoded['role'] ??
        '';

    int roleVal = 0;
    if (rawRole is int) {
      roleVal = rawRole;
    } else if (rawRole is String) {
      final roleStr = rawRole.toLowerCase();
      if (roleStr == 'admin') {
        roleVal = 3;
      } else if (roleStr == 'student') {
        roleVal = 2;
      } else if (roleStr == 'lecturer') {
        roleVal = 1;
      } else if (roleStr == 'researcher') {
        roleVal = 0;
      } else {
        roleVal = int.tryParse(roleStr) ?? 0;
      }
    }

    final fullName = data['fullName'] ?? data['name'] ??
        decoded['unique_name'] ??
        decoded['name'] ??
        '';

    return AuthResponse(
      accessToken: token,
      refreshToken: data['refreshToken'] ?? '',
      userId: userId,
      email: email,
      fullName: fullName,
      role: roleVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }
}
