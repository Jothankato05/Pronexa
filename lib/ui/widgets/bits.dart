import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// Protein progress ring. Animates to its value unless motion is reduced.
class ProteinRing extends StatelessWidget {
  const ProteinRing({super.key, required this.value, required this.max, this.size = 104});

  final double value;
  final double max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: 'About ${value.round()} of ${max.round()} grams of protein eaten',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: pct),
        duration: Motion.of(context, const Duration(milliseconds: 900)),
        curve: Motion.curve,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v),
            child: Center(
              child: Text(
                '${(v * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct);

  final double pct;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final r = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    if (pct <= 0) return;
    final fill = Paint()
      ..color = C.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * pct, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct;
}

/// Floating pill navigation (Today, Log, Solve, Learn).
class PillNav extends StatelessWidget {
  const PillNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Today'),
    (Icons.add_circle_outline, Icons.add_circle, 'Log a meal'),
    (Icons.lightbulb_outline, Icons.lightbulb, 'Close the gap'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
  ];

  static const _idle = Color(0xFF5C6478);

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.medium);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Tooltip(
              message: items[i].$3,
              child: Semantics(
                selected: i == index,
                button: true,
                label: items[i].$3,
                excludeSemantics: true,
                child: Pressable(
                  scale: 0.9,
                  child: AnimatedContainer(
                    duration: d,
                    curve: Motion.curve,
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: i == index ? C.indigo : Colors.white, shape: BoxShape.circle),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onTap(i),
                        child: AnimatedSwitcher(
                          duration: d,
                          transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: c),
                          child: Icon(i == index ? items[i].$2 : items[i].$1, key: ValueKey(i == index), color: i == index ? Colors.white : _idle),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
