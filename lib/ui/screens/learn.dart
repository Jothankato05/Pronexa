import 'package:flutter/material.dart';

import '../../data/lessons.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'extras.dart';
import 'home_shell.dart';

Future<void> _push(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _icons = [Icons.fitness_center, Icons.savings_outlined, Icons.rice_bowl_outlined, Icons.takeout_dining_outlined, Icons.eco_outlined];

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, navClearance),
      children: [
        const PageTitle('Learn'),
        const SizedBox(height: 16),
        const Label('Tools'),
        Appear(
          child: Group(
            children: [
              GroupRow(icon: Icons.emoji_events_outlined, title: '₦500 challenge', onTap: () => _push(context, const ChallengeScreen())),
              GroupRow(icon: Icons.calendar_month_outlined, title: 'Meal planner', onTap: () => _push(context, const PlannerScreen())),
              const GroupRow(icon: Icons.map_outlined, title: 'Campus map', trailing: Badge2('Soon')),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Label('Lessons'),
        Appear(
          index: 1,
          child: Group(
            children: [
              for (final (i, l) in lessons.indexed)
                GroupRow(
                  icon: _icons[i % _icons.length],
                  title: l.title,
                  subtitle: l.summary,
                  onTap: () => _push(context, LessonScreen(lesson: l)),
                ),
            ],
          ),
        ),
        const Footnote(),
      ],
    ),
  );
}
