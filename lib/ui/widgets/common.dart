import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

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

/// Icon on a soft tile, as used in lists.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 48, this.color = C.surface2});

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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline, size: 15, color: C.ink3),
        const SizedBox(width: 6),
        Flexible(child: Text('Estimates only. Not medical advice.', style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
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
      Tone.good => (C.leaf100, C.leaf700),
      Tone.gap => (C.clay100, C.clay700),
      Tone.value => (C.ochre100, C.ochre800),
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

/// White rounded panel with a hairline border.
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

/// Selectable pill (diet, allergies, budget...). 48 px tall for thumbs.
class SelectPill extends StatelessWidget {
  const SelectPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? C.leaf600 : C.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? C.leaf600 : C.line)),
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
                if (selected) ...[const Icon(Icons.check, size: 16, color: Colors.white), const SizedBox(width: 6)],
                if (icon != null && !selected) ...[Icon(icon, size: 16, color: C.ink2), const SizedBox(width: 6)],
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
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: selected ? C.leaf50 : C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: BorderSide(color: selected ? C.leaf600 : C.line, width: selected ? 1.5 : 1),
        ),
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
                Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? C.leaf600 : C.line),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
      style: IconButton.styleFrom(backgroundColor: C.surface, foregroundColor: C.leaf700, minimumSize: const Size(44, 44)),
      icon: Icon(icon, size: 20),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, 'Less', value - step, value - step >= min - 0.001),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              format?.call(value) ?? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          btn(Icons.add, 'More', value + step, value + step <= max + 0.001),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body, this.icon = 'empty-plate'});

  final String title;
  final String body;
  final String icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        FoodIcon(icon, size: 80),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(body, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Pronexa mark: a leaf and a seed. Flat colours.
class PronexaMark extends StatelessWidget {
  const PronexaMark({super.key, this.width = 120});

  final double width;

  static const _svg =
      '<svg viewBox="0 0 170 124" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2 122C2 60 40 12 118 2c4 62-34 112-116 120Z" fill="#FFFFFF"/>'
      '<rect x="122" y="74" width="47" height="49" rx="4" fill="#D9A441"/></svg>';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pronexa',
    image: true,
    child: SvgPicture.string(_svg, width: width),
  );
}
