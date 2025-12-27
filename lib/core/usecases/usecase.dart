// Core - Use Case Base Class
// All use cases should extend this class

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// For use cases that don't require parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
