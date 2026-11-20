import 'package:flutter/material.dart';

import '../scope.dart';
import '../theme.dart';
import '../widgets/bits.dart';
import 'learn.dart';
import 'log_home.dart';
import 'suggestions.dart';
import 'today.dart';

/// The four tabs with the floating pill navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static void goToTab(BuildContext context, int index) => context.findAncestorStateOfType<_HomeShellState>()?._go(index);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _lastCelebrate = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = AppScope.of(context).celebrateTick;
    if (tick > _lastCelebrate) {
      _lastCelebrate = tick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _celebrate();
      });
    }
  }

  Future<void> _celebrate() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      icon: const Icon(Icons.check_circle, color: C.leaf600, size: 56),
      title: const Text('Gap closed'),
      content: const Text("You've reached today's protein estimate.", textAlign: TextAlign.center),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = [TodayScreen(onTab: _go), const LogHomeScreen(), const SuggestionsScreen(), const LearnScreen()];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: Center(
              child: PillNav(index: _index, onTap: _go),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom space so content clears the floating nav.
const navClearance = 110.0;
