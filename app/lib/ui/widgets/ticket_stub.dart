import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/event.dart';
import 'star_rating.dart';

/// An event drawn as a paper ticket: a date stub on the left, a perforated tear line,
/// and the event details on the right. The shape is cut with a custom clipper.
class TicketStub extends StatelessWidget {
  const TicketStub({super.key, required this.event, this.onTap});

  final EventItem event;
  final VoidCallback? onTap;

  static const stubWidth = 76.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stubColor = event.attended ? scheme.tertiaryContainer : scheme.primaryContainer;
    final onStub = event.attended ? scheme.onTertiaryContainer : scheme.onPrimaryContainer;
    final subtitle = [event.artist, event.venue].where((s) => s.isNotEmpty).join(' at ');

    return Semantics(
      button: onTap != null,
      label: '${event.title}, ${DateFormat.yMMMd().format(event.date)}, ${event.status}',
      excludeSemantics: true,
      child: PhysicalShape(
        clipper: _TicketClipper(stubWidth),
        color: scheme.surfaceContainerHighest,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: CustomPaint(
            painter: _PerforationPainter(stubWidth, scheme.outlineVariant),
            child: Row(
              children: [
                Container(
                  width: stubWidth,
                  height: 96,
                  color: stubColor,
                  alignment: Alignment.center,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat.MMM().format(event.date).toUpperCase(),
                        style: text.labelMedium?.copyWith(color: onStub, letterSpacing: 1.5)),
                    Text('${event.date.day}', style: text.headlineMedium?.copyWith(color: onStub, fontWeight: FontWeight.bold)),
                    Text('${event.date.year}', style: text.labelSmall?.copyWith(color: onStub)),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(typeIcons[event.type], size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(event.title,
                              style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text(event.price == 0 ? 'Free' : 'LKR ${event.price.toStringAsFixed(0)}', style: text.labelLarge),
                        const Spacer(),
                        if (event.attended) StarRating(value: event.rating, size: 16),
                      ]),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded ticket with a half-circle notch at the top and bottom of the tear line.
class _TicketClipper extends CustomClipper<Path> {
  _TicketClipper(this.split);
  final double split;
  static const notch = 9.0;

  @override
  Path getClip(Size size) {
    final ticket = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(split, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(split, size.height), radius: notch));
    return Path.combine(PathOperation.difference, ticket, notches);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.split != split;
}

class _PerforationPainter extends CustomPainter {
  _PerforationPainter(this.x, this.color);
  final double x;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var y = 14.0; y < size.height - 14; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.color != color || old.x != x;
}
