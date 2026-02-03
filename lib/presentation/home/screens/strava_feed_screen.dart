import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/activity.dart';
import '../../../domain/entities/enum/activity_type.dart';
import '../../common/core/utils/activity_utils.dart';
import '../../common/core/utils/color_utils.dart';

/// Strava-like feed screen showing all activities and social features
class StravaFeedScreen extends HookConsumerWidget {
  const StravaFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, this would be fetched from a provider
    // For now, we'll create mock activities
    final activities = _getMockActivities();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_run,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to tracking screen
                    },
                    child: const Text('Start your first activity'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ActivityFeedCard(activity: activities[index]);
              },
            ),
    );
  }

  List<Activity> _getMockActivities() {
    // This would be replaced with actual activity data from the database
    return [];
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
      default:
        return 'Activity';
    }
  }
}
