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

/// Illustration on a light tile, as in the Asteria list rows.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 48, this.color = C.tile});

  final String icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.28)),
    alignment: Alignment.center,
    child: FoodIcon(icon, size: size * 0.72),
  );
}

class Footnote extends StatelessWidget {
  const Footnote({super.key, this.onSheet = false});

  final bool onSheet;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(
      'Estimates only. Not medical advice.',
      style: TextStyle(fontSize: 12, color: onSheet ? C.sInk2 : C.ink3),
      textAlign: TextAlign.center,
    ),
  );
}

/// Caps label above a group, as in Asteria ("SYSTEM PROTOCOLS").
class Label extends StatelessWidget {
  const Label(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 14),
    child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
  );
}

/// Large screen title used at the top of tabs.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
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

/// Small blue badge ("SOON", "3 ACTIVE").
class Badge2 extends StatelessWidget {
  const Badge2(this.text, {super.key, this.color = C.blue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6.4)),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: color),
    ),
  );
}

/// Outlined group of rows (Asteria settings): radius 30, a 10% white outline,
/// 5% hairlines between rows.
class Group extends StatelessWidget {
  const Group({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(R.xl),
      border: Border.all(color: C.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(), children[i]],
        ],
      ),
    ),
  );
}

/// One row of a [Group]: blue icon, title, optional subtitle, trailing.
class GroupRow extends StatelessWidget {
  const GroupRow({super.key, this.icon, this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.color});

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ] else if (icon != null) ...[
              Icon(icon, color: color ?? C.blue, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
                  if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing! else if (onTap != null) const Icon(Icons.chevron_right, color: Color(0x59FFFFFF), size: 20),
          ],
        ),
      ),
    ),
  );
}

/// The white sheet with a rounded top that holds lists (Asteria "Flow History").
class WhiteSheet extends StatelessWidget {
  const WhiteSheet({super.key, required this.child, this.minHeight = 0});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight),
    decoration: const BoxDecoration(
      color: C.sheet,
      borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
    ),
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
    child: Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: C.sInk2, minimumSize: const Size(48, 40)),
        ),
        dividerTheme: const DividerThemeData(color: Color(0x0F000000), space: 1, thickness: 1),
      ),
      child: child,
    ),
  );
}

/// Section heading on a white sheet.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.trailing, this.top = 0});

  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.45, color: C.sInk),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A list row on a white sheet: tile, title and subtitle, value and sub-value.
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.value,
    this.valueSub,
    this.valueSubColor,
    this.onTap,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final String? value;
  final String? valueSub;
  final Color? valueSubColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(R.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconTile(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.sInk),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subtitleColor ?? C.sInk2),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.sInk),
                ),
                if (valueSub != null)
                  Text(
                    valueSub!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueSubColor ?? C.sInk2),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

/// Translucent chip (Asteria currency chips).
class SoftChip extends StatelessWidget {
  const SoftChip({super.key, required this.label, this.value, this.dim = false});

  final String label;
  final String? value;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dim ? 0.7 : 1,
    child: Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.fill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: Colors.white),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Text(
              value!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.ink2),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Selectable pill (diet, allergies, budget...). White when selected.
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
            color: selected ? Colors.white : C.fill,
            shape: StadiumBorder(side: BorderSide(color: selected ? Colors.white : C.line)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, size: 16, color: selected ? Colors.black : C.ink2), const SizedBox(width: 6)],
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: d,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontFamilyFallback: const ['NairaSign'],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.black : C.ink,
                          ),
                          child: Text(label),
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

/// Full-width pill choice (Asteria registration fields). White when selected.
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: Pressable(
          scale: 0.98,
          child: AnimatedContainer(
            duration: d,
            curve: Motion.curve,
            decoration: ShapeDecoration(
              color: selected ? Colors.white : Colors.transparent,
              shape: StadiumBorder(side: BorderSide(color: selected ? Colors.white : C.line)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 66),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(
                      children: [
                        if (leading != null) ...[leading!, const SizedBox(width: 14)],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: selected ? Colors.black : C.ink),
                              ),
                              if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12, color: selected ? C.sInk2 : C.ink3)),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: d,
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: selected
                              ? const Icon(Icons.check_circle, key: ValueKey(true), color: Colors.black, size: 22)
                              : const SizedBox(key: ValueKey(false), width: 22),
                        ),
                      ],
                    ),
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
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 0.25, this.max = 20, this.step = 1, this.format, this.onSheet = false});

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String Function(double)? format;
  final bool onSheet;

  @override
  Widget build(BuildContext context) {
    final fg = onSheet ? C.sInk : Colors.white;
    Widget btn(IconData icon, String label, double next, bool enabled) => IconButton(
      tooltip: label,
      onPressed: enabled ? () => onChanged(double.parse(next.toStringAsFixed(2))) : null,
      style: IconButton.styleFrom(foregroundColor: fg, disabledForegroundColor: fg.withValues(alpha: 0.25), minimumSize: const Size(44, 44)),
      icon: Icon(icon, size: 20),
    );
    final text = format?.call(value) ?? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    return Container(
      decoration: BoxDecoration(
        color: onSheet ? C.sTile : C.fill,
        borderRadius: BorderRadius.circular(99),
        border: onSheet ? null : Border.all(color: C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, 'Less', value - step, value - step >= min - 0.001),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
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
  const EmptyState({super.key, required this.title, this.icon = 'empty-plate', this.onSheet = false});

  final String title;
  final String icon;
  final bool onSheet;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        IconTile(icon),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSheet ? C.sInk2 : C.ink2),
          ),
        ),
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

/// Tappable rounded box that animates between idle and selected (white).
class SelectBox extends StatelessWidget {
  const SelectBox({super.key, required this.selected, required this.onTap, required this.child, this.padding = const EdgeInsets.all(14)});

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
        color: selected ? Colors.white : C.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: BorderSide(color: selected ? Colors.white : C.line),
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

/// Text colour inside a [SelectBox].
Color selectInk(bool selected) => selected ? C.sInk : C.ink;
Color selectInk2(bool selected) => selected ? C.sInk2 : C.ink3;

/// Back button used in pushed screens (Asteria chevron).
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: 'Back', onPressed: onPressed ?? () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20));
}
