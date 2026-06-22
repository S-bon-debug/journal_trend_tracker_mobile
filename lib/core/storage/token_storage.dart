import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';
  static const String _userFullNameKey = 'user_fullname';

  static TokenStorage? _instance;
  late final SharedPreferences _prefs;

  TokenStorage._(this._prefs);

  static Future<TokenStorage> get instance async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = TokenStorage._(prefs);
    }
    return _instance!;
  }

  // Tokens
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userRoleKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userFullNameKey);
  }

  // Profile data
  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  Future<void> saveUserRole(int role) async {
    await _prefs.setInt(_userRoleKey, role);
  }

  int? getUserRole() {
    return _prefs.getInt(_userRoleKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(_userEmailKey, email);
  }

  String? getUserEmail() {
    return _prefs.getString(_userEmailKey);
  }

  Future<void> saveUserFullName(String name) async {
    await _prefs.setString(_userFullNameKey, name);
  }

  String? getUserFullName() {
    return _prefs.getString(_userFullNameKey);
  }

  bool hasValidToken() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
