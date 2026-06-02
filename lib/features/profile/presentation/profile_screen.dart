import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../driver/domain/driver_profile.dart';
import '../../driver/presentation/driver_controllers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(driverProfileProvider);
    final profile = profileState.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(driverProfileProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: profile == null
                    ? const Text('Нет данных профиля')
                    : _ProfileContent(profile: profile),
              ),
            ),
            if (profileState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                profileState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(label: 'Имя', value: profile.name),
        _Row(label: 'Телефон', value: profile.phone),
        _Row(label: 'Рейтинг', value: profile.rating.toStringAsFixed(2)),
        _Row(label: 'ВУ', value: profile.licenseNumber ?? 'Не указано'),
        _Row(
          label: 'Проверка',
          value:
              profile.verificationStatus?.label ??
              (profile.isVerified ? 'Проверен' : 'Не проверен'),
        ),
        _Row(label: 'Статус', value: profile.status.label),
        const Divider(height: 28),
        _CarsBlock(cars: profile.attachedCars),
      ],
    );
  }
}

class _CarsBlock extends StatelessWidget {
  const _CarsBlock({required this.cars});

  final List<DriverCar> cars;

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) {
      return const _Row(label: 'Автомобиль', value: 'Не назначен');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          cars.length == 1 ? 'Автомобиль' : 'Автомобили',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final car in cars) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _Row(label: 'Автомобиль', value: car.title),
                  _Row(
                    label: 'Госномер',
                    value: car.plateNumber.isEmpty
                        ? 'Не указан'
                        : car.plateNumber,
                  ),
                  _Row(label: 'Класс', value: car.carClass ?? 'Не указан'),
                  _Row(
                    label: 'Проверка авто',
                    value: car.verificationStatus.label,
                  ),
                  _Row(
                    label: 'Статус',
                    value: car.isActive ? 'Активна' : 'Не активна',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
