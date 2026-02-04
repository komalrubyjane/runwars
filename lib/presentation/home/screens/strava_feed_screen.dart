import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/activity.dart';
import '../../../domain/entities/enum/activity_type.dart';
import '../../community/providers/community_activities_provider.dart';
import '../../community/widgets/run_invites_sheet.dart';
import '../../common/core/utils/activity_utils.dart';
import '../providers/home_activities_provider.dart';

/// Strava-like feed: dashboard (daily/weekly/monthly) + all activities
class StravaFeedScreen extends HookConsumerWidget {
  const StravaFeedScreen({
    super.key,
    this.onSwitchToRecord,
  });

  final VoidCallback? onSwitchToRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(communityActivitiesProvider);
    final dashboardAsync = ref.watch(homeActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/run_wars_logo.png', height: 32, fit: BoxFit.contain),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showRunInvitesSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityActivitiesProvider);
          ref.invalidate(homeActivitiesProvider);
        },
        child: activitiesAsync.when(
          data: (activities) => dashboardAsync.when(
            data: (stats) => _buildBody(context, activities, stats),
            loading: () => _buildBody(context, activities, const DashboardStats()),
            error: (_, __) => _buildBody(context, activities, const DashboardStats()),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $e', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(communityActivitiesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Activity> activities, DashboardStats stats) {
    if (activities.isEmpty && stats.dailyKm == 0) {
      return ListView(
        children: [
          _DashboardSection(stats: stats, onSwitchToRecord: onSwitchToRecord),
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_run, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No activities yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onSwitchToRecord, child: const Text('Start your first activity')),
              ],
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _DashboardSection(stats: stats, onSwitchToRecord: onSwitchToRecord),
        const SizedBox(height: 16),
        Text('All Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        const SizedBox(height: 12),
        ...activities.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActivityFeedCard(activity: a),
        )),
      ],
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback? onSwitchToRecord;

  const _DashboardSection({required this.stats, this.onSwitchToRecord});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatBox('Daily', '${stats.dailyKm.toStringAsFixed(1)} km', stats.dailyCount)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox('Weekly', '${stats.weeklyKm.toStringAsFixed(1)} km', stats.weeklyCount)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox('Monthly', '${stats.monthlyKm.toStringAsFixed(1)} km', stats.monthlyCount)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSwitchToRecord,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final int count;

  const _StatBox(this.label, this.value, this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('$count activities', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

/// Widget for a single activity card in the feed (Strava-style)
class ActivityFeedCard extends StatelessWidget {
  final Activity activity;

  const ActivityFeedCard({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and action menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green[400],
                      child: Icon(
                        ActivityUtils.getActivityTypeIcon(activity.type),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.user.firstname ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(activity.startDatetime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Activity title/description
            Text(
              _getActivityTypeLabel(activity.type),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Key metrics in grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricBadge(
                  '${(activity.distance / 1000).toStringAsFixed(2)} km',
                  'Distance',
                ),
                _buildMetricBadge(
                  '${activity.time.toStringAsFixed(0)} min',
                  'Time',
                ),
                _buildMetricBadge(
                  '${activity.speed.toStringAsFixed(2)} km/h',
                  'Avg Pace',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Map preview (placeholder)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.map,
                  color: Colors.grey[300],
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Engagement metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEngagementButton(
                  Icons.favorite_border,
                  '${activity.likesCount.toInt()} Kudos',
                  activity.hasCurrentUserLiked,
                ),
                _buildEngagementButton(
                  Icons.comment_outlined,
                  '${activity.comments.length} Comments',
                  false,
                ),
                _buildEngagementButton(
                  Icons.share_outlined,
                  'Share',
                  false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementButton(
    IconData icon,
    String label,
    bool isActive,
  ) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(
        icon,
        size: 18,
        color: isActive ? Colors.red : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.red : Colors.grey,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.cycling:
        return 'Cycling';
    }
  }
}
