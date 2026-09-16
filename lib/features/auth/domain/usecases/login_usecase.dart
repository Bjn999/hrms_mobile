import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResult> call({
    required String username,
    required String password,
    bool rememberForBiometrics = false,
  }) async {
    return await repository.login(
      username: username,
      password: password,
      rememberForBiometrics: rememberForBiometrics,
    );
  }
}
