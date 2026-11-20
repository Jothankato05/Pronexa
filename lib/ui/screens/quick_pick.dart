import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Tap the foods in the meal. Works offline. If a photo is passed in (Photo mode
/// without AI), it is shown at the top as a reference.
class QuickPickScreen extends StatefulWidget {
  const QuickPickScreen({super.key, this.photo});

  final Uint8List? photo;

  @override
  State<QuickPickScreen> createState() => _QuickPickScreenState();
}

class _QuickPickScreenState extends State<QuickPickScreen> {
  final _picked = <String>[];
  String _q = '';

  void _toggle(String id) => setState(() => _picked.contains(id) ? _picked.remove(id) : _picked.add(id));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final recent = <String>[];
    for (final m in [...state.meals]..sort((a, b) => b.time.compareTo(a.time))) {
      for (final i in m.items) {
        if (!recent.contains(i.foodId) && foodById.containsKey(i.foodId)) recent.add(i.foodId);
      }
      if (recent.length >= 6) break;
    }
    final list = foods.where((f) => matchesQuery(f, _q)).toList();
    final showRecent = _q.isEmpty && recent.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.photo == null ? 'Pick foods' : 'What is in the photo?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          if (widget.photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(R.lg),
              child: Image.memory(widget.photo!, height: 200, width: double.infinity, fit: BoxFit.cover, semanticLabel: 'Your meal photo'),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            maxLength: 40,
            decoration: const InputDecoration(hintText: 'Search: beans, eba, akara', prefixIcon: Icon(Icons.search), counterText: ''),
            onChanged: (v) => setState(() => _q = v),
          ),
          if (showRecent) ...[
            const Padding(padding: EdgeInsets.only(top: 20, bottom: 10), child: Label('Recent')),
            _Grid(ids: recent.take(6).toList(), picked: _picked, onTap: _toggle),
          ],
          for (final g in groupOrder)
            if (list.any((f) => f.group == g && (!showRecent || !recent.take(6).contains(f.id)))) ...[
              Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Label(groupLabels[g]!)),
              _Grid(
                ids: list.where((f) => f.group == g && (!showRecent || !recent.take(6).contains(f.id))).map((f) => f.id).toList(),
                picked: _picked,
                onTap: _toggle,
              ),
            ],
          if (list.isEmpty) const EmptyState(title: 'Not in the list yet', body: 'Try another word, like "swallow" or "soup".'),
        ],
      ),
      bottomNavigationBar: _picked.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () =>
                      openConfirm(context, Draft.fromFoods(_picked, source: widget.photo == null ? LogSource.quick : LogSource.photo, photo: widget.photo)),
                  child: Text('Next: ${_picked.length} food${_picked.length == 1 ? '' : 's'}'),
                ),
              ),
            ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.ids, required this.picked, required this.onTap});

  final List<String> ids;
  final List<String> picked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.35,
    children: [for (final id in ids) _FoodTile(food: foodById[id]!, selected: picked.contains(id), onTap: () => onTap(id))],
  );
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.selected, required this.onTap});

  final Food food;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: food.name,
    excludeSemantics: true,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconTile(food.icon, size: 44, color: selected ? C.surface : C.surface2),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle, color: C.leaf600, size: 22)
                  else if (food.altProtein)
                    const Icon(Icons.eco_outlined, color: C.leaf600, size: 18),
                ],
              ),
              const Spacer(),
              Text(food.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (food.local != null) Text(food.local!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    ),
  );
}
