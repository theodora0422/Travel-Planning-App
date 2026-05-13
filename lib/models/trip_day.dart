import 'activity.dart';
class TripDay {
  final int dayNumber;
  final List<Activity> activities;

  TripDay({
    required this.dayNumber,
    required this.activities,
  });

  TripDay copyWith({int? dayNumber, List<Activity>? activities}) {
    return TripDay(
      dayNumber: dayNumber ?? this.dayNumber,
      activities: activities ?? this.activities,
    );
  }
}