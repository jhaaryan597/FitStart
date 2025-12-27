// Auth BLoC - States
// All possible auth states

import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Authenticated state
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

// Unauthenticated state
class Unauthenticated extends AuthState {}

// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

// Success message (e.g., after registration)
class AuthSuccess extends AuthState {
  final String message;
  final UserEntity user;

  const AuthSuccess({
    required this.message,
    required this.user,
  });

  @override
  List<Object> get props => [message, user];
}
