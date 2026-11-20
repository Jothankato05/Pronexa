import 'package:flutter/material.dart';

import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/bits.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class LogHomeScreen extends StatelessWidget {
  const LogHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, navClearance),
        children: [
          Row(
            children: [
              Expanded(child: Text('Log a meal', style: Theme.of(context).textTheme.headlineSmall)),
              StatusPill(state: state),
            ],
          ),
          const SizedBox(height: 20),
          _Method(icon: 'moimoi', title: 'Pick', body: 'Tap foods from the list', tag: 'Offline', onTap: () => openQuickPick(context)),
          _Method(
            icon: 'pack-md',
            title: 'Portion',
            body: 'Choose the pack or plate, then how much you ate',
            tag: 'Offline',
            onTap: () => openPortion(context),
          ),
          _Method(icon: 'plate', title: 'Photo', body: 'Take a photo, then confirm the foods', onTap: () => openPhoto(context)),
          _Method(icon: 'ricebeans', title: 'Describe', body: '"₦1,000 rice and beans, medium pack"', onTap: () => openDescribe(context)),
          const SizedBox(height: 8),
          Text('You check every result before it is counted.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.icon, required this.title, required this.body, required this.onTap, this.tag});

  final String icon;
  final String title;
  final String body;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
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
              IconTile(icon, size: 56, color: C.leaf50),
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
              if (tag != null) Tag(tag!, tone: Tone.good) else const Icon(Icons.chevron_right, color: C.ink3),
            ],
          ),
        ),
      ),
    ),
  );
}
