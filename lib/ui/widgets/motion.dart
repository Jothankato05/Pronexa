import 'package:flutter/material.dart';

import '../theme.dart';

/// Fades and slides its child in once, when first built. [index] staggers
/// items in a list. One controller, no timers; instant under reduced motion.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.index = 0, this.offset = 16});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  static const _step = 45;
  static const _run = 380;

  late final int _delay = (widget.index.clamp(0, 8)) * _step;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delay + _run),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(_delay / (_delay + _run), 1, curve: Motion.curve),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
    ),
  );
}

/// Shrinks slightly while pressed. Uses a Listener so it never competes with
/// the InkWell or button underneath for the tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(scale: _down ? widget.scale : 1, duration: Motion.of(context, Motion.fast), curve: Motion.curve, child: widget.child),
  );
}

/// A number that counts to its new value.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style});

  final double value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: Motion.of(context, const Duration(milliseconds: 700)),
    curve: Motion.curve,
    builder: (context, v, _) => Text('${v.round()}', style: style),
  );
}

/// Cross-fades between children keyed by [id] (step changes, questions).
class FadeSwap extends StatelessWidget {
  const FadeSwap({super.key, required this.id, required this.child});

  final Object id;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, Motion.medium),
    switchInCurve: Motion.curve,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, a) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(a),
        child: child,
      ),
    ),
    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
    child: KeyedSubtree(key: ValueKey(id), child: child),
  );
}
