import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/providers.dart';
import '../widgets/banner_image.dart';
import '../widgets/star_rating.dart';
import '../widgets/ticket_stub.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = findEvent(ref.watch(eventsProvider), id);
    // deleted, or removed by a sync from another device
    if (event == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('This event no longer exists.')));

    final notifier = ref.read(eventsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final canMarkAttended = !event.attended && !event.date.isAfter(DateTime.now());

    Future<void> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Delete event?'),
          content: Text('"${event.title}" will be removed from this phone and the server.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      await notifier.delete(event.id);
      if (context.mounted) Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Event'), actions: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(existing: event))),
        ),
        IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: confirmDelete),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (event.image.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(height: 180, child: BannerImage(image: event.image, type: event.type, darken: false)),
          ),
          const SizedBox(height: 12),
        ],
        TicketStub(event: event),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(DateFormat('EEEE d MMMM y, h:mm a').format(event.date)),
        ),
        if (event.artist.isNotEmpty) ListTile(leading: const Icon(Icons.mic), title: Text(event.artist)),
        if (event.venue.isNotEmpty) ListTile(leading: const Icon(Icons.place), title: Text(event.venue)),
        ListTile(
          leading: const Icon(Icons.payments),
          title: Text(event.price == 0 ? 'Free' : 'LKR ${event.price.toStringAsFixed(2)}'),
        ),
        if (event.attended) ...[
          const Divider(),
          Text('Your rating', style: text.titleMedium),
          // rate straight from here without opening the form
          StarRating(value: event.rating, onChanged: (r) => notifier.save(event.copyWith(rating: r), isNew: false)),
        ],
        if (event.notes.isNotEmpty) ...[
          const Divider(),
          Text('Notes', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(event.notes),
        ],
        if (canMarkAttended) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('I went. Move to diary'),
            onPressed: () => notifier.save(event.copyWith(status: 'attended'), isNew: false),
          ),
        ],
      ]),
    );
  }
}
