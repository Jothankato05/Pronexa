import 'package:flutter/material.dart';

import '../../ai/types.dart';
import '../../ai/validator.dart';
import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../../logic/solver.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

const _budgets = [300, 500, 1000, 2000];

void _logItems(BuildContext context, List<MealItem> items) => openConfirm(
  context,
  Draft(
    source: LogSource.quick,
    items: [for (final i in items) DraftItem(key: newKey(), item: i)],
  ),
);

/// Step 5: ways to close the gap, ranked by budget, diet and protein per naira.
/// Laid out like the Asteria key-feature screen: the number centred on the
/// dark canvas, the lists on a white sheet.
class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final s = state.settings;
    final vegan = p.diet == Diet.vegan;
    final plantFirst = vegan || s.plantFirst;
    final hasMeals = state.todayMeals.isNotEmpty;
    final gap = hasMeals ? state.gap : state.target;
    final closed = hasMeals && gap.mid <= 0;
    final r = solve(gap: gap, budget: s.budget, diet: p.diet, allergies: p.allergies, plantFirst: plantFirst, meals: state.todayMeals);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ColoredBox(
            color: C.bg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                child: Column(
                  children: [
                    const PageTitle('Close the gap'),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.medium),
                      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                      child: Text(
                        closed ? 'Closed' : fmtRange(gap),
                        key: ValueKey(closed ? 'closed' : fmtRange(gap)),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(hasMeals ? 'LEFT TO EAT TODAY' : "TODAY'S TARGET", style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final b in _budgets)
                          SelectPill(
                            label: b >= 1000 ? '₦${b ~/ 1000}k' : fmtNaira(b),
                            selected: s.budget == b,
                            onTap: () => state.updateSettings(s.copyWith(budget: b)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Group(
                      children: [
                        GroupRow(
                          icon: Icons.eco_outlined,
                          title: 'Plant protein first',
                          trailing: Switch(
                            value: plantFirst,
                            onChanged: vegan ? null : (v) => state.updateSettings(s.copyWith(plantFirst: v)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: WhiteSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!closed)
                  for (final (i, c) in r.combos.indexed)
                    Appear(
                      key: ValueKey('${c.title}-${s.budget}-$plantFirst'),
                      index: i,
                      child: _Combo(combo: c, top: i == 0 ? 0 : 24),
                    ),
                if (r.upgrades.isNotEmpty) ...[
                  SheetTitle(hasMeals ? 'Add to your meals' : 'Add to common meals', top: closed || r.combos.isEmpty ? 0 : 32),
                  for (final u in r.upgrades) _UpgradeRow(u: u),
                ],
                const SheetTitle('Most protein per ₦100', top: 32),
                if (r.ranked.isEmpty) const EmptyState(title: 'Nothing fits that budget', icon: 'handful', onSheet: true),
                for (final sug in r.ranked.take(8))
                  SheetRow(
                    icon: sug.food.icon,
                    title: sug.food.name,
                    subtitle: sug.caveat ?? portionLabel(sug.food.id, sug.item.portionId, sug.item.qty),
                    subtitleColor: sug.caveat != null ? C.sWarm : null,
                    value: '+${fmtRange(sug.protein)}',
                    valueSub: fmtPrice(sug.price),
                    onTap: () => _logItems(context, [sug.item]),
                  ),
                const SizedBox(height: 12),
                Text(
                  [
                    if (r.hiddenCount > 0) '${r.hiddenCount} hidden for ${dietLabels[p.diet]!.$1.toLowerCase()}${p.allergies.isEmpty ? '' : ' and allergies'}',
                    'Prices from $pricesAsOf',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: C.sInk2),
                ),
                const Footnote(onSheet: true),
                const SizedBox(height: navClearance - 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Combo extends StatelessWidget {
  const _Combo({required this.combo, required this.top});

  final Combo combo;
  final double top;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SheetTitle(
        combo.title,
        top: top,
        trailing: TextButton(onPressed: () => _logItems(context, combo.items.map((i) => i.item).toList()), child: const Text('I ate this')),
      ),
      for (final it in combo.items)
        SheetRow(
          icon: it.food.icon,
          title: it.food.name,
          subtitle: portionLabel(it.food.id, it.item.portionId, it.item.qty),
          value: '+${fmtRange(it.protein)}',
          valueSub: fmtPrice(it.price),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${fmtRange(combo.protein)} for ~${fmtNaira(combo.cost)}${combo.closesGap ? ' · closes the gap' : ''}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: combo.closesGap ? C.sGood : C.sInk2),
        ),
      ),
    ],
  );
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.u});
  final Upgrade u;

  @override
  Widget build(BuildContext context) {
    final f = u.suggestion.food;
    final change = u.swapFrom != null
        ? 'Swap ${u.swapFrom!.name.toLowerCase()} for ${f.name.toLowerCase()}'
        : 'Add ${portionLabel(f.id, u.suggestion.item.portionId, u.suggestion.item.qty)} ${f.name.toLowerCase()}';
    return SheetRow(
      icon: f.icon,
      title: change,
      subtitle: u.suggestion.caveat ?? u.title,
      subtitleColor: u.suggestion.caveat != null ? C.sWarm : null,
      value: '+${fmtRange(u.proteinChange)}',
      valueSub: '${u.costChange >= 0 ? '+' : '−'}${fmtNaira(u.costChange.abs())}',
      onTap: () => _logItems(context, [u.suggestion.item]),
    );
  }
}
