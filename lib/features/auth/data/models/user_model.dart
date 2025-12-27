// Auth Feature - User Model (Data Layer)
// Maps between JSON and Entity

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.profileImage,
    super.phoneNumber,
    required super.authProvider,
    super.googleId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      phoneNumber: json['phoneNumber'],
      authProvider: json['authProvider'] ?? 'email',
      googleId: json['googleId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
      'googleId': googleId,
    };
  }
}
