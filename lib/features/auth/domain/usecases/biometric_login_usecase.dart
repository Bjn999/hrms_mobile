import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class BiometricLoginUseCase {
  final AuthRepository repository;

  BiometricLoginUseCase(this.repository);

  Future<AuthResult> call() async {
    return await repository.loginWithBiometrics();
  }
}
