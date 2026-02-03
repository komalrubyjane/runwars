import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/enum/activity_type.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/user.dart';

/// Fetches community activities from Supabase (no legacy Dio API).
final communityActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final list = await SupabaseService().getCommunityActivities(limit: 50);
  return list.map(_mapToActivity).toList();
});

Activity _mapToActivity(Map<String, dynamic> map) {
  final id = map['id']?.toString() ?? '';
  final userId = map['user_id']?.toString() ?? '';
  final distance = (map['distance'] as num?)?.toDouble() ?? 0.0;
  final durationSeconds = (map['duration_seconds'] as int?) ?? 0;
  final createdStr = map['created_at'] as String?;
  final startDatetime = createdStr != null ? DateTime.tryParse(createdStr) ?? DateTime.now() : DateTime.now();
  final endDatetime = startDatetime.add(Duration(seconds: durationSeconds));
  final time = durationSeconds.toDouble();
  final speed = time > 0 ? (distance / (time / 3600)) : 0.0;

  final users = map['users'];
  String? fullName;
  String? email;
  if (users is Map) {
    fullName = users['full_name'] as String?;
    email = users['email'] as String?;
  }
  final user = User(
    id: userId,
    username: email ?? '',
    firstname: fullName ?? 'Runner',
    lastname: null,
  );

  final pathPoints = map['path_points'] as List<dynamic>? ?? [];
  final locations = pathPoints.asMap().entries.map((e) {
    final p = e.value is Map ? Map<String, dynamic>.from(e.value as Map) : <String, dynamic>{};
    final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
    final ts = p['timestamp'] as String?;
    final dt = ts != null ? DateTime.tryParse(ts) ?? startDatetime : startDatetime;
    return Location(id: '${e.key}', datetime: dt, latitude: lat, longitude: lng);
  }).toList();

  return Activity(
    id: id,
    type: ActivityType.running,
    startDatetime: startDatetime,
    endDatetime: endDatetime,
    distance: distance,
    speed: speed,
    time: time,
    locations: locations,
    user: user,
    likesCount: 0,
    hasCurrentUserLiked: false,
    comments: const [],
  );
}
