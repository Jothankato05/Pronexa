import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// Thin progress line under the big number. Glides to its value.
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, required this.max});

  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: 'About ${(pct * 100).round()}% of today\'s protein target',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: pct),
        duration: Motion.of(context, const Duration(milliseconds: 900)),
        curve: Motion.curve,
        builder: (context, v, _) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.12))),
                FractionallySizedBox(
                  widthFactor: v,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: C.blue, borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: SizedBox.expand(),
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

/// Floating pill navigation (Asteria): translucent white, active button in
/// solid indigo.
class PillNav extends StatelessWidget {
  const PillNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Today'),
    (Icons.add_rounded, Icons.add_rounded, 'Log a meal'),
    (Icons.lightbulb_outline, Icons.lightbulb, 'Close the gap'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.medium);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x0D000000)),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 28, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Tooltip(
              message: items[i].$3,
              child: Semantics(
                selected: i == index,
                button: true,
                label: items[i].$3,
                excludeSemantics: true,
                child: Pressable(
                  scale: 0.9,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: i == index ? 1 : 0,
                            duration: d,
                            curve: Motion.curve,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: C.indigo,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20))],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onTap(i),
                              child: AnimatedSwitcher(
                                duration: d,
                                transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: c),
                                child: Icon(
                                  i == index ? items[i].$2 : items[i].$1,
                                  key: ValueKey(i == index),
                                  color: i == index ? Colors.white : Colors.black,
                                  size: i == 1 ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
