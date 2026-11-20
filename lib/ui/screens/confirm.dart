import 'package:flutter/material.dart';

import '../../ai/types.dart';
import '../../ai/validator.dart';
import '../../data/foods.dart';
import '../../data/models.dart';
import '../../data/portions.dart';
import '../../logic/calc.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Step 3: the student checks and corrects what was understood. Nothing is
/// counted until "Add to today" is tapped.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key, required this.draft});

  final Draft draft;

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  Draft get d => widget.draft;
  bool _saving = false;

  void _update(DraftItem it, MealItem next) =>
      setState(() => d.items = [for (final x in d.items) x.key == it.key ? x.copyWith(item: next, source: PortionSource.stated, generic: false) : x]);

  void _answer(QuestionAction a) {
    setState(() {
      switch (a) {
        case SetPortion(:final key, :final portion):
          d.items = [
            for (final x in d.items)
              x.key == key
                  ? x.copyWith(
                      item: x.item.copyWith(portionId: portion, qty: 1),
                      source: PortionSource.stated,
                    )
                  : x,
          ];
        case SetFood(:final key, :final foodId):
          final f = foodById[foodId]!;
          d.items = [
            for (final x in d.items)
              x.key == key
                  ? x.copyWith(
                      item: x.item.copyWith(foodId: foodId, portionId: f.hasPortion(x.item.portionId) ? x.item.portionId : f.defaultPortion),
                      generic: false,
                    )
                  : x,
          ];
        case AddFood(:final foodId):
          final f = foodById[foodId]!;
          d.items = [
            ...d.items,
            DraftItem(
              key: newKey(),
              item: MealItem(foodId: foodId, portionId: f.defaultPortion, qty: f.defaultQty),
              source: PortionSource.defaulted,
            ),
          ];
          d.unknown = d.unknown.skip(1).toList();
        case Dismiss():
          d.unknown = d.unknown.skip(1).toList();
      }
      final next = pickQuestion(d.items, d.unknown);
      d.question = next != null && next.id != d.question?.id ? next : null;
      if (d.question == null && d.confidence != null) d.confidence = d.confidence == Confidence.low ? Confidence.medium : Confidence.high;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final total = itemsProtein(d.items.map((i) => i.item));
    await state.saveMeal(
      items: d.items.map((i) => i.item).toList(),
      source: d.source,
      text: d.text,
      price: d.price,
      editingId: d.editingId,
      photoFeatures: d.photoFeatures,
    );
    nav.popUntil((r) => r.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(d.editingId != null ? 'Meal updated' : 'Added: about ${fmtRange(total)} protein')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = itemsProtein(d.items.map((i) => i.item));
    final q = d.question;
    return Scaffold(
      appBar: AppBar(title: Text(d.editingId != null ? 'Edit meal' : 'Check your meal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
        children: [
          if (d.photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.xl),
                child: Image.memory(d.photo!, height: 160, width: double.infinity, fit: BoxFit.cover, semanticLabel: 'Your meal photo'),
              ),
            ),
          // The meal total, centred like the Asteria balance.
          Center(
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: Text(d.items.isEmpty ? '0 g' : fmtRange(total), key: ValueKey(fmtRange(total)), style: text.displaySmall),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Text('PROTEIN IN THIS MEAL', style: text.labelSmall)),
          if (d.confidence != null) ...[const SizedBox(height: 16), Center(child: _ConfidenceBar(d.confidence!))],
          if (d.text != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '"${d.text}"',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: FadeSwap(
              id: q?.id ?? 'none',
              child: q == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: C.indigo, borderRadius: BorderRadius.circular(R.xl)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.text, style: text.titleMedium),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [for (final o in q.options) SelectPill(label: o.label, selected: o.selected, onTap: () => _answer(o.action))],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          const Label('Foods'),
          Group(
            children: [
              if (d.items.isEmpty) const GroupRow(icon: Icons.restaurant_outlined, title: 'No foods yet'),
              for (final (i, it) in d.items.indexed)
                Appear(
                  key: ValueKey(it.key),
                  index: i,
                  child: _ItemRow(
                    it: it,
                    onChange: (next) => _update(it, next),
                    onRemove: () => setState(() => d.items = d.items.where((x) => x.key != it.key).toList()),
                  ),
                ),
              GroupRow(
                icon: Icons.add,
                title: 'Add a food',
                trailing: const SizedBox.shrink(),
                onTap: () async {
                  final f = await pickFood(context, title: 'Add a food');
                  if (f == null) return;
                  setState(
                    () => d.items = [
                      ...d.items,
                      DraftItem(
                        key: newKey(),
                        item: MealItem(foodId: f.id, portionId: f.defaultPortion, qty: f.defaultQty),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          if (d.notes.isNotEmpty || d.price != null) ...[
            const SizedBox(height: 20),
            for (final n in [if (d.price != null) 'Price is only a clue to the size.', ...d.notes])
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Text(n, style: text.bodySmall),
              ),
          ],
          const Footnote(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
          child: FilledButton(onPressed: d.items.isEmpty || _saving ? null : _save, child: Text(d.editingId != null ? 'Save changes' : 'Add to today')),
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar(this.c);
  final Confidence c;

  @override
  Widget build(BuildContext context) {
    final (title, fg) = switch (c) {
      Confidence.high => ('Looks clear', C.good),
      Confidence.medium => ('Check the marked parts', C.warm),
      Confidence.low => ('Not sure. Check each food', C.warm),
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.medium),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c == Confidence.high ? Icons.check_circle_outline : Icons.help_outline, color: fg, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One food: tile, name, size and amount, protein. Tap to change any of it.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.it, required this.onChange, required this.onRemove});

  final DraftItem it;
  final ValueChanged<MealItem> onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final f = foodById[it.item.foodId]!;
    final p = itemProtein(it.item);
    final detail = '${portionLabel(f.id, it.item.portionId, it.item.qty)} · ${eatenLabel(it.item.eaten).toLowerCase()}';
    return Semantics(
      button: true,
      label: '${f.name}, $detail, ${fmtRange(p)}. Change',
      excludeSemantics: true,
      child: GroupRow(
        leading: IconTile(f.icon, size: 44),
        title: it.generic ? '${f.name}?' : f.name,
        subtitle: it.isGuess ? 'Check size: $detail' : detail,
        trailing: Text(
          fmtRange(p),
          style: const TextStyle(color: C.blue, fontWeight: FontWeight.w500, fontSize: 15),
        ),
        onTap: () => _edit(context, f),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Food food) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      var item = it.item;
      var f = food;
      return StatefulBuilder(
        builder: (sheet, setSheet) {
          void set(MealItem next) {
            item = next;
            onChange(next);
            setSheet(() {});
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.85),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Row(
                    children: [
                      IconTile(f.icon, size: 44),
                      const SizedBox(width: 14),
                      Expanded(child: Text(f.name, style: Theme.of(sheet).textTheme.titleLarge)),
                      TextButton(
                        onPressed: () async {
                          final next = await pickFood(context, title: 'Change food');
                          if (next == null) return;
                          final keep = next.hasPortion(item.portionId);
                          f = next;
                          set(item.copyWith(foodId: next.id, portionId: keep ? item.portionId : next.defaultPortion, qty: keep ? item.qty : next.defaultQty));
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Label('Size'),
                  for (final p in f.portions)
                    ChoiceRow(
                      title: capitalise(p.label ?? portionMeta[p.id]!.one),
                      subtitle: p.price == null ? null : 'about ${fmtPrice(p.price!)}',
                      selected: item.portionId == p.id,
                      onTap: () => set(item.copyWith(portionId: p.id)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('How many', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      QtyStepper(
                        value: item.qty,
                        step: portionMeta[item.portionId]!.container || item.qty < 1 ? 0.25 : 1,
                        format: fmtQty,
                        onChanged: (v) => set(item.copyWith(qty: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Label('How much you ate'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (v, label) in eatenOptions)
                        SelectPill(
                          label: label,
                          selected: item.eaten == v,
                          onTap: () => set(item.copyWith(eaten: v)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('Done')),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: C.warm),
                    onPressed: () {
                      Navigator.pop(sheet);
                      onRemove();
                    },
                    child: Text('Remove ${f.name.toLowerCase()}'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
