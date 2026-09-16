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

  Future<void> setBiometricEnabled(bool enabled);

  Future<bool> hasSavedCredentials();
}
