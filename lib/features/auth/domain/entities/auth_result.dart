import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthResult extends Equatable {
  final UserEntity user;
  final String token;
  final String role;
  final List<String> permissions;

  const AuthResult({
    required this.user,
    required this.token,
    required this.role,
    this.permissions = const [],
  });

  @override
  List<Object?> get props => [user, token, role, permissions];
}
