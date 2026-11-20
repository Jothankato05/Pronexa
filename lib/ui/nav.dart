import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../data/models.dart';
import 'draft.dart';
import 'screens/confirm.dart';
import 'screens/describe.dart';
import 'screens/photo.dart';
import 'screens/portion_mode.dart';
import 'screens/quick_pick.dart';
import 'screens/settings.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

Future<void> openDescribe(BuildContext context, {String text = ''}) => _push(context, DescribeScreen(initialText: text));
Future<void> openQuickPick(BuildContext context, {Uint8List? photo}) => _push(context, QuickPickScreen(photo: photo));
Future<void> openPortion(BuildContext context) => _push(context, const PortionModeScreen());
Future<void> openPhoto(BuildContext context) => _push(context, const PhotoScreen());
Future<void> openConfirm(BuildContext context, Draft draft) => _push(context, ConfirmScreen(draft: draft));
Future<void> openSettings(BuildContext context) => _push(context, const SettingsScreen());

bool matchesQuery(Food f, String q) {
  final s = q.toLowerCase().trim();
  if (s.isEmpty) return true;
  return f.name.toLowerCase().contains(s) || (f.local ?? '').toLowerCase().contains(s) || f.aliases.any((a) => a.contains(s));
}

/// Searchable list of all foods in a bottom sheet.
Future<Food?> pickFood(BuildContext context, {String title = 'Choose a food'}) => showModalBottomSheet<Food>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _FoodPickerSheet(title: title),
);

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet({required this.title});

  final String title;

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = foods.where((f) => matchesQuery(f, _q)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  autofocus: false,
                  maxLength: 40,
                  decoration: const InputDecoration(hintText: 'Search: beans, eba, akara', prefixIcon: Icon(Icons.search), counterText: ''),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(title: 'Not in the list yet')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final g in groupOrder)
                        if (list.any((f) => f.group == g)) ...[
                          Padding(padding: const EdgeInsets.only(top: 16), child: Label(groupLabels[g]!)),
                          for (final f in list.where((f) => f.group == g))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: IconTile(f.icon, size: 44),
                              title: Text(f.name),
                              subtitle: f.local == null ? null : Text(f.local!, style: const TextStyle(color: C.ink3)),
                              onTap: () => Navigator.pop(context, f),
                            ),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String sourceLabel(LogSource s) => switch (s) {
  LogSource.quick => 'Picked',
  LogSource.portion => 'Portion',
  LogSource.describe => 'Described',
  LogSource.photo => 'Photo',
};
