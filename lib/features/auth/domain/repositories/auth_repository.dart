// Auth Feature - Domain Repository Interface
// Defines what the auth repository should do (contract)

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String username,
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> googleSignIn({
    required String idToken,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, bool>> isLoggedIn();
}
