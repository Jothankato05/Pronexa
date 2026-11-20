import 'dart:async';

import 'package:flutter/material.dart';

import '../../ai/meal_reader.dart';
import '../theme.dart';
import 'motion.dart';

/// The "describe a meal" bar, adapted from the Assistant Pill design:
/// a pill-shaped field with an orb on the left and a send button on the right.
/// Flat colours; the orb becomes a progress ring while a meal is being read.
class AssistantPill extends StatefulWidget {
  const AssistantPill({
    super.key,
    required this.onSubmit,
    this.examples = const [],
    this.busy = false,
    this.status,
    this.enabled = true,
    this.initialText = '',
    this.autofocus = false,
  });

  final ValueChanged<String> onSubmit;
  final List<String> examples;
  final bool busy;
  final String? status;
  final bool enabled;
  final String initialText;
  final bool autofocus;

  @override
  State<AssistantPill> createState() => AssistantPillState();
}

class AssistantPillState extends State<AssistantPill> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);
  final _focus = FocusNode();
  Timer? _timer;
  int _example = 0;

  void setText(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion && widget.examples.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted && _controller.text.isEmpty && !_focus.hasFocus) setState(() => _example = (_example + 1) % widget.examples.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy || !widget.enabled) return;
    _focus.unfocus();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.busy && widget.enabled;
    final hint = !widget.enabled
        ? 'Needs internet'
        : widget.examples.isEmpty
        ? 'Describe your meal'
        : widget.examples[_example];
    final showHint = _controller.text.isEmpty && !widget.busy;
    final d = Motion.of(context, Motion.medium);
    return AnimatedContainer(
      duration: d,
      curve: Motion.curve,
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: C.indigo,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _focus.hasFocus ? C.blue : C.indigo, width: 1.5),
      ),
      child: Row(
        children: [
          _Orb(busy: widget.busy, onTap: () => _focus.requestFocus()),
          const SizedBox(width: 12),
          Expanded(
            child: widget.busy
                ? Semantics(
                    liveRegion: true,
                    child: Text(widget.status ?? 'Reading…', style: const TextStyle(color: C.onIndigo2, fontSize: 15)),
                  )
                : Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      if (showHint)
                        IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: d,
                            transitionBuilder: (c, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                                child: c,
                              ),
                            ),
                            layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                            child: Text(
                              hint,
                              key: ValueKey(hint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: C.onIndigo2, fontSize: 15),
                            ),
                          ),
                        ),
                      TextField(
                        controller: _controller,
                        focusNode: _focus,
                        enabled: widget.enabled,
                        autofocus: widget.autofocus,
                        maxLength: maxTextLength,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        cursorColor: C.blue,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          // The visible hint is the animated text above; this one is for screen readers.
                          hintText: hint,
                          hintStyle: const TextStyle(color: Colors.transparent, fontSize: 15),
                          hintMaxLines: 1,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Read my meal',
            child: Pressable(
              scale: 0.9,
              child: AnimatedContainer(
                duration: d,
                curve: Motion.curve,
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: canSend ? Colors.white : C.indigo2, shape: BoxShape.circle),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: canSend ? _send : null,
                    child: Icon(Icons.arrow_upward, color: canSend ? C.indigo : C.onIndigo2, semanticLabel: 'Read my meal'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Type a meal',
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle),
            ),
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
            ),
            if (busy) const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
          ],
        ),
      ),
    ),
  );
}
