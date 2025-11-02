import 'package:FitStart/model/sport_category.dart';
import 'package:FitStart/model/field_facility.dart';

class SportField {
  String id;
  String name;
  SportCategory category;
  List<FieldFacility> facilities;
  String address;
  String phoneNumber;
  String openDay;
  String openTime;
  String closeTime;
  String imageAsset;
  int price;
  // New fields for location and rating
  double latitude;
  double longitude;
  double rating;
  // Computed at runtime for sorting/display
  double? distanceKm;
  String author;
  String authorUrl;
  String imageUrl;

  SportField(
      {required this.id,
      required this.name,
      required this.category,
      required this.facilities,
      required this.address,
      required this.phoneNumber,
      required this.openDay,
      required this.openTime,
      required this.closeTime,
      required this.imageAsset,
      required this.price,
      required this.latitude,
      required this.longitude,
      required this.rating,
      required this.author,
      required this.authorUrl,
      required this.imageUrl});

  // Simple check if venue is currently open based on open/close in 24h strings like "06.00" or "06:00"
  bool isOpenNow([DateTime? now]) {
    final DateTime current = now ?? DateTime.now();
    final _toMinutes = (String timeStr) {
      // supports "HH.MM" and "HH:MM"
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
      // open 24 hours
      return true;
    }
    if (end > start) {
      // same-day closing
      return nowMinutes >= start && nowMinutes <= end;
    } else {
      // crosses midnight
      return nowMinutes >= start || nowMinutes <= end;
    }
  }
}
