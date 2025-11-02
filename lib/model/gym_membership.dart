import 'package:FitStart/model/gym.dart';
import 'package:FitStart/model/user.dart';

class GymMembership {
  String id;
  Gym gym;
  User user;
  String membershipType; // 'daily', 'monthly', 'quarterly', 'yearly'
  DateTime startDate;
  DateTime endDate;
  int amount;
  bool isActive;
  String? trainerId; // If personal trainer is included

  GymMembership({
    required this.id,
    required this.gym,
    required this.user,
    required this.membershipType,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.isActive = true,
    this.trainerId,
  });
}
