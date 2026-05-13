class Activity {
  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final int durationMinutes;
  final String comments;

  Activity({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.durationMinutes,
    required this.comments,
  });
  Activity copyWith({String? id, String? title, double? latitude, double? longitude, int? durationMinutes, String? comments,}) 
  {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      comments: comments ?? this.comments,
    );
  }
}