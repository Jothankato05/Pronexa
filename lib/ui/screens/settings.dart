import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/foods.dart';
import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final s = state.settings;
    final text = Theme.of(context).textTheme;
    final target = state.target;

    Future<void> setP(Profile next) => state.saveProfile(next);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Panel(
            color: C.leaf700,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: C.leaf600,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${target.mid.round()} g of protein a day',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                      Text('Range ${fmtRange(target)} · ${dietLabels[p.diet]!.$1}', style: const TextStyle(color: C.onGreen2, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Diet'),
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
          const SectionTitle('Allergies'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in Allergen.values)
                SelectPill(
                  label: allergenLabels[a]!,
                  selected: p.allergies.contains(a),
                  onTap: () => setP(p.copyWith(allergies: p.allergies.contains(a) ? (p.allergies.where((x) => x != a).toList()) : [...p.allergies, a])),
                ),
            ],
          ),
          const SectionTitle('Weight and activity'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.weightKg == null ? 'Weight not set ($defaultWeightKg kg used)' : 'Weight', style: text.titleMedium)),
                    QtyStepper(
                      value: (p.weightKg ?? defaultWeightKg).toDouble(),
                      min: 30,
                      max: 200,
                      format: (v) => '${v.round()} kg',
                      onChanged: (v) => setP(p.copyWith(weightKg: v.round())),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
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
                const SizedBox(height: 10),
                Text(
                  '${activityInfo[p.activity]!.low}–${activityInfo[p.activity]!.high} g per kg. Needs differ with age, pregnancy and illness.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SectionTitle('Data'),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Low-data mode'),
                  subtitle: const Text('Photos are never sent to the AI.'),
                  value: s.lowData,
                  onChanged: (v) => state.updateSettings(s.copyWith(lowData: v)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copy my data'),
                  subtitle: const Text('Your profile and meals as text.'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: state.exportJson()));
                    messenger.showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: C.clay700),
                  title: const Text('Delete all my data', style: TextStyle(color: C.clay700)),
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Everything is stored on this phone. No name, email or phone number is collected.', style: text.bodySmall),
          ),
          const SectionTitle('Demo'),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant_outlined),
                  title: const Text('Load a demo day'),
                  subtitle: const Text('Adds a sample breakfast and lunch for today.'),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await state.loadDemoDay();
                    nav.pop();
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Act as if the meal reader is down'),
                  subtitle: const Text('To show the fallback.'),
                  value: s.simulateAiDown,
                  onChanged: (v) => state.updateSettings(s.copyWith(simulateAiDown: v)),
                ),
              ],
            ),
          ),
          const SectionTitle('About the numbers'),
          Text(
            'Protein values: ${foods.length} foods (database v$dbVersion), from the West African Food Composition Table 2019 and USDA data, '
            'with typical campus portions. They still need review by a nutrition professional. Prices are from $pricesAsOf.',
            style: text.bodyMedium,
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
        backgroundColor: C.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete all data?'),
        content: const Text('Your profile, meals and settings will be removed from this phone. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.clay700),
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
