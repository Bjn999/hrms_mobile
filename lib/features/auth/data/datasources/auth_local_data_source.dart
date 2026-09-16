import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> deleteUser();

  Future<void> saveCredentials({required String username, required String password});
  Future<Map<String, String>?> getSavedCredentials();
  Future<void> clearSavedCredentials();

  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);

  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService storage;

  AuthLocalDataSourceImpl({required this.storage});

  @override
  Future<void> saveToken(String token) async {
    await storage.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await storage.getToken();
  }

  @override
  Future<void> deleteToken() async {
    await storage.deleteToken();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await storage.saveUserData(user.toJson());
  }

  @override
  Future<UserModel?> getUser() async {
    final data = await storage.getUserData();
    if (data != null) {
      return UserModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<void> deleteUser() async {
    await storage.deleteUserData();
  }

  @override
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await storage.saveCredentials(username: username, password: password);
  }

  @override
  Future<Map<String, String>?> getSavedCredentials() async {
    return await storage.getSavedCredentials();
  }

  @override
  Future<void> clearSavedCredentials() async {
    await storage.clearSavedCredentials();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await storage.isBiometricEnabled();
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await storage.setBiometricEnabled(enabled);
  }

  @override
  Future<void> clearSession() async {
    await storage.clearAllSession();
  }
}
