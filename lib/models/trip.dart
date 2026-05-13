import 'city.dart';
import 'trip_day.dart';
class Trip{
  final String id;
  final City city;
  final int numberOfDays;
  final List<TripDay> days;

  Trip({
    required this.id,
    required this.city,
    required this.numberOfDays,
    required this.days,
  });
  Trip copyWith({String? id, City? city, int? numberOfDays, List<TripDay>? days}) {
    return Trip(
      id: id ?? this.id,
      city: city ?? this.city,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      days: days ?? this.days,
    );
  }
}