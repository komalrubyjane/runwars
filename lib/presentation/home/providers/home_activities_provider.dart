import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/supabase_service.dart';

/// Dashboard stats: daily, weekly, monthly distance and activity counts
class DashboardStats {
  final double dailyKm;
  final double weeklyKm;
  final double monthlyKm;
  final int dailyCount;
  final int weeklyCount;
  final int monthlyCount;

  const DashboardStats({
    this.dailyKm = 0,
    this.weeklyKm = 0,
    this.monthlyKm = 0,
    this.dailyCount = 0,
    this.weeklyCount = 0,
    this.monthlyCount = 0,
  });
}

final homeActivitiesProvider = FutureProvider<DashboardStats>((ref) async {
  final user = SupabaseService().currentUser;
  if (user == null) return const DashboardStats();

  final activities = await SupabaseService().getUserActivities(user.id);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  double dailyKm = 0, weeklyKm = 0, monthlyKm = 0;
  int dailyCount = 0, weeklyCount = 0, monthlyCount = 0;

  for (final a in activities) {
    final created = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime.now();
    final dist = (a['distance'] as num?)?.toDouble() ?? 0;

    if (created.isAfter(todayStart)) {
      dailyKm += dist;
      dailyCount++;
    }
    if (created.isAfter(weekStart)) {
      weeklyKm += dist;
      weeklyCount++;
    }
    if (created.isAfter(monthStart)) {
      monthlyKm += dist;
      monthlyCount++;
    }
  }

  return DashboardStats(
    dailyKm: dailyKm,
    weeklyKm: weeklyKm,
    monthlyKm: monthlyKm,
    dailyCount: dailyCount,
    weeklyCount: weeklyCount,
    monthlyCount: monthlyCount,
  );
});
