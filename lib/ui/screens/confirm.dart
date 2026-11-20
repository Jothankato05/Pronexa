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
    await state.saveMeal(items: d.items.map((i) => i.item).toList(), source: d.source, text: d.text, price: d.price, editingId: d.editingId);
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (d.photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.lg),
                child: Image.memory(d.photo!, height: 140, width: double.infinity, fit: BoxFit.cover, semanticLabel: 'Your meal photo'),
              ),
            ),
          if (d.text != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('"${d.text}"', style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            ),
          if (d.confidence != null) _ConfidenceBar(d.confidence!),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: FadeSwap(
              id: q?.id ?? 'none',
              child: q == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Panel(
                        color: C.indigo,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.text, style: text.titleMedium),
                            const SizedBox(height: 10),
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
          const SectionTitle('Foods', top: 20),
          if (d.items.isEmpty)
            const Panel(
              child: EmptyState(title: 'No foods yet', body: 'Add what you ate.'),
            ),
          for (final (i, it) in d.items.indexed)
            Appear(
              key: ValueKey(it.key),
              index: i,
              child: _ItemCard(
                it: it,
                onChange: (next) => _update(it, next),
                onRemove: () => setState(() => d.items = d.items.where((x) => x.key != it.key).toList()),
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () async {
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
            icon: const Icon(Icons.add),
            label: const Text('Add a food'),
          ),
          if (d.notes.isNotEmpty || d.price != null) ...[
            const SizedBox(height: 16),
            Panel(
              color: C.surface2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [if (d.price != null) const _Note('Price is only a clue to the size.'), for (final n in d.notes) _Note(n)],
              ),
            ),
          ],
          if (d.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Panel(
              color: C.indigo,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'This meal',
                      style: TextStyle(color: C.onIndigo2, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fast),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                    child: Text(
                      fmtRange(total),
                      key: ValueKey(fmtRange(total)),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Footnote(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(onPressed: d.items.isEmpty || _saving ? null : _save, child: Text(d.editingId != null ? 'Save changes' : 'Add to today')),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.info_outline, size: 16, color: C.ink3),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar(this.c);
  final Confidence c;

  @override
  Widget build(BuildContext context) {
    final (title, bg, fg) = switch (c) {
      Confidence.high => ('Looks clear', C.goodBg, C.good),
      Confidence.medium => ('Check the marked parts', C.warmBg, C.warm),
      Confidence.low => ('Not sure. Check each food', C.warmBg, C.warm),
    };
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.medium),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c == Confidence.high ? Icons.check_circle_outline : Icons.help_outline, color: fg, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.it, required this.onChange, required this.onRemove});

  final DraftItem it;
  final ValueChanged<MealItem> onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final f = foodById[it.item.foodId]!;
    final p = itemProtein(it.item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(f.icon, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: _EditChip(
                    label: f.name,
                    guess: it.generic,
                    big: true,
                    onTap: () async {
                      final next = await pickFood(context, title: 'Change food');
                      if (next == null) return;
                      final keep = next.hasPortion(it.item.portionId);
                      onChange(
                        it.item.copyWith(foodId: next.id, portionId: keep ? it.item.portionId : next.defaultPortion, qty: keep ? it.item.qty : next.defaultQty),
                      );
                    },
                  ),
                ),
                IconButton(tooltip: 'Remove ${f.name}', onPressed: onRemove, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EditChip(label: portionLabel(f.id, it.item.portionId, it.item.qty), guess: it.isGuess, onTap: () => _portionSheet(context, f)),
                _EditChip(label: eatenLabel(it.item.eaten), onTap: () => _eatenSheet(context)),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  Expanded(child: Text(it.isGuess ? 'Check the size' : (f.local ?? ''), style: Theme.of(context).textTheme.bodySmall)),
                  Text(
                    fmtRange(p),
                    style: const TextStyle(color: C.blueInk, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _portionSheet(BuildContext context, Food f) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        var item = it.item;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How much ${f.name.toLowerCase()}?', style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final p in f.portions)
                  ChoiceRow(
                    leading: IconTile(portionMeta[p.id]!.icon, size: 40),
                    title: capitalise(p.label ?? portionMeta[p.id]!.one),
                    subtitle: p.price == null ? null : 'about ${fmtPrice(p.price!)}',
                    selected: item.portionId == p.id,
                    onTap: () {
                      item = item.copyWith(portionId: p.id);
                      onChange(item);
                      Navigator.pop(sheet);
                    },
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(
                      child: Text('How many?', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    QtyStepper(
                      value: item.qty,
                      step: portionMeta[item.portionId]!.container || item.qty < 1 ? 0.25 : 1,
                      format: fmtQty,
                      onChanged: (v) {
                        item = item.copyWith(qty: v);
                        onChange(item);
                        setSheet(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Future<void> _eatenSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How much did you eat?', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final (v, label) in eatenOptions)
              ChoiceRow(
                title: label,
                selected: it.item.eaten == v,
                onTap: () {
                  onChange(it.item.copyWith(eaten: v));
                  Navigator.pop(sheet);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _EditChip extends StatelessWidget {
  const _EditChip({required this.label, required this.onTap, this.guess = false, this.big = false});

  final String label;
  final VoidCallback onTap;
  final bool guess;
  final bool big;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label. Change',
    excludeSemantics: true,
    child: Material(
      color: guess ? C.warmBg : C.surface2,
      shape: StadiumBorder(side: BorderSide(color: guess ? C.warm : Colors.transparent)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: big ? 16 : 14, fontWeight: FontWeight.w500, color: guess ? C.warm : C.ink),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 14, color: guess ? C.warm : C.ink3),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
