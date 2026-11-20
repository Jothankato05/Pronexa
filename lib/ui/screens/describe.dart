import 'dart:async';

import 'package:flutter/material.dart';

import '../../ai/meal_reader.dart';
import '../../data/models.dart';
import '../draft.dart';
import '../nav.dart';
import '../scope.dart';
import '../theme.dart';
import '../widgets/assistant_pill.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

const _examples = ['₦1,000 rice and beans, medium takeaway', 'I chop 2 wraps of eba with egusi', 'Bread and 4 akara, ₦600', 'Garri and groundnut'];
const _steps = ['Reading', 'Matching foods', 'Checking the portion'];

class DescribeScreen extends StatefulWidget {
  const DescribeScreen({super.key, this.initialText = ''});

  final String initialText;

  @override
  State<DescribeScreen> createState() => _DescribeScreenState();
}

class _DescribeScreenState extends State<DescribeScreen> {
  final _pill = GlobalKey<AssistantPillState>();
  bool _busy = false;
  int _step = 0;
  Timer? _stepTimer;
  ReadFail? _fail;

  @override
  void initState() {
    super.initState();
    if (widget.initialText.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(widget.initialText));
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _run(String text) async {
    final state = AppScope.read(context);
    setState(() {
      _busy = true;
      _fail = null;
      _step = 0;
    });
    _stepTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted && _step < _steps.length - 1) setState(() => _step++);
    });
    final started = DateTime.now();
    final result = await state.reader.readText(text, online: state.online, aiDown: state.settings.simulateAiDown);
    // Short minimum so the status is readable rather than a flash.
    final wait = const Duration(milliseconds: 900) - DateTime.now().difference(started);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _stepTimer?.cancel();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case ReadOk(:final reading):
        await openConfirm(context, Draft.fromReading(reading, source: LogSource.describe, text: text));
      case final ReadFail fail:
        if (fail.reason != ReadFailure.empty) setState(() => _fail = fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fail = _fail;
    return Scaffold(
      appBar: AppBar(title: const Text('Describe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AssistantPill(
            key: _pill,
            examples: _examples,
            busy: _busy,
            status: _steps[_step],
            initialText: widget.initialText,
            autofocus: widget.initialText.isEmpty,
            onSubmit: _run,
          ),
          if (fail != null) ...[
            const SizedBox(height: 20),
            Appear(
              child: Panel(
                color: fail.reason == ReadFailure.nothingFound ? C.surface : C.warmBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (fail.reason) {
                      ReadFailure.nothingFound => fail.unknown.isEmpty ? 'No foods found' : '"${fail.unknown.first}" is not in the food list yet',
                      _ => 'The meal reader is not available',
                    }, style: text.titleMedium),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: () => openQuickPick(context), child: const Text('Pick from the list')),
                  ],
                ),
              ),
            ),
          ],
          if (!_busy) ...[
            const Padding(padding: EdgeInsets.only(top: 28, bottom: 10), child: Label('Examples')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, ex) in _examples.indexed)
                  Appear(
                    index: i,
                    child: SelectPill(
                      label: ex,
                      selected: false,
                      onTap: () {
                        _pill.currentState?.setText(ex);
                        unawaited(_run(ex));
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
