import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';

/// Listens to new run invites and shows a SnackBar so the user gets a notification.
class RunInvitesListener extends StatefulWidget {
  final Widget child;

  const RunInvitesListener({super.key, required this.child});

  @override
  State<RunInvitesListener> createState() => _RunInvitesListenerState();
}

class _RunInvitesListenerState extends State<RunInvitesListener> {
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    _unsubscribe = SupabaseService().subscribeToRunInvites(user.id, (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Run invite: Someone wants you to join their run! Tap the bell to see.'),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
