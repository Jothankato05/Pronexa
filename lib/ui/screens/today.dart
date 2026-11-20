import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/bits.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

/// Secondary text on the indigo header (white at 70%).
const _soft = Color(0xB3FFFFFF);

/// Today, laid out like the Asteria dashboard: an indigo header with the key
/// number and four actions, then a white sheet with the meals.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = state.todayMeals;
    final closed = list.isNotEmpty && state.gap.mid <= 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons,
      // Solid indigo behind everything, so the sheet's rounded corners and any
      // overscroll show the header colour. The white sheet fills the rest.
      child: ColoredBox(
        color: C.indigo,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(closed: closed)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: WhiteSheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SheetTitle(
                      "Today's meals",
                      trailing: list.isNotEmpty && !closed ? TextButton(onPressed: () => onTab(2), child: const Text('Close the gap')) : null,
                    ),
                    if (list.isEmpty) const Appear(child: EmptyState(title: 'Nothing logged yet', onSheet: true)),
                    for (final (i, m) in list.indexed)
                      Appear(
                        key: ValueKey(m.id),
                        index: i,
                        child: _MealRow(meal: m),
                      ),
                    if (closed)
                      const Appear(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: C.sGood, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gap closed for today',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: C.sGood),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.profile?.diet == Diet.vegan && list.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('B12: fortified foods or a supplement.', style: TextStyle(fontSize: 12, color: C.sInk2)),
                      ),
                    const Footnote(onSheet: true),
                    const SizedBox(height: navClearance - 24),
                  ],
                ),
              ),
            ),
          ],
        ),
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

    return Container(
      decoration: const BoxDecoration(color: C.indigo),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 8, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Profile and settings',
            style: IconButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero),
            onPressed: () => openSettings(context),
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(label: 'Target', value: '~${t.mid.round()} g'),
              SoftChip(label: 'Gap', value: closed ? 'closed' : fmtRange(hasMeals ? s.gap : t), dim: closed),
            ],
          ),
          const SizedBox(height: 36),
          Semantics(
            label: 'About ${e.mid.round()} grams of protein eaten today',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CountUp(value: e.mid, style: Theme.of(context).textTheme.displaySmall!),
                const Text(
                  ' g',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: _soft),
                ),
                const Spacer(),
                Text(hasMeals ? fmtRange(e) : 'eaten today', style: const TextStyle(color: _soft, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ProgressLine(value: e.mid, max: t.mid),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Action(icon: Icons.grid_view_rounded, label: 'Pick', primary: true, onTap: () => openQuickPick(context)),
              _Action(icon: Icons.takeout_dining_outlined, label: 'Portion', onTap: () => openPortion(context)),
              _Action(icon: Icons.photo_camera_outlined, label: 'Photo', onTap: () => openPhoto(context)),
              _Action(icon: Icons.edit_outlined, label: 'Describe', onTap: () => openDescribe(context)),
            ],
          ),
        ],
      ),
    );
  }
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
    child: Pressable(
      scale: 0.92,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.md),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primary ? Colors.white : C.fill,
                  borderRadius: BorderRadius.circular(17.8),
                  boxShadow: primary ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10))] : null,
                ),
                child: Icon(icon, color: primary ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: _soft),
              ),
            ],
          ),
        ),
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
    return SheetRow(
      icon: first?.icon ?? 'plate',
      title: title,
      subtitle: '$label · $time',
      value: '+${fmtRange(p)}',
      valueSub: 'protein',
      onTap: () => _openActions(context, title),
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheet);
                openConfirm(context, Draft.fromMeal(meal));
              },
              child: const Text('Edit'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: C.warm),
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
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    ),
  );
}
