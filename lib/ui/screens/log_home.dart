import 'package:flutter/material.dart';

import '../nav.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

class LogHomeScreen extends StatelessWidget {
  const LogHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = [
      ('moimoi', 'Pick', 'Tap foods from a list', () => openQuickPick(context)),
      ('pack-md', 'Portion', 'Pack, plate or wrap', () => openPortion(context)),
      ('plate', 'Photo', 'Snap it, then check', () => openPhoto(context)),
      ('ricebeans', 'Describe', 'Type it in your words', () => openDescribe(context)),
    ];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, navClearance),
        children: [
          Text('Log a meal', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          for (final (i, (icon, title, body, onTap)) in methods.indexed)
            Appear(
              index: i,
              child: _Method(icon: icon, title: title, body: body, onTap: onTap),
            ),
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.icon, required this.title, required this.body, required this.onTap});

  final String icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Pressable(
      scale: 0.98,
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: const BorderSide(color: C.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconTile(icon, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: C.ink3),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
