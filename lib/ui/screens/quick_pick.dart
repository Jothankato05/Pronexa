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
  const QuickPickScreen({super.key, this.photo, this.suggested = const []});

  final Uint8List? photo;

  /// Foods the on-phone recogniser saw in the photo. Shown first, not selected.
  final List<String> suggested;

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
      appBar: AppBar(title: Text(widget.photo == null ? 'Pick foods' : 'What\'s in it?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 120),
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
          if (widget.suggested.isNotEmpty && _q.isEmpty) ...[
            const Padding(padding: EdgeInsets.only(top: 28), child: Label('Looks like')),
            _Grid(ids: widget.suggested, picked: _picked, onTap: _toggle),
          ],
          if (showRecent) ...[
            const Padding(padding: EdgeInsets.only(top: 28), child: Label('Recent')),
            _Grid(ids: recent.take(6).toList(), picked: _picked, onTap: _toggle),
          ],
          for (final g in groupOrder)
            if (list.any((f) => f.group == g && (!showRecent || !recent.take(6).contains(f.id)))) ...[
              Padding(padding: const EdgeInsets.only(top: 28), child: Label(groupLabels[g]!)),
              _Grid(
                ids: list.where((f) => f.group == g && (!showRecent || !recent.take(6).contains(f.id))).map((f) => f.id).toList(),
                picked: _picked,
                onTap: _toggle,
              ),
            ],
          if (list.isEmpty) const EmptyState(title: 'Not in the list yet'),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.curve,
        child: _picked.isEmpty
            ? const SizedBox(width: double.infinity)
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: FilledButton(
                    onPressed: () =>
                        openConfirm(context, Draft.fromFoods(_picked, source: widget.photo == null ? LogSource.quick : LogSource.photo, photo: widget.photo)),
                    child: Text('Next: ${_picked.length} food${_picked.length == 1 ? '' : 's'}'),
                  ),
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
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.3,
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
    child: SelectBox(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(food.icon, size: 44),
              const Spacer(),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.fast),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: selected
                    ? const Icon(Icons.check_circle, key: ValueKey('on'), color: Colors.black, size: 22)
                    : food.altProtein
                    ? const Icon(Icons.eco_outlined, key: ValueKey('plant'), color: C.blue, size: 18)
                    : const SizedBox(key: ValueKey('off')),
              ),
            ],
          ),
          const Spacer(),
          Text(
            food.name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: selectInk(selected)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (food.local != null)
            Text(
              food.local!,
              style: TextStyle(fontSize: 12, color: selectInk2(selected)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );
}
