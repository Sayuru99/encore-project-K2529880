import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../data/event.dart';

/// Event banner from the API, cached on disk so it still shows offline.
/// Falls back to a gradient with the event type icon when there is no image.
class BannerImage extends StatelessWidget {
  const BannerImage({super.key, required this.image, required this.type, this.darken = true});

  final String image;
  final String type;
  final bool darken; // adds a bottom shade so white text on top stays readable

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(typeIcons[type], size: 56, color: scheme.onPrimary.withValues(alpha: 0.5))),
    );

    return Stack(fit: StackFit.expand, children: [
      if (image.isEmpty)
        fallback
      else
        CachedNetworkImage(
          imageUrl: imageUrl(image),
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholder: (_, __) => ColoredBox(color: scheme.surfaceContainerHighest),
          errorWidget: (_, __, ___) => fallback,
        ),
      if (darken)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
              stops: [0.35, 1],
            ),
          ),
        ),
    ]);
  }
}
