import 'package:flutter/material.dart';

import '../../ai/types.dart';
import '../../ai/validator.dart';
import '../../data/foods.dart';
import '../../data/models.dart';
import '../../data/portions.dart';
import '../draft.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

const _extraIds = [
  'beef',
  'chicken',
  'fish',
  'egg',
  'moi_moi',
  'akara',
  'tofu',
  'soya_chunks',
  'beans',
  'plantain',
  'stew',
  'egusi',
  'efo_riro',
  'okra',
  'ewedu',
  'groundnuts',
];
const _swallowExtras = ['egusi', 'efo_riro', 'okra', 'ewedu', 'beef', 'fish', 'chicken', 'tofu', 'soya_chunks'];
const _containerLabel = {
  PortionId.smPack: 'Small takeaway',
  PortionId.mdPack: 'Medium takeaway',
  PortionId.lgPack: 'Large takeaway',
  PortionId.plate: 'Plate',
  PortionId.bowl: 'Bowl',
  PortionId.wrap: 'Swallow wrap',
};

class PortionModeScreen extends StatefulWidget {
  const PortionModeScreen({super.key});

  @override
  State<PortionModeScreen> createState() => _PortionModeScreenState();
}

class _PortionModeScreenState extends State<PortionModeScreen> {
  int _step = 0;
  PortionId? _container;
  final _fill = <String>[];
  double _wraps = 1;
  final _extras = <String, double>{};
  double _eaten = 1;

  static const _titles = ['What did it come in?', 'What was in it?', 'Anything on the side?', 'How much did you eat?'];

  List<Food> get _fillFoods =>
      _container == null ? [] : foods.where((f) => f.hasPortion(_container!) && (f.group != FoodGroup.soup || _container == PortionId.bowl)).toList();

  void _finish() {
    final c = _container!;
    final share = 1 / (_fill.isEmpty ? 1 : _fill.length);
    final items = <DraftItem>[
      for (final id in _fill)
        DraftItem(
          key: newKey(),
          item: MealItem(foodId: id, portionId: c, qty: c == PortionId.wrap ? _wraps : double.parse(share.toStringAsFixed(2)), eaten: _eaten),
        ),
      for (final e in _extras.entries)
        if (e.value > 0)
          DraftItem(
            key: newKey(),
            item: MealItem(foodId: e.key, portionId: foodById[e.key]!.defaultPortion, qty: e.value, eaten: _eaten),
          ),
    ];
    openConfirm(context, Draft(source: LogSource.portion, items: items));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Portion · ${_step + 1} of 4')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: (_step + 1) / 4),
              duration: Motion.of(context, Motion.slow),
              curve: Motion.curve,
              builder: (context, v, _) => LinearProgressIndicator(value: v, borderRadius: BorderRadius.circular(4), minHeight: 4),
            ),
            const SizedBox(height: 32),
            FadeSwap(
              id: _step,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_titles[_step], style: text.headlineSmall),
                  const SizedBox(height: 28),
                  ...switch (_step) {
                    0 => [_containers()],
                    1 => _fillStep(),
                    2 => _extrasStep(),
                    _ => [_eatenStep()],
                  },
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _step == 0
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: FilledButton(
                    onPressed: _step == 1 && _fill.isEmpty ? null : () => _step == 3 ? _finish() : setState(() => _step++),
                    child: Text(_step == 3 ? 'Check my meal' : (_step == 2 && !_extras.values.any((v) => v > 0) ? 'Nothing else' : 'Next')),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _containers() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.82,
    children: [
      for (final c in containers)
        _Tile(
          icon: portionMeta[c]!.icon,
          title: _containerLabel[c]!,
          selected: _container == c,
          onTap: () => setState(() {
            _container = c;
            _fill.clear();
            _step = 1;
          }),
        ),
    ],
  );

  List<Widget> _fillStep() => [
    GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        for (final f in _fillFoods)
          _Tile(
            icon: f.icon,
            title: f.name,
            selected: _fill.contains(f.id),
            onTap: () => setState(() => _fill.contains(f.id) ? _fill.remove(f.id) : _fill.add(f.id)),
          ),
      ],
    ),
    if (_container == PortionId.wrap && _fill.isNotEmpty) ...[
      const SizedBox(height: 16),
      Appear(
        child: Group(
          children: [
            GroupRow(
              icon: Icons.circle_outlined,
              title: 'Wraps',
              trailing: QtyStepper(value: _wraps, min: 0.5, max: 6, step: 0.5, onChanged: (v) => setState(() => _wraps = v)),
            ),
          ],
        ),
      ),
    ],
  ];

  List<Widget> _extrasStep() => [
    Group(
      children: [
        for (final id in (_container == PortionId.wrap ? _swallowExtras : _extraIds).where((id) => !_fill.contains(id)))
          GroupRow(
            leading: IconTile(foodById[id]!.icon, size: 40),
            title: foodById[id]!.name,
            subtitle: portionMeta[foodById[id]!.defaultPortion]!.one,
            trailing: QtyStepper(value: _extras[id] ?? 0, min: 0, max: 10, onChanged: (v) => setState(() => _extras[id] = v)),
          ),
      ],
    ),
  ];

  Widget _eatenStep() => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.4,
    children: [for (final (v, label) in eatenOptions) _EatenTile(fraction: v, label: label, selected: _eaten == v, onTap: () => setState(() => _eaten = v))],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.selected, required this.onTap});

  final String icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: title,
    excludeSemantics: true,
    child: SelectBox(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTile(icon, size: 52),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selectInk(selected)),
          ),
        ],
      ),
    ),
  );
}

class _EatenTile extends StatelessWidget {
  const _EatenTile({required this.fraction, required this.label, required this.selected, required this.onTap});

  final double fraction;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: SelectBox(
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 22,
              backgroundColor: selected ? C.sTile : const Color(0x1FFFFFFF),
              color: selected ? C.indigo2 : C.blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: selectInk(selected)),
          ),
        ],
      ),
    ),
  );
}
