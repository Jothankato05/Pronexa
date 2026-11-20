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
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, navClearance),
        children: [
          Text('Close the gap', style: text.headlineSmall),
          const SizedBox(height: 16),
          Panel(
            color: C.leaf700,
            padding: const EdgeInsets.all(24),
            child: closed
                ? const Text(
                    "Today's gap is closed.",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasMeals ? 'LEFT TO EAT TODAY' : 'TODAY\'S TARGET',
                        style: const TextStyle(color: C.onGreen2, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fmtRange(gap),
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w500, height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      const Text('protein, estimated', style: TextStyle(color: C.onGreen2, fontSize: 14)),
                    ],
                  ),
          ),
          const Padding(padding: EdgeInsets.only(top: 20, bottom: 10), child: Label('Budget')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in _budgets)
                SelectPill(
                  label: fmtNaira(b),
                  selected: s.budget == b,
                  onTap: () => state.updateSettings(s.copyWith(budget: b)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Plant protein first'),
              subtitle: Text(vegan ? 'Always on for vegan.' : 'Beans, soy and groundnuts first.'),
              value: plantFirst,
              onChanged: vegan ? null : (v) => state.updateSettings(s.copyWith(plantFirst: v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'For ${dietLabels[p.diet]!.$1.toLowerCase()}${p.allergies.isEmpty ? '' : ', no ${p.allergies.map((a) => allergenLabels[a]!.toLowerCase()).join(', ')}'}. Change in your profile.',
              style: text.bodySmall,
            ),
          ),
          if (!closed && r.combos.isNotEmpty) ...[const SectionTitle('Ways to close it'), for (final c in r.combos) _ComboCard(combo: c, gap: gap)],
          if (r.upgrades.isNotEmpty) ...[
            SectionTitle(hasMeals ? 'Add to your meals' : 'Add to common meals'),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < r.upgrades.length; i++) ...[if (i > 0) const Divider(), _UpgradeRow(u: r.upgrades[i])],
                ],
              ),
            ),
          ],
          const SectionTitle('Most protein for your money'),
          if (r.ranked.isEmpty)
            const Panel(
              child: EmptyState(title: 'Nothing fits that budget', body: 'Try a bigger budget.', icon: 'handful'),
            )
          else
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < r.ranked.take(8).length; i++) ...[if (i > 0) const Divider(), _SuggestionRow(s: r.ranked[i])],
                ],
              ),
            ),
          if (r.hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('${r.hiddenCount} foods hidden for your diet or allergies.', style: text.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Prices are typical campus prices from $pricesAsOf and vary by vendor.', style: text.bodySmall),
          ),
          const Footnote(),
        ],
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.combo, required this.gap});

  final Combo combo;
  final Range gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(combo.title, style: Theme.of(context).textTheme.titleMedium)),
              Tag(
                combo.closesGap ? 'Closes it' : '${(combo.protein.mid / (gap.mid == 0 ? 1 : gap.mid) * 100).round()}% of gap',
                tone: combo.closesGap ? Tone.good : Tone.gap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final it in combo.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  IconTile(it.food.icon, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.food.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(portionLabel(it.food.id, it.item.portionId, it.item.qty), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    '+${fmtRange(it.protein)}',
                    style: const TextStyle(color: C.leaf700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('About ${fmtRange(combo.protein)} for ~${fmtNaira(combo.cost)}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              TextButton(onPressed: () => _logItems(context, combo.items.map((i) => i.item).toList()), child: const Text('I ate this')),
            ],
          ),
        ],
      ),
    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(u.title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            change,
            style: const TextStyle(fontWeight: FontWeight.w500, color: C.leaf700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag('+${fmtRange(u.proteinChange)}', tone: Tone.good),
              Tag('${u.costChange >= 0 ? '+' : '−'}${fmtNaira(u.costChange.abs())}'),
              Tag('${u.suggestion.per100.toStringAsFixed(1)} g per ₦100', tone: Tone.value),
            ],
          ),
          if (u.suggestion.caveat != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(u.suggestion.caveat!, style: const TextStyle(color: C.ochre800, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.s});
  final Suggestion s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(s.food.icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(s.food.name, style: Theme.of(context).textTheme.titleMedium)),
                  Text(
                    '+${fmtRange(s.protein)}',
                    style: const TextStyle(color: C.leaf700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(portionLabel(s.food.id, s.item.portionId, s.item.qty), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Tag(fmtPrice(s.price)),
                  Tag('${s.per100.toStringAsFixed(1)} g per ₦100', tone: Tone.value),
                  if (s.gapShare > 0) Tag('${(s.gapShare * 100).round()}% of gap', tone: Tone.good),
                ],
              ),
              if (s.food.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(s.food.note!, style: Theme.of(context).textTheme.bodyMedium),
                ),
              if (s.caveat != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(s.caveat!, style: const TextStyle(color: C.ochre800, fontSize: 13)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => _logItems(context, [s.item]),
                  child: const Text('I ate this'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
