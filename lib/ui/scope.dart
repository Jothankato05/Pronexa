import 'package:flutter/widgets.dart';

import '../state/app_state.dart';

/// Makes [AppState] available to every screen and rebuilds listeners on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Read and listen for changes.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read once (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
