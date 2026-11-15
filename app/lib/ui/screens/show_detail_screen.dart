import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/event.dart';
import '../../state/providers.dart';
import '../widgets/banner_image.dart';

class ShowDetailScreen extends ConsumerWidget {
  const ShowDetailScreen({super.key, required this.show});
  final Show show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // same title and date means the user already saved this show
    final past = !show.date.isAfter(DateTime.now());
    final saved = ref.watch(eventsProvider).items.any((e) => e.title == show.title && e.date.isAtSameMomentAs(show.date));

    Future<void> add() async {
      await ref.read(eventsProvider.notifier).save(
            EventItem(
              id: const Uuid().v4(),
              title: show.title,
              artist: show.artist,
              venue: show.venue,
              date: show.date,
              type: show.type,
              status: past ? 'attended' : 'planned',
              price: show.price,
              image: show.image,
              updatedAt: DateTime.now(),
            ),
            isNew: true,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(past ? 'Added to your diary. Open it there to rate it.' : 'Added to your Upcoming list')));
      }
    }

    Widget fact(IconData icon, String title, String subtitle) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: scheme.primaryContainer, child: Icon(icon, color: scheme.onPrimaryContainer)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
        );

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar.large(
          expandedHeight: 300,
          stretch: true,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(show.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            background: Hero(tag: show.id, child: BannerImage(image: show.image, type: show.type)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList.list(children: [
            fact(Icons.calendar_month, DateFormat('EEEE d MMMM y').format(show.date), DateFormat('h:mm a').format(show.date)),
            fact(Icons.place, show.venue, 'Venue'),
            fact(Icons.mic, show.artist, 'Line-up'),
            fact(Icons.confirmation_number, 'LKR ${NumberFormat('#,###').format(show.price)}', past ? 'Tickets were from' : 'Tickets from'),
            const SizedBox(height: 12),
            Text('About', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(show.description, style: text.bodyLarge),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: saved
              ? FilledButton.tonalIcon(onPressed: null, icon: const Icon(Icons.check), label: Text(past ? 'In your diary' : 'In your Upcoming list'))
              : FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: add,
                  icon: Icon(past ? Icons.check_circle : Icons.bookmark_add),
                  label: Text(past ? 'I went' : "I'm going"),
                ),
        ),
      ),
    );
  }
}
