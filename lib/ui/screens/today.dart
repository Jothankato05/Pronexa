import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/assistant_pill.dart';
import '../widgets/bits.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

const _examples = ['₦1,000 rice and beans, medium pack', 'Eba and egusi with one meat', 'Bread and 4 akara', 'Soaked garri and groundnut'];

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = state.todayMeals;
    final gap = state.gap;
    final closed = list.isNotEmpty && gap.mid <= 0;
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(closed: closed),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: AssistantPill(
              examples: _examples,
              onSubmit: (text) => openDescribe(context, text: text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, navClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  "Today's meals",
                  trailing: list.isNotEmpty && !closed ? TextButton(onPressed: () => onTab(2), child: const Text('Close the gap')) : null,
                ),
                if (list.isEmpty)
                  const Panel(
                    child: EmptyState(title: 'No meals logged today', body: 'Log your last meal. Bread and tea counts too.'),
                  )
                else
                  Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(children: [for (final m in list) _MealRow(meal: m)]),
                  ),
                if (closed) ...[
                  const SizedBox(height: 16),
                  Panel(
                    color: C.leaf100,
                    child: Text("You've reached today's estimate.", style: textTheme.titleMedium?.copyWith(color: C.leaf700)),
                  ),
                ],
                if (state.profile?.diet == Diet.vegan && list.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Vegan tip: get B12 from fortified foods or supplements.', style: textTheme.bodyMedium),
                ],
                const Footnote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.target;
    final e = s.eaten;
    final hasMeals = s.todayMeals.isNotEmpty;
    final now = s.now;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final date = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 28),
      decoration: const BoxDecoration(
        color: C.leaf700,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(R.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Profile and settings',
                onPressed: () => openSettings(context),
                icon: const Icon(Icons.person_outline, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  date,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.onGreen2, fontSize: 13),
                ),
              ),
              StatusPill(state: s, onGreen: true),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'Target', value: '~${t.mid.round()} g'),
              _MiniPill(label: 'Gap', value: closed ? 'closed' : fmtRange(hasMeals ? s.gap : t)),
              _MiniPill(label: dietLabels[s.profile!.diet]!.$1, value: null),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'About ${e.mid.round()} grams of protein eaten today',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${e.mid.round()}',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500, color: Colors.white, height: 1),
                            ),
                            const TextSpan(
                              text: ' g',
                              style: TextStyle(fontSize: 22, color: C.onGreen2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(hasMeals ? 'eaten, about ${fmtRange(e)}' : 'protein eaten today', style: const TextStyle(color: C.onGreen2, fontSize: 14)),
                  ],
                ),
              ),
              ProteinRing(value: e.mid, max: t.mid),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Action(icon: Icons.grid_view_rounded, label: 'Pick', primary: true, onTap: () => openQuickPick(context)),
              _Action(icon: Icons.takeout_dining_outlined, label: 'Portion', onTap: () => openPortion(context)),
              _Action(icon: Icons.photo_camera_outlined, label: 'Photo', onTap: () => openPhoto(context)),
              _Action(icon: Icons.edit_note, label: 'Describe', onTap: () => openDescribe(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: Colors.white),
          ),
          if (value != null)
            TextSpan(
              text: '  $value',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
        ],
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(R.md),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: primary ? Colors.white : Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(R.md)),
            child: Icon(icon, color: primary ? C.leaf700 : Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, letterSpacing: 1, color: C.onGreen2),
          ),
        ],
      ),
    ),
  );
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final p = itemsProtein(meal.items);
    final title = capitalise(describeItems(meal.items));
    final first = foodById[meal.items.first.foodId];
    final h = meal.time.hour;
    final label = h < 11
        ? 'Breakfast'
        : h < 16
        ? 'Lunch'
        : h < 21
        ? 'Dinner'
        : 'Late snack';
    final time = '${meal.time.hour.toString().padLeft(2, '0')}:${meal.time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () => _openActions(context, title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconTile(first?.icon ?? 'plate'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$label · $time', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+${fmtRange(p)}', style: Theme.of(context).textTheme.titleMedium),
                Text('protein', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context, String title) => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheet);
                openConfirm(context, Draft.fromMeal(meal));
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: C.clay700),
              onPressed: () async {
                Navigator.pop(sheet);
                final state = AppScope.read(context);
                final messenger = ScaffoldMessenger.of(context);
                final removed = await state.deleteMeal(meal.id);
                if (removed == null) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Meal removed'),
                    action: SnackBarAction(label: 'Undo', onPressed: () => state.restoreMeal(removed)),
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        ),
      ),
    ),
  );
}
