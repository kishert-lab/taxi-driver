import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../driver/domain/driver_profile.dart';
import '../../driver/presentation/driver_controllers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(driverProfileProvider).value;

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
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Row(label: 'Имя', value: profile.name),
                          _Row(label: 'Телефон', value: profile.phone),
                          _Row(
                            label: 'Рейтинг',
                            value: profile.rating.toStringAsFixed(2),
                          ),
                          _Row(
                            label: 'ВУ',
                            value: profile.licenseNumber ?? 'Не указано',
                          ),
                          _Row(
                            label: 'Проверка',
                            value: profile.isVerified
                                ? 'Проверен'
                                : 'Не проверен',
                          ),
                          _Row(label: 'Статус', value: profile.status.label),
                          const SizedBox(height: 12),
                          const Text(
                            'Автомобиль: будет показан после добавления backend-поля.',
                          ),
                        ],
                      ),
              ),
            ),
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
