import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event.dart';
import '../../state/providers.dart';
import '../widgets/ticket_stub.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

/// Used twice: 'planned' is the Upcoming tab, 'attended' is the Diary tab.
class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key, required this.status});
  final String status;

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  String _query = '';
  String? _type;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(eventsProvider).items.where((e) => e.status == widget.status);
    final q = _query.toLowerCase();
    final list = all
        .where((e) => _type == null || e.type == _type)
        .where((e) => q.isEmpty || '${e.title} ${e.artist} ${e.venue}'.toLowerCase().contains(q))
        .toList();
    // diary reads newest first, upcoming reads soonest first
    if (widget.status == 'attended') list.sort((a, b) => b.date.compareTo(a.date));
    final planned = widget.status == 'planned';

    return Scaffold(
      appBar: AppBar(title: Text(planned ? 'Upcoming' : 'Diary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => EventFormScreen(defaultStatus: widget.status))),
        icon: const Icon(Icons.add),
        label: Text(planned ? 'Plan event' : 'Log event'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchBar(
            hintText: 'Search title, artist or venue',
            leading: const Icon(Icons.search),
            onChanged: (s) => setState(() => _query = s.trim()),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final t in eventTypes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(typeIcons[t], size: 18),
                  label: Text(t),
                  selected: _type == t,
                  onSelected: (on) => setState(() => _type = on ? t : null),
                ),
              ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(eventsProvider.notifier).sync,
            child: list.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Icon(planned ? Icons.event_available : Icons.menu_book, size: 56, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 8),
                    Text(
                      all.isEmpty
                          ? (planned ? 'Nothing planned. Tap Plan event to add one.' : 'Your diary is empty. Log a show you went to.')
                          : 'No events match your search.',
                      textAlign: TextAlign.center,
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TicketStub(
                      event: list[i],
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => EventDetailScreen(id: list[i].id))),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
