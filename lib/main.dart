import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/app_state.dart';
import 'state/storage.dart';
import 'ui/scope.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(PronexaApp(state: AppState(storage: PrefsStorage())));
}

class PronexaApp extends StatefulWidget {
  const PronexaApp({super.key, required this.state, this.watchConnectivity = true});

  final AppState state;

  /// Off in widget tests (no platform channel).
  final bool watchConnectivity;

  @override
  State<PronexaApp> createState() => _PronexaAppState();
}

class _PronexaAppState extends State<PronexaApp> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    unawaited(widget.state.load());
    if (widget.watchConnectivity) {
      final connectivity = Connectivity();
      void apply(List<ConnectivityResult> r) => widget.state.setOnline(r.any((x) => x != ConnectivityResult.none));
      unawaited(connectivity.checkConnectivity().then(apply, onError: (Object _) {}));
      _sub = connectivity.onConnectivityChanged.listen(apply, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: widget.state,
    child: MaterialApp(title: 'Pronexa', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const _Root()),
  );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (state.profile == null) return const OnboardingScreen();
    return const HomeShell();
  }
}
