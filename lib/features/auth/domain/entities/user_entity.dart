// Auth Feature - Domain Entity
// Pure Dart class representing a User

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String? phoneNumber;
  final String authProvider;
  final String? googleId;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.phoneNumber,
    required this.authProvider,
    this.googleId,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        profileImage,
        phoneNumber,
        authProvider,
        googleId,
      ];
}
