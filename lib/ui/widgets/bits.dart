import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../theme.dart';

/// Protein progress ring. Animates to its value unless motion is reduced.
class ProteinRing extends StatelessWidget {
  const ProteinRing({super.key, required this.value, required this.max, this.size = 104});

  final double value;
  final double max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'About ${value.round()} of ${max.round()} grams of protein eaten',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(v),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    'OF TARGET',
                    style: TextStyle(color: C.onGreen2, fontSize: 9.5, fontWeight: FontWeight.w500, letterSpacing: 1),
                  ),
                ],
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
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    if (pct <= 0) return;
    final fill = Paint()
      ..color = C.ochre100
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * pct, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct;
}

/// Shows "Offline" when there is no connection. Nothing else: the log is
/// always saved on the phone, so there is no sync state to report.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.state, this.onGreen = false});

  final AppState state;
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    final offline = !state.online;
    final fg = onGreen ? Colors.white : (offline ? C.clay700 : C.ink2);
    final bg = onGreen ? Colors.white.withValues(alpha: 0.14) : (offline ? C.clay100 : C.surface2);
    return Semantics(
      label: offline ? 'Offline. Meals are saved on this phone.' : 'Online. Meals are saved on this phone.',
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: offline ? (onGreen ? C.clay200 : C.clay700) : (onGreen ? C.leaf300 : C.leaf600), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              offline ? 'Offline' : 'Saved on phone',
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating pill navigation (Today, Log, Solve, Learn).
class PillNav extends StatelessWidget {
  const PillNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const items = [
    (Icons.home_outlined, Icons.home, 'Today'),
    (Icons.add_circle_outline, Icons.add_circle, 'Log a meal'),
    (Icons.lightbulb_outline, Icons.lightbulb, 'Close the gap'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: C.line),
      boxShadow: const [BoxShadow(color: Color(0x1F3C2D19), blurRadius: 24, offset: Offset(0, 8))],
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
              child: Material(
                color: i == index ? C.leaf600 : Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onTap(i),
                  child: SizedBox(width: 54, height: 54, child: Icon(i == index ? items[i].$2 : items[i].$1, color: i == index ? Colors.white : C.ink2)),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
