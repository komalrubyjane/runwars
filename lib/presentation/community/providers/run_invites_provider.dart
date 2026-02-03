import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/supabase_service.dart';

/// One run invite for display.
class RunInviteItem {
  final String id;
  final String fromUserId;
  final String? fromUserName;
  final String message;
  final String status;
  final DateTime? createdAt;

  const RunInviteItem({
    required this.id,
    required this.fromUserId,
    this.fromUserName,
    required this.message,
    required this.status,
    this.createdAt,
  });
}

/// Fetches pending run invites for the current user.
final runInvitesProvider = FutureProvider<List<RunInviteItem>>((ref) async {
  final user = SupabaseService().currentUser;
  if (user == null) return [];

  final list = await SupabaseService().getRunInvitesForUser(user.id);
  final items = <RunInviteItem>[];

  for (final map in list) {
    final fromUserId = map['from_user_id'] as String?;
    final fromUserName = map['_sender_name'] as String?;
    items.add(RunInviteItem(
      id: map['id'] as String? ?? '',
      fromUserId: fromUserId ?? '',
      fromUserName: fromUserName,
      message: map['message'] as String? ?? 'Join me for a run!',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
    ));
  }
  return items;
});
