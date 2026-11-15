import 'package:flutter/material.dart';

/// Five stars. Read only when [onChanged] is null. Tapping the current value clears it.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.onChanged, this.size = 32});

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFB300);
    final stars = List.generate(5, (i) {
      final icon = Icon(i < value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: color);
      if (onChanged == null) return icon;
      return IconButton(
        icon: icon,
        tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
        visualDensity: VisualDensity.compact,
        onPressed: () => onChanged!(i + 1 == value ? 0 : i + 1),
      );
    });
    return Semantics(
      label: value == 0 ? 'Not rated' : 'Rated $value out of 5',
      child: Row(mainAxisSize: MainAxisSize.min, children: stars),
    );
  }
}
