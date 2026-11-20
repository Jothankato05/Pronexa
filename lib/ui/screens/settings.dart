import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Profile and data, laid out like the Asteria settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final s = state.settings;
    final target = state.target;

    Future<void> setP(Profile next) => state.saveProfile(next);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        children: [
          Appear(
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: C.indigo2, borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${target.mid.round()} g a day', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.6)),
                      const SizedBox(height: 4),
                      Text(
                        '${dietLabels[p.diet]!.$1} · ${fmtRange(target)}'.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: C.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Label('Diet'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in Diet.values)
                SelectPill(
                  label: dietLabels[d]!.$1,
                  selected: p.diet == d,
                  onTap: () => setP(p.copyWith(diet: d)),
                ),
            ],
          ),
          const SizedBox(height: 32),
          const Label('Allergies'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in Allergen.values)
                SelectPill(
                  label: allergenLabels[a]!,
                  selected: p.allergies.contains(a),
                  onTap: () => setP(p.copyWith(allergies: p.allergies.contains(a) ? p.allergies.where((x) => x != a).toList() : [...p.allergies, a])),
                ),
            ],
          ),
          const SizedBox(height: 32),
          const Label('Body'),
          Group(
            children: [
              GroupRow(
                icon: Icons.monitor_weight_outlined,
                title: 'Weight',
                trailing: QtyStepper(
                  value: (p.weightKg ?? defaultWeightKg).toDouble(),
                  min: 30,
                  max: 200,
                  format: (v) => '${v.round()}',
                  onChanged: (v) => setP(p.copyWith(weightKg: v.round())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in Activity.values)
                      SelectPill(
                        label: activityInfo[a]!.label,
                        selected: p.activity == a,
                        onTap: () => setP(p.copyWith(activity: a)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Label('Data'),
          Group(
            children: [
              GroupRow(
                icon: Icons.data_saver_on_outlined,
                title: 'Low-data mode',
                trailing: Switch(
                  value: s.lowData,
                  onChanged: (v) => state.updateSettings(s.copyWith(lowData: v)),
                ),
              ),
              GroupRow(
                icon: Icons.copy_outlined,
                title: 'Copy my data',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: state.exportJson()));
                  messenger.showSnackBar(const SnackBar(content: Text('Copied')));
                },
              ),
              GroupRow(icon: Icons.delete_outline, title: 'Delete all my data', color: C.warm, onTap: () => _confirmDelete(context)),
            ],
          ),
          const SizedBox(height: 32),
          const Label('Demo'),
          Group(
            children: [
              GroupRow(
                icon: Icons.restaurant_outlined,
                title: 'Load a demo day',
                onTap: () async {
                  final nav = Navigator.of(context);
                  await state.loadDemoDay();
                  nav.pop();
                },
              ),
              GroupRow(
                icon: Icons.cloud_off_outlined,
                title: 'Pretend the reader is down',
                trailing: Switch(
                  value: s.simulateAiDown,
                  onChanged: (v) => state.updateSettings(s.copyWith(simulateAiDown: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '${foods.length} foods from WAFCT 2019 and USDA. Prices from $pricesAsOf. Pending review by a nutritionist.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const Footnote(),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.warm, minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final nav = Navigator.of(context);
    await AppScope.read(context).resetAll();
    nav.popUntil((r) => r.isFirst);
  }
}
