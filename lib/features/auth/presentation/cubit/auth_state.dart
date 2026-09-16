import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final UserEntity user;
  final String token;
  final String role;
  final List<String> permissions;
  final bool promptBiometrics;

  const Authenticated({
    required this.user,
    required this.token,
    required this.role,
    this.permissions = const [],
    this.promptBiometrics = false,
  });

  @override
  List<Object?> get props => [user, token, role, permissions, promptBiometrics];
}

class Unauthenticated extends AuthState {
  final bool canUseBiometrics;
  final bool hasSavedCredentials;

  const Unauthenticated({
    this.canUseBiometrics = false,
    this.hasSavedCredentials = false,
  });

  @override
  List<Object?> get props => [canUseBiometrics, hasSavedCredentials];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
