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
    
    return AuthResponse(
      accessToken: data['accessToken'] ?? data['token'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
      userId: data['userId'] ?? data['id'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      role: data['role'] is int ? data['role'] : int.tryParse(data['role']?.toString() ?? '') ?? 0,
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
