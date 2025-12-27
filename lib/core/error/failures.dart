// Core - Error/Failure Classes
// This file defines failures that can occur in the app

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

// Server Failure - When API returns error
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

// Cache Failure - When local storage fails
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

// Network Failure - When there's no internet
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

// Auth Failure - Authentication/Authorization errors
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

// Validation Failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
