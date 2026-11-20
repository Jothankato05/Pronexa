import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/calc.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _nutrients = [
    ('Vitamin B12', 'Only from fortified foods or supplements.'),
    ('Iron', 'Beans, lentils, ugu. Eat with oranges or tomatoes to absorb more.'),
    ('Calcium', 'Tofu (awara), fortified soy milk, leafy greens.'),
    ('Zinc', 'Beans, groundnuts, seeds, whole grains.'),
    ('Omega-3', 'Small amounts in soybeans and some seeds.'),
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
          const Panel(
            color: C.leaf700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rice and beans work together',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 6),
                Text(
                  'Beans and grains have different protein building blocks. Eaten on the same day, they complement each other.',
                  style: TextStyle(color: C.onGreen2, fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
          const SectionTitle('If you eat only plants'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrients to watch. For awareness, not medical advice.', style: text.bodySmall),
                const SizedBox(height: 8),
                for (final (name, body) in _nutrients)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.eco_outlined, size: 18, color: C.leaf600),
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
          const SectionTitle('Coming later'),
          const _Later(icon: Icons.menu_book_outlined, title: 'Protein lessons', body: 'Short lessons you can read offline.'),
          _Later(
            icon: Icons.emoji_events_outlined,
            title: '₦500 protein challenge',
            body: 'Example: soya chunks and a sachet of groundnuts is about ${fmtRange(challenge)} for under ₦500.',
          ),
          const _Later(icon: Icons.calendar_month_outlined, title: 'Plant-based meal planner', body: 'Cheap daily plans for vegan students.'),
          const _Later(icon: Icons.map_outlined, title: 'Campus protein map', body: 'Vendors and markets near campus.'),
          const Footnote(),
        ],
      ),
    );
  }
}

class _Later extends StatelessWidget {
  const _Later({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

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
            decoration: BoxDecoration(color: C.ochre100, borderRadius: BorderRadius.circular(R.sm)),
            child: Icon(icon, color: C.ochre800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Tag('Soon'),
        ],
      ),
    ),
  );
}
