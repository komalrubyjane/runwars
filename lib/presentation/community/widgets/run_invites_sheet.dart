import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/strava_theme.dart';
import '../providers/run_invites_provider.dart';

/// Bottom sheet showing pending "Join me!" run invites.
void showRunInvitesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => const _RunInvitesSheet(),
  );
}

class _RunInvitesSheet extends ConsumerWidget {
  const _RunInvitesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(runInvitesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none, color: StravaTheme.orange),
                  const SizedBox(width: 8),
                  const Text('Run invites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: async.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No pending invites',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final inv = list[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: StravaTheme.orange.withValues(alpha: 0.2),
                          child: Text(
                            (inv.fromUserName ?? inv.fromUserId).isNotEmpty
                                ? (inv.fromUserName ?? inv.fromUserId)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: StravaTheme.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(inv.fromUserName ?? 'Someone'),
                        subtitle: Text(inv.message),
                        trailing: const Icon(Icons.directions_run, color: StravaTheme.orange),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.grey[600]))),
              ),
            ),
          ],
        );
      },
    );
  }
}
