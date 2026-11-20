import 'package:flutter/material.dart';

import '../nav.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

/// The four ways to log a meal, as one outlined group (Asteria settings).
class LogHomeScreen extends StatelessWidget {
  const LogHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, navClearance),
      children: [
        const PageTitle('Log a meal'),
        const SizedBox(height: 16),
        const Label('Choose how'),
        Appear(
          child: Group(
            children: [
              GroupRow(icon: Icons.grid_view_rounded, title: 'Pick', onTap: () => openQuickPick(context)),
              GroupRow(icon: Icons.takeout_dining_outlined, title: 'Portion', onTap: () => openPortion(context)),
              GroupRow(icon: Icons.photo_camera_outlined, title: 'Photo', onTap: () => openPhoto(context)),
              GroupRow(icon: Icons.edit_outlined, title: 'Describe', onTap: () => openDescribe(context)),
            ],
          ),
        ),
      ],
    ),
  );
}
