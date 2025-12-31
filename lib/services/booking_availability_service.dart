import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing real-time booking availability
/// Handles slot capacity for venues (1 per slot) and gyms (configurable capacity)
class BookingAvailabilityService {
  static const String _boxName = 'booking_availability';
  static Box? _box;

  /// Venue types
  static const String venueType = 'venue';
  static const String gymType = 'gym';

  /// Initialize the service
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// Generate unique key for a slot
  static String _getSlotKey({
    required String venueId,
    required String date,
    required String timeSlot,
  }) {
    return '${venueId}_${date}_$timeSlot';
  }

  /// Get the capacity for a venue/gym
  /// Venues: 1 booking per slot
  /// Gyms: configurable capacity (default 30)
  static int getCapacity(String type, {int? customCapacity}) {
    if (type == gymType) {
      return customCapacity ?? 30; // Default gym capacity
    }
    return 1; // Venues allow only 1 booking per slot
  }

  /// Check if a slot is available
  static Future<bool> isSlotAvailable({
    required String venueId,
    required String date,
    required String timeSlot,
    required String type,
    int? maxCapacity,
  }) async {
    await init();

    final key = _getSlotKey(venueId: venueId, date: date, timeSlot: timeSlot);
    final bookingData = _box?.get(key);

    if (bookingData == null) {
      return true; // No bookings yet
    }

    final bookings = Map<String, dynamic>.from(bookingData);
    final currentCount = (bookings['count'] as int?) ?? 0;
    final capacity = getCapacity(type, customCapacity: maxCapacity);

    return currentCount < capacity;
  }

  /// Get number of available spots for a slot
  static Future<int> getAvailableSpots({
    required String venueId,
    required String date,
    required String timeSlot,
    required String type,
    int? maxCapacity,
  }) async {
    await init();

    final key = _getSlotKey(venueId: venueId, date: date, timeSlot: timeSlot);
    final bookingData = _box?.get(key);

    final capacity = getCapacity(type, customCapacity: maxCapacity);

    if (bookingData == null) {
      return capacity; // All spots available
    }

    final bookings = Map<String, dynamic>.from(bookingData);
    final currentCount = (bookings['count'] as int?) ?? 0;

    return (capacity - currentCount).clamp(0, capacity);
  }

  /// Get slot status (available/limited/full)
  static Future<SlotStatus> getSlotStatus({
    required String venueId,
    required String date,
    required String timeSlot,
    required String type,
    int? maxCapacity,
  }) async {
    await init();

    final key = _getSlotKey(venueId: venueId, date: date, timeSlot: timeSlot);
    final bookingData = _box?.get(key);

    final capacity = getCapacity(type, customCapacity: maxCapacity);

    if (bookingData == null) {
      return SlotStatus.available;
    }

    final bookings = Map<String, dynamic>.from(bookingData);
    final currentCount = (bookings['count'] as int?) ?? 0;

    if (currentCount >= capacity) {
      return SlotStatus.full;
    } else if (currentCount >= capacity * 0.7) {
      return SlotStatus.limited; // Less than 30% available
    }
    return SlotStatus.available;
  }

  /// Book a slot
  static Future<BookingResult> bookSlot({
    required String venueId,
    required String date,
    required String timeSlot,
    required String type,
    required String userEmail,
    int? maxCapacity,
  }) async {
    await init();

    final key = _getSlotKey(venueId: venueId, date: date, timeSlot: timeSlot);
    final bookingData = _box?.get(key);

    final capacity = getCapacity(type, customCapacity: maxCapacity);

    Map<String, dynamic> bookings;
    if (bookingData == null) {
      bookings = {
        'venueId': venueId,
        'date': date,
        'timeSlot': timeSlot,
        'type': type,
        'capacity': capacity,
        'count': 0,
        'users': <String>[],
      };
    } else {
      bookings = Map<String, dynamic>.from(bookingData);
    }

    final currentCount = (bookings['count'] as int?) ?? 0;
    final users = List<String>.from(bookings['users'] ?? []);

    // Check if already booked by this user
    if (users.contains(userEmail)) {
      return BookingResult(
        success: false,
        message: 'You have already booked this slot',
        availableSpots: capacity - currentCount,
      );
    }

    // Check capacity
    if (currentCount >= capacity) {
      return BookingResult(
        success: false,
        message: type == gymType
            ? 'This time slot is fully booked'
            : 'This venue is already booked for this time slot',
        availableSpots: 0,
      );
    }

    // Book the slot
    bookings['count'] = currentCount + 1;
    users.add(userEmail);
    bookings['users'] = users;
    bookings['updatedAt'] = DateTime.now().toIso8601String();

    await _box?.put(key, bookings);

    if (kDebugMode) {
      print('✅ Booked slot: $key for $userEmail (${currentCount + 1}/$capacity)');
    }

    return BookingResult(
      success: true,
      message: 'Slot booked successfully',
      availableSpots: capacity - currentCount - 1,
    );
  }

  /// Cancel a booking
  static Future<bool> cancelBooking({
    required String venueId,
    required String date,
    required String timeSlot,
    required String userEmail,
  }) async {
    await init();

    final key = _getSlotKey(venueId: venueId, date: date, timeSlot: timeSlot);
    final bookingData = _box?.get(key);

    if (bookingData == null) {
      return false;
    }

    final bookings = Map<String, dynamic>.from(bookingData);
    final users = List<String>.from(bookings['users'] ?? []);

    if (!users.contains(userEmail)) {
      return false;
    }

    users.remove(userEmail);
    bookings['users'] = users;
    bookings['count'] = ((bookings['count'] as int?) ?? 1) - 1;
    bookings['updatedAt'] = DateTime.now().toIso8601String();

    await _box?.put(key, bookings);

    if (kDebugMode) {
      print('✅ Cancelled booking: $key for $userEmail');
    }

    return true;
  }

  /// Get all slots availability for a date
  static Future<Map<String, SlotInfo>> getDayAvailability({
    required String venueId,
    required String date,
    required String type,
    required List<String> timeSlots,
    int? maxCapacity,
  }) async {
    await init();

    final Map<String, SlotInfo> availability = {};

    for (final timeSlot in timeSlots) {
      final status = await getSlotStatus(
        venueId: venueId,
        date: date,
        timeSlot: timeSlot,
        type: type,
        maxCapacity: maxCapacity,
      );

      final availableSpots = await getAvailableSpots(
        venueId: venueId,
        date: date,
        timeSlot: timeSlot,
        type: type,
        maxCapacity: maxCapacity,
      );

      availability[timeSlot] = SlotInfo(
        status: status,
        availableSpots: availableSpots,
        totalCapacity: getCapacity(type, customCapacity: maxCapacity),
      );
    }

    return availability;
  }

  /// Check if multiple slots are all available
  static Future<bool> areAllSlotsAvailable({
    required String venueId,
    required String date,
    required List<String> timeSlots,
    required String type,
    int? maxCapacity,
  }) async {
    for (final slot in timeSlots) {
      final isAvailable = await isSlotAvailable(
        venueId: venueId,
        date: date,
        timeSlot: slot,
        type: type,
        maxCapacity: maxCapacity,
      );
      if (!isAvailable) return false;
    }
    return true;
  }

  /// Book multiple slots atomically
  static Future<BookingResult> bookMultipleSlots({
    required String venueId,
    required String date,
    required List<String> timeSlots,
    required String type,
    required String userEmail,
    int? maxCapacity,
  }) async {
    // First check all slots are available
    final allAvailable = await areAllSlotsAvailable(
      venueId: venueId,
      date: date,
      timeSlots: timeSlots,
      type: type,
      maxCapacity: maxCapacity,
    );

    if (!allAvailable) {
      return BookingResult(
        success: false,
        message: 'Some selected time slots are no longer available',
        availableSpots: 0,
      );
    }

    // Book all slots
    final List<String> bookedSlots = [];
    for (final slot in timeSlots) {
      final result = await bookSlot(
        venueId: venueId,
        date: date,
        timeSlot: slot,
        type: type,
        userEmail: userEmail,
        maxCapacity: maxCapacity,
      );

      if (result.success) {
        bookedSlots.add(slot);
      } else {
        // Rollback previously booked slots
        for (final bookedSlot in bookedSlots) {
          await cancelBooking(
            venueId: venueId,
            date: date,
            timeSlot: bookedSlot,
            userEmail: userEmail,
          );
        }
        return BookingResult(
          success: false,
          message: 'Failed to book slot $slot: ${result.message}',
          availableSpots: 0,
        );
      }
    }

    return BookingResult(
      success: true,
      message: 'All ${timeSlots.length} time slots booked successfully',
      availableSpots: 0,
    );
  }

  /// Clear old bookings (older than 30 days)
  static Future<void> clearOldBookings() async {
    await init();

    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final keysToDelete = <String>[];

    for (final key in _box?.keys ?? []) {
      final data = _box?.get(key);
      if (data != null) {
        final dateStr = data['date'] as String?;
        if (dateStr != null) {
          final bookingDate = DateTime.tryParse(dateStr);
          if (bookingDate != null && bookingDate.isBefore(cutoffDate)) {
            keysToDelete.add(key as String);
          }
        }
      }
    }

    for (final key in keysToDelete) {
      await _box?.delete(key);
    }

    if (kDebugMode && keysToDelete.isNotEmpty) {
      print('🗑️ Cleared ${keysToDelete.length} old booking records');
    }
  }
}

/// Slot availability status
enum SlotStatus {
  available, // All or most spots available
  limited, // Less than 30% available
  full, // No spots available
}

/// Information about a slot
class SlotInfo {
  final SlotStatus status;
  final int availableSpots;
  final int totalCapacity;

  SlotInfo({
    required this.status,
    required this.availableSpots,
    required this.totalCapacity,
  });

  String get displayText {
    if (status == SlotStatus.full) {
      return 'Full';
    } else if (totalCapacity == 1) {
      return 'Available';
    } else {
      return '$availableSpots/$totalCapacity';
    }
  }
}

/// Result of a booking operation
class BookingResult {
  final bool success;
  final String message;
  final int availableSpots;

  BookingResult({
    required this.success,
    required this.message,
    required this.availableSpots,
  });
}
