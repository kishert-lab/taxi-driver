import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../realtime/realtime_controller.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        ref.read(realtimeControllerProvider.notifier).start();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Вход водителя')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Taxi Driver',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Войдите по номеру телефона и паролю.'),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
              onSubmitted: (_) => _login(),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: authState.errorMessage!),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loading ? null : _login,
              icon: const Icon(Icons.login_outlined),
              label: Text(loading ? 'Входим...' : 'Войти'),
            ),
          ],
        ),
      ),
    );
  }

  void _login() {
    ref
        .read(authControllerProvider.notifier)
        .login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
