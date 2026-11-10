import '../../../../core/error/exceptions.dart';
import '../../../../core/services/biometric_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final BiometricService biometricService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.biometricService,
  });

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
    bool rememberForBiometrics = false,
  }) async {
    final result = await remoteDataSource.login(
      username: username,
      password: password,
    );

    // Save token and user data locally
    await localDataSource.saveToken(result.token);
    await localDataSource.saveUser(result.user as UserModel);

    if (rememberForBiometrics) {
      await localDataSource.saveCredentials(username: username, password: password);
      await localDataSource.setBiometricEnabled(true);
    }

    return result;
  }

  @override
  Future<AuthResult> loginWithBiometrics() async {
    final isAvailable = await biometricService.isBiometricsAvailable();
    if (!isAvailable) {
      throw BiometricException(
        message: 'خاصية البصمة غير متوفرة أو غير مدعومة على هذا الجهاز',
      );
    }

    final isEnrolled = await localDataSource.isBiometricEnabled();
    final credentials = await localDataSource.getSavedCredentials();

    if (!isEnrolled || credentials == null) {
      throw BiometricException(
        message: 'لم يتم حفظ بيانات الدخول السريع، يرجى تسجيل الدخول بكلمة المرور أولاً',
      );
    }

    // Authenticate via hardware biometric prompt
    final authenticated = await biometricService.authenticate(
      localizedReason: 'تأكيد البصمة للدخول السريع إلى حسابك',
    );

    if (!authenticated) {
      throw BiometricException(
        message: 'فشلت المصادقة بالبصمة، يرجى المحاولة مجدداً أو استخدام كلمة المرور',
      );
    }

    // Login with saved credentials
    final username = credentials['username']!;
    final password = credentials['password']!;

    return await login(
      username: username,
      password: password,
      rememberForBiometrics: true,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await localDataSource.clearSession();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await localDataSource.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    // Try fetching fresh profile from backend to verify token validity and get latest user info
    try {
      final remoteUser = await remoteDataSource.getUserProfile();
      await localDataSource.saveUser(remoteUser);
      return remoteUser;
    } on ServerException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await localDataSource.clearSession();
        return null;
      }
      // On other server errors, fallback to cached user
      return await localDataSource.getUser();
    } catch (_) {
      // Offline fallback to cached user
      return await localDataSource.getUser();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return await biometricService.isBiometricsAvailable();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await localDataSource.isBiometricEnabled();
  }

  @override
  Future<void> setBiometricEnabled(
    bool enabled, {
    String? username,
    String? password,
  }) async {
    await localDataSource.setBiometricEnabled(enabled);
    if (enabled && username != null && password != null) {
      await localDataSource.saveCredentials(
        username: username,
        password: password,
      );
    } else if (!enabled) {
      await localDataSource.clearSavedCredentials();
    }
  }

  @override
  Future<bool> hasSavedCredentials() async {
    final isEnabled = await localDataSource.isBiometricEnabled();
    final credentials = await localDataSource.getSavedCredentials();
    return isEnabled && credentials != null;
  }

  @override
  Future<UserEntity> updateProfile({
    String? email,
    String? username,
    String? password,
    String? passwordConfirmation,
    String? phone,
    String? address,
  }) async {
    final updatedUser = await remoteDataSource.updateProfile(
      email: email,
      username: username,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone,
      address: address,
    );
    await localDataSource.saveUser(updatedUser);

    // If biometric credentials were saved and username or password changed, update them
    if (await localDataSource.isBiometricEnabled()) {
      final creds = await localDataSource.getSavedCredentials();
      if (creds != null) {
        final newUsername = (username != null && username.trim().isNotEmpty)
            ? username.trim()
            : creds['username']!;
        final newPassword = (password != null && password.isNotEmpty)
            ? password
            : creds['password']!;
        await localDataSource.saveCredentials(
          username: newUsername,
          password: newPassword,
        );
      }
    }

    return updatedUser;
  }
}
