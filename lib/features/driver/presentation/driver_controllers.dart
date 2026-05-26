import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/async_state.dart';
import '../data/driver_repository.dart';
import '../domain/driver_profile.dart';

final driverProfileProvider =
    StateNotifierProvider<DriverProfileController, Loadable<DriverProfile>>((
      ref,
    ) {
      return DriverProfileController(ref.watch(driverRepositoryProvider));
    });

final driverStatusControllerProvider =
    StateNotifierProvider<DriverStatusController, Loadable<DriverStatus>>((
      ref,
    ) {
      return DriverStatusController(
        ref.watch(driverRepositoryProvider),
        ref.read(driverProfileProvider.notifier),
      );
    });

class DriverProfileController extends StateNotifier<Loadable<DriverProfile>> {
  DriverProfileController(this._repository) : super(const Loadable.idle());

  final DriverRepository _repository;

  Future<void> load() async {
    state = Loadable.loading(state.value);
    try {
      final profile = await _repository.getProfile();
      state = Loadable.idle(profile);
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }

  void setProfile(DriverProfile profile) {
    state = Loadable.idle(profile);
  }
}

class DriverStatusController extends StateNotifier<Loadable<DriverStatus>> {
  DriverStatusController(this._repository, this._profileController)
    : super(const Loadable.idle(DriverStatus.offline));

  final DriverRepository _repository;
  final DriverProfileController _profileController;

  Future<void> goOnline() async {
    state = Loadable.loading(state.value);
    try {
      final profile = await _repository.goOnline();
      _profileController.setProfile(profile);
      state = Loadable.idle(profile.status);
    } on ApiException catch (error) {
      if (error.isNotImplemented) {
        state = const Loadable(
          isLoading: false,
          value: DriverStatus.online,
          errorMessage: 'Функция пока недоступна на сервере.',
        );
        return;
      }
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> goOffline() async {
    state = Loadable.loading(state.value);
    try {
      final profile = await _repository.goOffline();
      _profileController.setProfile(profile);
      state = Loadable.idle(profile.status);
    } on ApiException catch (error) {
      if (error.isNotImplemented) {
        state = const Loadable(
          isLoading: false,
          value: DriverStatus.offline,
          errorMessage: 'Функция пока недоступна на сервере.',
        );
        return;
      }
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }

  void syncFromProfile(DriverProfile profile) {
    state = Loadable.idle(profile.status);
  }
}
