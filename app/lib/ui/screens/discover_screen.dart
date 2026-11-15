import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/event.dart';
import '../../state/providers.dart';
import '../widgets/banner_image.dart';
import 'show_detail_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _type;
  final _pages = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _open(Show s) => Navigator.push(context, MaterialPageRoute(builder: (_) => ShowDetailScreen(show: s)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(showsProvider);
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(showsProvider.future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 48),
          Padding(padding: const EdgeInsets.all(16), child: Text('Could not load shows: $e', textAlign: TextAlign.center)),
          Center(child: FilledButton(onPressed: () => ref.invalidate(showsProvider), child: const Text('Try again'))),
        ]),
        data: (result) {
          final now = DateTime.now();
          final upcoming = result.shows.where((s) => s.date.isAfter(now)).toList();
          final past = result.shows.where((s) => !s.date.isAfter(now)).toList().reversed.toList();
          final featured = upcoming.take(3).toList();
          final list = upcoming.where((s) => _type == null || s.type == _type).toList();
          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Discover', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                result.offline ? 'Offline. Showing the last listings you loaded.' : 'What is on around Sri Lanka',
                style: text.bodyMedium,
              ),
            ),
            if (result.shows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('No listings yet. Connect to the internet and pull down to refresh.', textAlign: TextAlign.center),
              )
            else ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 230,
                child: PageView(
                  controller: _pages,
                  children: [for (final s in featured) _FeaturedCard(show: s, onTap: () => _open(s))],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: const Text('All'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
                  ),
                  for (final t in eventTypes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(typeIcons[t], size: 18),
                        label: Text(t),
                        selected: _type == t,
                        onSelected: (on) => setState(() => _type = on ? t : null),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Text('Nothing of this type coming up.', textAlign: TextAlign.center)),
              for (final s in list) _ShowRow(show: s, onTap: () => _open(s)),
              if (past.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 2),
                  child: Text('Earlier this year', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text('Were you there? Tap a show to add it to your diary.', style: text.bodySmall),
                ),
                SizedBox(
                  height: 190,
                  child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                    for (final s in past) SizedBox(width: 280, child: _FeaturedCard(show: s, onTap: () => _open(s))),
                  ]),
                ),
              ],
            ],
          ]);
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.show, required this.onTap});
  final Show show;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: Stack(fit: StackFit.expand, children: [
              Hero(tag: show.id, child: BannerImage(image: show.image, type: show.type)),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Pill(DateFormat('EEE d MMM').format(show.date).toUpperCase()),
                  const SizedBox(height: 8),
                  Text(show.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(show.venue, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.show, required this.onTap});
  final Show show;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 88, height: 88, child: BannerImage(image: show.image, type: show.type, darken: false)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEE d MMM, h:mm a').format(show.date),
                  style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(show.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(show.venue, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
              const SizedBox(height: 4),
              Text('From LKR ${NumberFormat('#,###').format(show.price)}', style: text.labelLarge),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}
