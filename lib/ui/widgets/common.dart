import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import 'motion.dart';

/// Food and container illustrations (flat SVG assets).
class FoodIcon extends StatelessWidget {
  const FoodIcon(this.name, {super.key, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset('assets/icons/food/$name.svg', width: size, height: size),
  );
}

/// Illustration on a light tile, so its dark outlines stay visible on navy.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 48, this.color = C.tile});

  final String icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(R.sm)),
    alignment: Alignment.center,
    child: FoodIcon(icon, size: size * 0.74),
  );
}

class Footnote extends StatelessWidget {
  const Footnote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text('Estimates only. Not medical advice.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.top = 28});

  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
        ),
        ?trailing,
      ],
    ),
  );
}

class Label extends StatelessWidget {
  const Label(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color));
}

enum Tone { good, gap, value, plain }

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone = Tone.plain});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.good => (C.goodBg, C.good),
      Tone.gap || Tone.value => (C.warmBg, C.warm),
      Tone.plain => (C.surface2, C.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

/// Rounded panel. Navy with a hairline border by default.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color = C.surface});

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(R.lg),
      side: color == C.surface ? const BorderSide(color: C.line) : BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Selectable pill (diet, allergies, budget...). 46 px tall for thumbs.
class SelectPill extends StatelessWidget {
  const SelectPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.fast);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        child: AnimatedContainer(
          duration: d,
          curve: Motion.curve,
          decoration: ShapeDecoration(
            color: selected ? C.indigo2 : C.surface,
            shape: StadiumBorder(side: BorderSide(color: selected ? C.blue : C.line)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: d,
                        curve: Motion.curve,
                        child: selected
                            ? const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check, size: 16, color: Colors.white),
                              )
                            : icon != null
                            ? Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(icon, size: 16, color: C.ink2),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : C.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width choice row with a check.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({super.key, required this.title, this.subtitle, required this.selected, required this.onTap, this.leading});

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.fast);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: Pressable(
          scale: 0.98,
          child: AnimatedContainer(
            duration: d,
            curve: Motion.curve,
            decoration: ShapeDecoration(
              color: selected ? C.indigo2 : C.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.lg),
                side: BorderSide(color: selected ? C.blue : C.line, width: selected ? 1.5 : 1),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(R.lg),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      if (leading != null) ...[leading!, const SizedBox(width: 14)],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.titleMedium),
                            if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: d,
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(selected ? Icons.check_circle : Icons.circle_outlined, key: ValueKey(selected), color: selected ? Colors.white : C.ink3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 0.25, this.max = 20, this.step = 1, this.format});

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String label, double next, bool enabled) => IconButton.filledTonal(
      tooltip: label,
      onPressed: enabled ? () => onChanged(double.parse(next.toStringAsFixed(2))) : null,
      style: IconButton.styleFrom(
        backgroundColor: C.surface,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.surface,
        disabledForegroundColor: C.line,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon, size: 20),
    );
    final text = format?.call(value) ?? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, 'Less', value - step, value - step >= min - 0.001),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: c),
              ),
              child: Text(
                text,
                key: ValueKey(text),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          btn(Icons.add, 'More', value + step, value + step <= max + 0.001),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.body, this.icon = 'empty-plate'});

  final String title;
  final String? body;
  final String icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        IconTile(icon, size: 72),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        if (body != null) ...[const SizedBox(height: 4), Text(body!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)],
      ],
    ),
  );
}

/// Pronexa mark: a leaf and a seed, in white.
class PronexaMark extends StatelessWidget {
  const PronexaMark({super.key, this.width = 120});

  final double width;

  static const _svg =
      '<svg viewBox="0 0 170 124" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2 122C2 60 40 12 118 2c4 62-34 112-116 120Z" fill="#FFFFFF"/>'
      '<rect x="122" y="74" width="47" height="49" rx="6" fill="#FFFFFF"/></svg>';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pronexa',
    image: true,
    child: SvgPicture.string(_svg, width: width),
  );
}

/// Tappable rounded box that animates between idle and selected.
class SelectBox extends StatelessWidget {
  const SelectBox({super.key, required this.selected, required this.onTap, required this.child, this.padding = const EdgeInsets.all(12)});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Pressable(
    child: AnimatedContainer(
      duration: Motion.of(context, Motion.fast),
      curve: Motion.curve,
      decoration: ShapeDecoration(
        color: selected ? C.indigo2 : C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: BorderSide(color: selected ? C.blue : C.line, width: selected ? 1.5 : 1),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(R.lg),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}
