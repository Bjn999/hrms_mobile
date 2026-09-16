import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/biometric_login_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final BiometricLoginUseCase biometricLoginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.loginUseCase,
    required this.biometricLoginUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.authRepository,
  }) : super(AuthInitial());

  /// Check app startup auth state
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading(message: 'جاري التحقق من الجلسة...'));

    try {
      final user = await checkAuthStatusUseCase();
      final canBiometrics = await authRepository.isBiometricAvailable();
      final hasSaved = await authRepository.hasSavedCredentials();

      if (user != null) {
        emit(Authenticated(
          user: user,
          token: '', // Token is securely stored in storage
          role: user.role,
        ));
      } else {
        emit(Unauthenticated(
          canUseBiometrics: canBiometrics,
          hasSavedCredentials: hasSaved,
        ));
      }
    } catch (_) {
      final canBiometrics = await authRepository.isBiometricAvailable();
      final hasSaved = await authRepository.hasSavedCredentials();
      emit(Unauthenticated(
        canUseBiometrics: canBiometrics,
        hasSavedCredentials: hasSaved,
      ));
    }
  }

  /// Login with username and password
  Future<void> login({
    required String username,
    required String password,
    bool rememberForBiometrics = false,
  }) async {
    emit(const AuthLoading(message: 'جاري تسجيل الدخول...'));

    try {
      final result = await loginUseCase(
        username: username,
        password: password,
        rememberForBiometrics: rememberForBiometrics,
      );

      final canBiometrics = await authRepository.isBiometricAvailable();
      final isBiometricsEnabled = await authRepository.isBiometricEnabled();

      // If device supports biometrics and not enabled yet, prompt user
      final shouldPrompt = canBiometrics && !isBiometricsEnabled && !rememberForBiometrics;

      emit(Authenticated(
        user: result.user,
        token: result.token,
        role: result.role,
        permissions: result.permissions,
        promptBiometrics: shouldPrompt,
      ));
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول: ${e.toString()}'));
    }
  }

  /// Login using Biometrics
  Future<void> loginWithBiometrics() async {
    emit(const AuthLoading(message: 'جاري المصادقة بالبصمة...'));

    try {
      final result = await biometricLoginUseCase();

      emit(Authenticated(
        user: result.user,
        token: result.token,
        role: result.role,
        permissions: result.permissions,
      ));
    } on BiometricException catch (e) {
      final canBiometrics = await authRepository.isBiometricAvailable();
      final hasSaved = await authRepository.hasSavedCredentials();
      emit(AuthError(e.message));
      emit(Unauthenticated(
        canUseBiometrics: canBiometrics,
        hasSavedCredentials: hasSaved,
      ));
    } catch (e) {
      final canBiometrics = await authRepository.isBiometricAvailable();
      final hasSaved = await authRepository.hasSavedCredentials();
      emit(AuthError('فشل الدخول بالبصمة: ${e.toString()}'));
      emit(Unauthenticated(
        canUseBiometrics: canBiometrics,
        hasSavedCredentials: hasSaved,
      ));
    }
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometrics(bool enabled, {String? username, String? password}) async {
    if (enabled && username != null && password != null) {
      await authRepository.login(
        username: username,
        password: password,
        rememberForBiometrics: true,
      );
    } else {
      await authRepository.setBiometricEnabled(enabled);
    }
  }

  /// Logout
  Future<void> logout() async {
    emit(const AuthLoading(message: 'جاري تسجيل الخروج...'));
    try {
      await logoutUseCase();
    } finally {
      final canBiometrics = await authRepository.isBiometricAvailable();
      final hasSaved = await authRepository.hasSavedCredentials();
      emit(Unauthenticated(
        canUseBiometrics: canBiometrics,
        hasSavedCredentials: hasSaved,
      ));
    }
  }
}
