import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpirationNotifier extends StateNotifier<int> {
  SessionExpirationNotifier() : super(0);

  void markExpired() {
    state++;
  }
}

final sessionExpirationProvider =
    StateNotifierProvider<SessionExpirationNotifier, int>(
      (ref) => SessionExpirationNotifier(),
    );
