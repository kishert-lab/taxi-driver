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

  DriverProfile? get currentProfile => state.value;

  Future<void> load() async {
    await refresh();
  }

  Future<DriverProfile?> refresh() async {
    state = Loadable.loading(state.value);
    try {
      final profile = await _repository.getProfile();
      state = Loadable.idle(profile);
      return profile;
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
      return state.value;
    }
  }

  void setProfile(DriverProfile profile) {
    state = Loadable.idle(profile);
  }
}

class DriverStatusController extends StateNotifier<Loadable<DriverStatus>> {
  DriverStatusController(this._repository, this._profileController)
    : super(const Loadable.idle());

  final DriverRepository _repository;
  final DriverProfileController _profileController;

  Future<void> goOnline() async {
    state = Loadable.loading(state.value);
    final profile =
        _profileController.currentProfile ?? await _profileController.refresh();
    if (profile == null) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: 'Не удалось проверить допуск к линии. Обновите профиль.',
      );
      return;
    }

    final blockReasons = profile.onlineBlockReasons();
    if (blockReasons.isNotEmpty) {
      state = Loadable(
        isLoading: false,
        value: profile.status,
        errorMessage: _formatOnlineBlockReasons(blockReasons),
      );
      return;
    }

    try {
      final updatedProfile = (await _repository.goOnline()).copyWith(
        status: DriverStatus.online,
        cars: profile.attachedCars,
      );
      _profileController.setProfile(updatedProfile);
      state = const Loadable.idle(DriverStatus.online);
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.isDriverNotAvailable
            ? _formatOnlineBlockReasons(profile.onlineBlockReasons())
            : error.userMessage,
      );
    }
  }

  Future<void> goOffline() async {
    state = Loadable.loading(state.value);
    final currentProfile = _profileController.currentProfile;
    try {
      final profile = (await _repository.goOffline()).copyWith(
        status: DriverStatus.offline,
        cars: currentProfile?.attachedCars,
      );
      _profileController.setProfile(profile);
      state = const Loadable.idle(DriverStatus.offline);
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

  String _formatOnlineBlockReasons(List<String> reasons) {
    if (reasons.isEmpty) {
      return 'Вы не можете выйти на линию. Проверьте статус проверки документов и автомобиля.';
    }
    return [
      'Вы не можете выйти на линию:',
      ...reasons.map((reason) => '• $reason'),
    ].join('\n');
  }
}
