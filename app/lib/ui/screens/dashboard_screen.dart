import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/event.dart';
import '../../state/providers.dart';
import '../widgets/ticket_stub.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).items;
    final user = ref.watch(authProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final upcoming = events.where((e) => !e.attended && !e.date.isBefore(DateTime(now.year, now.month, now.day))).toList();
    final thisYear = events.where((e) => e.attended && e.date.year == now.year).toList();
    final rated = thisYear.where((e) => e.rating > 0).toList();
    final spent = thisYear.fold<double>(0, (sum, e) => sum + e.price);
    final avg = rated.isEmpty ? 0 : rated.fold<int>(0, (s, e) => s + e.rating) / rated.length;
    final byType = {for (final t in eventTypes) t: thisYear.where((e) => e.type == t).length}
      ..removeWhere((_, n) => n == 0);
    // past plans the user has not logged yet
    final toLog = events.where((e) => !e.attended && e.date.isBefore(now)).toList();

    void open(EventItem e) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(id: e.id)));

    return RefreshIndicator(
      onRefresh: ref.read(eventsProvider.notifier).sync,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Hi ${user?.name.split(' ').first ?? ''}', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR ${now.year} IN LIVE EVENTS',
                style: text.labelMedium?.copyWith(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              _Stat(label: 'Seen', value: '${thisYear.length}'),
              _Stat(label: 'Spent (LKR)', value: NumberFormat.compact().format(spent)),
              _Stat(label: 'Avg rating', value: avg == 0 ? '-' : avg.toStringAsFixed(1)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Next up', style: text.titleMedium),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nothing planned yet'),
              subtitle: const Text('Add a gig, play or match you want to go to'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EventFormScreen(defaultStatus: 'planned'))),
            ),
          )
        else
          TicketStub(event: upcoming.first, onTap: () => open(upcoming.first)),
        if (toLog.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('How did it go?', style: text.titleMedium),
          Text('These dates have passed. Tap one to rate it and move it to your diary.', style: text.bodySmall),
          const SizedBox(height: 8),
          for (final e in toLog.take(3))
            Padding(padding: const EdgeInsets.only(bottom: 8), child: TicketStub(event: e, onTap: () => open(e))),
        ],
        if (byType.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('What you went to', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final entry in byType.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(typeIcons[entry.key], size: 20),
                const SizedBox(width: 8),
                SizedBox(width: 72, child: Text(entry.key)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: entry.value / thisYear.length, minHeight: 10),
                  ),
                ),
                SizedBox(width: 32, child: Text('${entry.value}', textAlign: TextAlign.end)),
              ]),
            ),
        ],
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(child: Text(value, style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
        Text(label, style: text.bodySmall?.copyWith(color: Colors.white70)),
      ]),
    );
  }
}
