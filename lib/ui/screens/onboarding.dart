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
            leading: BackChevron(onPressed: () => setState(() => _step--)),
            title: Semantics(
              label: 'Step $_step of 5',
              child: _Dots(step: _step),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
            children: [
              FadeSwap(
                id: _step,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: switch (_step) {
                    1 => [
                      Text('What do you eat?', style: text.headlineSmall),
                      const SizedBox(height: 32),
                      for (final d in Diet.values)
                        ChoiceRow(title: dietLabels[d]!.$1, subtitle: dietLabels[d]!.$2, selected: _diet == d, onTap: () => setState(() => _diet = d)),
                    ],
                    2 => [
                      Text('Any food allergies?', style: text.headlineSmall),
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 48),
                      Column(
                        children: [
                          Text(_weightKnown ? '$_weight kg' : 'Not sure', style: text.displaySmall),
                          const SizedBox(height: 24),
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
                      const SizedBox(height: 32),
                      for (final a in Activity.values)
                        ChoiceRow(
                          title: activityInfo[a]!.label,
                          subtitle: activityInfo[a]!.detail,
                          selected: _activity == a,
                          onTap: () => setState(() => _activity = a),
                        ),
                    ],
                    _ => [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
                        decoration: BoxDecoration(
                          color: C.indigo,
                          borderRadius: BorderRadius.circular(R.xl),
                          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 80, offset: Offset(0, 40))],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR DAILY PROTEIN',
                              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                CountUp(value: target.mid, style: text.displaySmall!.copyWith(fontSize: 56)),
                                Text(' g', style: text.displaySmall!.copyWith(fontSize: 56)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(fmtRange(target), style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('A health worker can give you a personal number.', style: text.bodySmall, textAlign: TextAlign.center),
                    ],
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
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

/// Step dots (Asteria key-feature pager): the current step is a white bar.
class _Dots extends StatelessWidget {
  const _Dots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        AnimatedContainer(
          duration: Motion.of(context, Motion.medium),
          curve: Motion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i == step ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(color: i <= step ? Colors.white : const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(4)),
        ),
    ],
  );
}

/// Welcome, after the Asteria splash: solid navy, the mark,
/// a short caps headline and one white button.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: lightIcons,
    child: Scaffold(
      body: ColoredBox(
        color: C.bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                const Center(child: Appear(offset: 24, child: PronexaMark(width: 150))),
                const Spacer(flex: 4),
                const Appear(
                  index: 2,
                  child: Text(
                    'CHECK YOUR PROTEIN',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500, height: 1, letterSpacing: -0.5),
                  ),
                ),
                const SizedBox(height: 10),
                const Appear(
                  index: 3,
                  child: Text('Close the gap for less.', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 16)),
                ),
                const SizedBox(height: 36),
                Appear(
                  index: 4,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: onStart, child: const Text('Start')),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
