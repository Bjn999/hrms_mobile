import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keySavedUsername = 'saved_username';
  static const String _keySavedPassword = 'saved_password';
  static const String _keyBaseUrl = 'custom_base_url';

  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // User Data Management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonStr = jsonEncode(userData);
    await _storage.write(key: _keyUserData, value: jsonStr);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final jsonStr = await _storage.read(key: _keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: _keyUserData);
  }

  // Biometrics Management
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  // Credentials for Fast Biometric Login
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _keySavedUsername, value: username);
    await _storage.write(key: _keySavedPassword, value: password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final username = await _storage.read(key: _keySavedUsername);
    final password = await _storage.read(key: _keySavedPassword);
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _keySavedUsername);
    await _storage.delete(key: _keySavedPassword);
  }

  // Dynamic Base URL Configuration
  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url.trim());
  }

  Future<String> getBaseUrl() async {
    final url = await _storage.read(key: _keyBaseUrl);
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return ApiEndpoints.defaultBaseUrl;
  }

  // Complete Logout/Clear
  Future<void> clearAllSession() async {
    await deleteToken();
    await deleteUserData();
  }
}
