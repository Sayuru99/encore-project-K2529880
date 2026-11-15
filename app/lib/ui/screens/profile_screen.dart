import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart' as v;
import '../../state/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final sync = ref.watch(eventsProvider);
    if (user == null) return const SizedBox.shrink();

    void snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    Future<void> editName() async {
      final ctrl = TextEditingController(text: user.name);
      final key = GlobalKey<FormState>();
      final name = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Your name'),
          content: Form(
            key: key,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              validator: (s) => v.requiredText(s, max: 50, field: 'Name'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, ctrl.text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (name == null) return;
      try {
        await ref.read(authProvider.notifier).updateName(name);
        snack('Name updated');
      } catch (e) {
        snack(e.toString());
      }
    }

    Future<void> logout() async {
      if (sync.pending > 0) {
        // logging out wipes the phone, so unsent changes would be lost
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Unsynced changes'),
            content: Text('${sync.pending} change(s) have not reached the server yet and will be lost if you log out now.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out anyway')),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(authProvider.notifier).logout();
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 16),
      CircleAvatar(radius: 40, child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 32))),
      const SizedBox(height: 12),
      Text(user.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      Text(user.email, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Card(
        child: Column(children: [
          ListTile(leading: const Icon(Icons.edit), title: const Text('Change name'), onTap: editName),
          ListTile(
            leading: Icon(sync.online ? Icons.cloud_done : Icons.cloud_off),
            title: Text(sync.online ? 'Connected' : 'Offline'),
            subtitle: Text(sync.pending == 0 ? 'Everything is synced' : '${sync.pending} change(s) waiting'),
            trailing: sync.syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(onPressed: ref.read(eventsProvider.notifier).sync, child: const Text('Sync now')),
          ),
          ListTile(leading: const Icon(Icons.local_activity), title: Text('${sync.items.length} events saved')),
        ]),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout), label: const Text('Log out')),
    ]);
  }
}
