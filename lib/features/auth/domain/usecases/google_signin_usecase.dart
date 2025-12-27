// Auth Feature - Google Sign In Use Case

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase implements UseCase<UserEntity, GoogleSignInParams> {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(GoogleSignInParams params) async {
    return await repository.googleSignIn(idToken: params.idToken);
  }
}

class GoogleSignInParams extends Equatable {
  final String idToken;

  const GoogleSignInParams({required this.idToken});

  @override
  List<Object> get props => [idToken];
}
