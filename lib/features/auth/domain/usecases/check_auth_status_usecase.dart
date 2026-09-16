import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<UserEntity?> call() async {
    final isAuth = await repository.isAuthenticated();
    if (isAuth) {
      return await repository.getCurrentUser();
    }
    return null;
  }
}
