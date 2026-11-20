import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../../state/app_state.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Profile, laid out like the Asteria settings screen: the target at the top,
/// then short rows that each show their value and open a sheet to change it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final s = state.settings;
    final target = state.target;
    final allergies = p.allergies.isEmpty
        ? 'None'
        : p.allergies.length == 1
        ? allergenLabels[p.allergies.first]!.split(' ').first
        : '${p.allergies.length} chosen';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        children: [
          Appear(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: C.indigo2, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${target.mid.round()} g a day', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.6)),
                      const SizedBox(height: 4),
                      Text(
                        fmtRange(target).toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1, color: C.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Label('You'),
          Appear(
            index: 1,
            child: Group(
              children: [
                _ValueRow(icon: Icons.restaurant_menu_outlined, title: 'Diet', value: dietLabels[p.diet]!.$1, onTap: () => _dietSheet(context, state)),
                _ValueRow(icon: Icons.no_food_outlined, title: 'Allergies', value: allergies, onTap: () => _allergySheet(context, state)),
                _ValueRow(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Weight',
                  value: '${p.weightKg ?? defaultWeightKg} kg',
                  onTap: () => _weightSheet(context, state),
                ),
                _ValueRow(icon: Icons.directions_walk, title: 'Activity', value: activityInfo[p.activity]!.label, onTap: () => _activitySheet(context, state)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Label('Data'),
          Appear(
            index: 2,
            child: Group(
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
          ),
          const SizedBox(height: 32),
          const Label('Demo'),
          Appear(
            index: 3,
            child: Group(
              children: [
                GroupRow(
                  icon: Icons.play_circle_outline,
                  title: 'Load a demo day',
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await state.loadDemoDay();
                    nav.pop();
                  },
                ),
                GroupRow(
                  icon: Icons.cloud_off_outlined,
                  title: 'Reader offline test',
                  trailing: Switch(
                    value: s.simulateAiDown,
                    onChanged: (v) => state.updateSettings(s.copyWith(simulateAiDown: v)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('${foods.length} foods · WAFCT 2019 and USDA · prices $pricesAsOf', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          const Footnote(),
        ],
      ),
    );
  }

  Future<void> _sheet(BuildContext context, String title, Widget Function(BuildContext sheet) body) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(title, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 24),
            body(sheet),
          ],
        ),
      ),
    ),
  );

  Future<void> _dietSheet(BuildContext context, AppState state) => _sheet(
    context,
    'Diet',
    (sheet) => Column(
      children: [
        for (final d in Diet.values)
          ChoiceRow(
            title: dietLabels[d]!.$1,
            subtitle: dietLabels[d]!.$2,
            selected: state.profile!.diet == d,
            onTap: () {
              state.saveProfile(state.profile!.copyWith(diet: d));
              Navigator.pop(sheet);
            },
          ),
      ],
    ),
  );

  Future<void> _activitySheet(BuildContext context, AppState state) => _sheet(
    context,
    'Activity',
    (sheet) => Column(
      children: [
        for (final a in Activity.values)
          ChoiceRow(
            title: activityInfo[a]!.label,
            subtitle: activityInfo[a]!.detail,
            selected: state.profile!.activity == a,
            onTap: () {
              state.saveProfile(state.profile!.copyWith(activity: a));
              Navigator.pop(sheet);
            },
          ),
      ],
    ),
  );

  Future<void> _allergySheet(BuildContext context, AppState state) => _sheet(
    context,
    'Allergies',
    (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final p = state.profile!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in Allergen.values)
                  SelectPill(
                    label: allergenLabels[a]!,
                    selected: p.allergies.contains(a),
                    onTap: () async {
                      await state.saveProfile(p.copyWith(allergies: p.allergies.contains(a) ? p.allergies.where((x) => x != a).toList() : [...p.allergies, a]));
                      setSheet(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('Done')),
          ],
        );
      },
    ),
  );

  Future<void> _weightSheet(BuildContext context, AppState state) => _sheet(
    context,
    'Weight',
    (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final p = state.profile!;
        final kg = p.weightKg ?? defaultWeightKg;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Text('$kg kg', style: Theme.of(sheet).textTheme.displaySmall)),
            const SizedBox(height: 20),
            Center(
              child: QtyStepper(
                value: kg.toDouble(),
                min: 30,
                max: 200,
                format: (v) => '${v.round()}',
                onChanged: (v) async {
                  await state.saveProfile(p.copyWith(weightKg: v.round()));
                  setSheet(() {});
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('Done')),
          ],
        );
      },
    ),
  );

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

/// A row that shows its current value and opens a sheet.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.title, required this.value, required this.onTap});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GroupRow(
    icon: icon,
    title: title,
    onTap: onTap,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: C.ink2),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: Color(0x59FFFFFF), size: 20),
      ],
    ),
  );
}
