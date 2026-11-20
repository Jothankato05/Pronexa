import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/calc.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _nutrients = [
    ('Vitamin B12', 'Fortified foods or supplements'),
    ('Iron', 'Beans, lentils, ugu, with oranges'),
    ('Calcium', 'Awara, fortified soy milk, greens'),
    ('Zinc', 'Beans, groundnuts, seeds'),
  ];

  @override
  Widget build(BuildContext context) {
    final challenge = itemsProtein(const [
      MealItem(foodId: 'soya_chunks', portionId: PortionId.handful, qty: 1),
      MealItem(foodId: 'groundnuts', portionId: PortionId.sachet, qty: 1),
    ]);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, navClearance),
        children: [
          const PageTitle('Learn'),
          const SizedBox(height: 16),
          Appear(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: C.indigo, borderRadius: BorderRadius.circular(R.xl)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rice and beans work together', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text("Each fills the other's gaps when eaten the same day.", style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Label('If you eat only plants'),
          Appear(
            index: 1,
            child: Group(
              children: [for (final (name, body) in _nutrients) GroupRow(icon: Icons.eco_outlined, title: name, subtitle: body)],
            ),
          ),
          const SizedBox(height: 40),
          const Label('Coming later'),
          Appear(
            index: 2,
            child: Group(
              children: [
                const GroupRow(icon: Icons.menu_book_outlined, title: 'Protein lessons', trailing: Badge2('Soon')),
                GroupRow(
                  icon: Icons.emoji_events_outlined,
                  title: '₦500 challenge',
                  subtitle: 'Soya + groundnuts: ${fmtRange(challenge)}',
                  trailing: const Badge2('Soon'),
                ),
                const GroupRow(icon: Icons.calendar_month_outlined, title: 'Meal planner', trailing: Badge2('Soon')),
                const GroupRow(icon: Icons.map_outlined, title: 'Campus map', trailing: Badge2('Soon')),
              ],
            ),
          ),
          const Footnote(),
        ],
      ),
    );
  }
}
