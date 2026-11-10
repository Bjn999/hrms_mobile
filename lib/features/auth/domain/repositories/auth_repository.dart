import '../entities/auth_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String username,
    required String password,
    bool rememberForBiometrics = false,
  });

  Future<AuthResult> loginWithBiometrics();

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<bool> isAuthenticated();

  Future<bool> isBiometricAvailable();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(
    bool enabled, {
    String? username,
    String? password,
  });

  Future<bool> hasSavedCredentials();

  Future<UserEntity> updateProfile({
    String? email,
    String? username,
    String? password,
    String? passwordConfirmation,
    String? phone,
    String? address,
  });
}
