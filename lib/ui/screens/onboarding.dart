import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../logic/calc.dart';
import '../../logic/diet.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Step 1: diet, allergies (asked separately), weight and activity, then the target.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  Diet? _diet;
  List<Allergen>? _allergies;
  int _weight = defaultWeightKg;
  bool _weightKnown = true;
  Activity? _activity;

  Profile get _profile =>
      Profile(diet: _diet ?? Diet.none, allergies: _allergies ?? const [], weightKg: _weightKnown ? _weight : null, activity: _activity ?? Activity.moderate);

  bool get _canContinue => switch (_step) {
    1 => _diet != null,
    2 => _allergies != null,
    4 => _activity != null,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _Welcome(onStart: () => setState(() => _step = 1));
    final text = Theme.of(context).textTheme;
    final target = proteinTarget(_profile);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _step--);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(tooltip: 'Back', onPressed: () => setState(() => _step--), icon: const Icon(Icons.arrow_back)),
            title: Text('Step $_step of 5'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: _step / 5),
                duration: Motion.of(context, Motion.slow),
                curve: Motion.curve,
                builder: (context, v, _) => LinearProgressIndicator(value: v, borderRadius: BorderRadius.circular(4), minHeight: 5),
              ),
              const SizedBox(height: 24),
              FadeSwap(
                id: _step,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: switch (_step) {
                    1 => [
                      Text('What do you eat?', style: text.headlineSmall),
                      const SizedBox(height: 20),
                      for (final d in Diet.values)
                        ChoiceRow(title: dietLabels[d]!.$1, subtitle: dietLabels[d]!.$2, selected: _diet == d, onTap: () => setState(() => _diet = d)),
                    ],
                    2 => [
                      Text('Any food allergies?', style: text.headlineSmall),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SelectPill(label: 'None', selected: _allergies != null && _allergies!.isEmpty, onTap: () => setState(() => _allergies = [])),
                          for (final a in Allergen.values)
                            SelectPill(
                              label: allergenLabels[a]!,
                              selected: _allergies?.contains(a) ?? false,
                              onTap: () => setState(() {
                                final cur = _allergies ?? <Allergen>[];
                                _allergies = cur.contains(a) ? cur.where((x) => x != a).toList() : [...cur, a];
                              }),
                            ),
                        ],
                      ),
                    ],
                    3 => [
                      Text('Your weight', style: text.headlineSmall),
                      const SizedBox(height: 24),
                      Panel(
                        child: Column(
                          children: [
                            Text(_weightKnown ? '$_weight kg' : 'Not sure', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                            QtyStepper(
                              value: _weight.toDouble(),
                              min: 30,
                              max: 200,
                              format: (v) => '${v.round()}',
                              onChanged: (v) => setState(() {
                                _weight = v.round();
                                _weightKnown = true;
                              }),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final kg in [45, 55, 65, 75, 85])
                                  SelectPill(
                                    label: '$kg',
                                    selected: _weightKnown && _weight == kg,
                                    onTap: () => setState(() {
                                      _weight = kg;
                                      _weightKnown = true;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectPill(
                        label: 'Not sure (use $defaultWeightKg kg)',
                        selected: !_weightKnown,
                        onTap: () => setState(() {
                          _weightKnown = !_weightKnown;
                          _weight = defaultWeightKg;
                        }),
                      ),
                    ],
                    4 => [
                      Text('How active are you?', style: text.headlineSmall),
                      const SizedBox(height: 20),
                      for (final a in Activity.values)
                        ChoiceRow(
                          title: activityInfo[a]!.label,
                          subtitle: activityInfo[a]!.detail,
                          selected: _activity == a,
                          onTap: () => setState(() => _activity = a),
                        ),
                    ],
                    _ => [
                      Panel(
                        color: C.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR DAILY PROTEIN',
                              style: TextStyle(color: C.onIndigo2, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                CountUp(
                                  value: target.mid,
                                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w500),
                                ),
                                const Text(
                                  ' g',
                                  style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(fmtRange(target), style: const TextStyle(color: C.onIndigo2, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('A health worker can give you a personal number.', style: text.bodySmall, textAlign: TextAlign.center),
                    ],
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                onPressed: !_canContinue
                    ? null
                    : _step == 5
                    ? () => AppScope.read(context).saveProfile(_profile)
                    : () => setState(() => _step++),
                child: Text(_step == 5 ? 'Start' : 'Continue'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: lightIcons,
    child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Center(child: Appear(offset: 24, child: PronexaMark(width: 120))),
              const Spacer(),
              const Appear(
                index: 2,
                child: Text(
                  'Pronexa',
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              const Appear(
                index: 3,
                child: Text('Check your protein. Close the gap for less.', style: TextStyle(color: C.ink2, fontSize: 17)),
              ),
              const SizedBox(height: 32),
              Appear(
                index: 4,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: onStart, child: const Text('Start')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
