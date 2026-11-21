import 'package:flutter/material.dart';

import '../../ai/types.dart';
import '../../ai/validator.dart';
import '../../data/foods.dart';
import '../../data/lessons.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/plans.dart';
import '../../logic/solver.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

void _log(BuildContext context, List<MealItem> items) => openConfirm(
  context,
  Draft(
    source: LogSource.quick,
    items: [for (final i in items) DraftItem(key: newKey(), item: i)],
  ),
);

/// One food in a list: tile, name, portion, protein.
class _FoodLine extends StatelessWidget {
  const _FoodLine(this.item);

  final MealItem item;

  @override
  Widget build(BuildContext context) {
    final f = foodById[item.foodId]!;
    return GroupRow(
      leading: IconTile(f.icon, size: 40),
      title: f.name,
      subtitle: portionLabel(f.id, item.portionId, item.qty),
      trailing: Text(
        fmtRange(itemProtein(item)),
        style: const TextStyle(color: C.blue, fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }
}

/// Number centred on the canvas with a caps caption (Asteria key feature).
class _Hero extends StatelessWidget {
  const _Hero({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 16),
      AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: Text(value, key: ValueKey(value), style: Theme.of(context).textTheme.displaySmall),
      ),
      const SizedBox(height: 10),
      Text(caption.toUpperCase(), style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
      const SizedBox(height: 32),
    ],
  );
}

// Lessons ---------------------------------------------------------------

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lesson')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
      children: [
        Text(lesson.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(lesson.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        for (final (i, p) in lesson.points.indexed)
          Appear(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: C.indigo2, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 16, height: 1.45, color: C.ink)),
                  ),
                ],
              ),
            ),
          ),
        const Footnote(),
      ],
    ),
  );
}

// ₦500 challenge --------------------------------------------------------

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  static const budget = 500;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final week = state.week();
    final closed = week.where((d) => d.logged && d.eaten.mid >= state.target.mid).length;
    final gap = state.todayMeals.isEmpty ? state.target : state.gap;
    final r = solve(gap: gap, budget: budget, diet: p.diet, allergies: p.allergies, plantFirst: true, meals: const []);
    final best = r.combos.isEmpty ? null : r.combos.first;
    return Scaffold(
      appBar: AppBar(title: const Text('₦500 challenge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        children: [
          _Hero(value: '$closed / 7', caption: 'Days this week you reached your target'),
          Text('Close the gap with no more than ₦500 of extra protein.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          if (gap.mid <= 0)
            const Group(
              children: [GroupRow(icon: Icons.check_circle_outline, title: 'Done for today', color: C.good)],
            )
          else if (best == null)
            const Group(
              children: [GroupRow(icon: Icons.info_outline, title: 'Nothing fits ₦500 for your diet')],
            )
          else ...[
            Label('Today: ${fmtRange(best.protein)} for ~${fmtNaira(best.cost)}'),
            Appear(child: Group(children: [for (final it in best.items) _FoodLine(it.item)])),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => _log(context, best.items.map((i) => i.item).toList()), child: const Text('I ate this')),
          ],
          const SizedBox(height: 32),
          if (r.ranked.isNotEmpty) ...[
            const Label('Other ways under ₦500'),
            Group(
              children: [
                for (final s in r.ranked.take(4))
                  GroupRow(
                    leading: IconTile(s.food.icon, size: 40),
                    title: s.food.name,
                    subtitle: fmtPrice(s.price),
                    trailing: Text(
                      '+${fmtRange(s.protein)}',
                      style: const TextStyle(color: C.blue, fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                    onTap: () => _log(context, [s.item]),
                  ),
              ],
            ),
          ],
          const Footnote(),
        ],
      ),
    );
  }
}

// Meal planner ----------------------------------------------------------

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  static const _budgets = [1500, 2500, 4000];
  int _budget = 2500;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final plans = planDays(target: state.target, budget: _budget, diet: p.diet, allergies: p.allergies);
    final plan = plans.isEmpty ? null : plans[_index % plans.length];
    return Scaffold(
      appBar: AppBar(title: const Text('Meal planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        children: [
          _Hero(
            value: plan == null ? '–' : fmtRange(plan.protein),
            caption: plan == null ? 'No plan fits this budget' : 'Protein for ~${fmtNaira(plan.cost)} · target ${fmtRange(state.target)}',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final b in _budgets)
                SelectPill(
                  label: fmtNaira(b),
                  selected: _budget == b,
                  onTap: () => setState(() {
                    _budget = b;
                    _index = 0;
                  }),
                ),
            ],
          ),
          if (plan != null) ...[
            FadeSwap(
              id: '$_budget-$_index',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in plan.meals) ...[
                    const SizedBox(height: 32),
                    Label('${m.slot} · ${fmtRange(m.protein)}'),
                    Group(
                      children: [
                        for (final it in m.items) _FoodLine(it),
                        GroupRow(icon: Icons.add, title: 'I ate this', trailing: const SizedBox.shrink(), onTap: () => _log(context, m.items)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (plans.length > 1) OutlinedButton(onPressed: () => setState(() => _index++), child: const Text('Another plan')),
          ],
          const Footnote(),
        ],
      ),
    );
  }
}
