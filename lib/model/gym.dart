import 'package:FitStart/model/gym_amenity.dart';

class Gym {
  String id;
  String name;
  String
      type; // e.g., 'CrossFit', 'Bodybuilding', 'Functional', 'Yoga', 'Pilates', 'Mixed'
  List<GymAmenity> amenities;
  String address;
  String phoneNumber;
  String openDay;
  String openTime;
  String closeTime;
  String imageAsset;
  int monthlyPrice;
  int dailyPrice;
  // Location and rating
  double latitude;
  double longitude;
  double rating;
  // Computed at runtime for sorting/display
  double? distanceKm;
  String author;
  String authorUrl;
  String imageUrl;
  // Gym specific features
  bool hasPersonalTrainer;
  bool hasGroupClasses;
  int trainerPrice; // per session
  String? description;

  Gym({
    required this.id,
    required this.name,
    required this.type,
    required this.amenities,
    required this.address,
    required this.phoneNumber,
    required this.openDay,
    required this.openTime,
    required this.closeTime,
    required this.imageAsset,
    required this.monthlyPrice,
    required this.dailyPrice,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.author,
    required this.authorUrl,
    required this.imageUrl,
    this.hasPersonalTrainer = false,
    this.hasGroupClasses = false,
    this.trainerPrice = 0,
    this.description,
  });

  // Check if gym is currently open
  bool isOpenNow([DateTime? now]) {
    final DateTime current = now ?? DateTime.now();
    final _toMinutes = (String timeStr) {
      final cleaned = timeStr.replaceAll(" ", "");
      final sep = cleaned.contains('.') ? '.' : ':';
      final parts = cleaned.split(sep);
      int h = 0;
      int m = 0;
      if (parts.isNotEmpty) {
        h = int.tryParse(parts[0]) ?? 0;
      }
      if (parts.length > 1) {
        m = int.tryParse(parts[1]) ?? 0;
      }
      return h * 60 + m;
    };

    final int start = _toMinutes(openTime);
    final int end = _toMinutes(closeTime);
    final int nowMinutes = current.hour * 60 + current.minute;

    if (end == start) {
      return true; // 24 hours
    }
    if (end > start) {
      return nowMinutes >= start && nowMinutes <= end;
    } else {
      return nowMinutes >= start || nowMinutes <= end;
    }
  }
}
