import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

/// Shows when the app is offline or has changes waiting to be sent.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(eventsProvider);
    if (s.online && s.pending == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final waiting = '${s.pending} change${s.pending == 1 ? '' : 's'} waiting to sync';
    return Material(
      color: s.online ? scheme.secondaryContainer : scheme.errorContainer,
      child: ListTile(
        dense: true,
        leading: Icon(s.online ? Icons.sync : Icons.cloud_off),
        title: Text(s.online ? waiting : 'Offline. ${s.pending == 0 ? 'Showing saved data.' : waiting}'),
        trailing: s.syncing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: ref.read(eventsProvider.notifier).sync, child: const Text('Retry')),
      ),
    );
  }
}
