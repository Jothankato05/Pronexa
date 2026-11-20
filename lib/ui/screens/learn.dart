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
    ('Vitamin B12', 'Only from fortified foods or supplements.'),
    ('Iron', 'Beans, lentils, ugu. Add oranges or tomatoes.'),
    ('Calcium', 'Awara, fortified soy milk, greens.'),
    ('Zinc', 'Beans, groundnuts, seeds.'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final challenge = itemsProtein(const [
      MealItem(foodId: 'soya_chunks', portionId: PortionId.handful, qty: 1),
      MealItem(foodId: 'groundnuts', portionId: PortionId.sachet, qty: 1),
    ]);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, navClearance),
        children: [
          Text('Learn', style: text.headlineSmall),
          const SizedBox(height: 16),
          const Appear(
            child: Panel(
              color: C.indigo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rice and beans work together',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Beans and grains fill each other\'s gaps when eaten on the same day.',
                    style: TextStyle(color: C.onIndigo2, fontSize: 14, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('If you eat only plants'),
          Appear(
            index: 1,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (name, body) in _nutrients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.eco_outlined, size: 18, color: C.good),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: text.titleMedium),
                                Text(body, style: text.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SectionTitle('Coming later'),
          const Appear(
            index: 2,
            child: _Later(icon: Icons.menu_book_outlined, title: 'Protein lessons'),
          ),
          Appear(
            index: 3,
            child: _Later(icon: Icons.emoji_events_outlined, title: '₦500 protein challenge', body: 'Soya chunks + groundnuts: ${fmtRange(challenge)}'),
          ),
          const Appear(
            index: 4,
            child: _Later(icon: Icons.calendar_month_outlined, title: 'Plant-based meal planner'),
          ),
          const Appear(
            index: 5,
            child: _Later(icon: Icons.map_outlined, title: 'Campus protein map'),
          ),
          const Footnote(),
        ],
      ),
    );
  }
}

class _Later extends StatelessWidget {
  const _Later({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.sm)),
            child: Icon(icon, color: C.blueInk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (body != null) Text(body!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Tag('Soon'),
        ],
      ),
    ),
  );
}
