import '../../domain/entities/auth_result.dart';
import 'user_model.dart';

class LoginResponseModel extends AuthResult {
  const LoginResponseModel({
    required super.user,
    required super.token,
    required super.role,
    super.permissions,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    final token = data['token']?.toString() ?? '';
    final role = data['role']?.toString() ?? user.role;

    List<String> permissions = [];
    if (data['permissions'] != null && data['permissions'] is List) {
      permissions = (data['permissions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return LoginResponseModel(
      user: user,
      token: token,
      role: role,
      permissions: permissions,
    );
  }
}
