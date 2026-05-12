import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _phoneController = TextEditingController(text: '+79000000000');
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isCodeSent = authState.status == AuthStatus.codeSent;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход водителя')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Авторизация',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Введите номер телефона водителя. Токены сохраняются только в secure storage.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
              ),
            ),
            if (isCodeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SMS-код',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                authState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      if (isCodeSent) {
                        context.read<AuthCubit>().verifyCode(
                          _codeController.text.trim(),
                        );
                        return;
                      }
                      context.read<AuthCubit>().requestCode(
                        _phoneController.text.trim(),
                      );
                    },
              icon: Icon(
                isCodeSent ? Icons.verified_user_outlined : Icons.sms_outlined,
              ),
              label: Text(isCodeSent ? 'Подтвердить код' : 'Получить SMS-код'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => context.read<AuthCubit>().authenticateDemoSession(),
              icon: const Icon(Icons.developer_mode_outlined),
              label: const Text('Демо вход без backend'),
            ),
          ],
        ),
      ),
    );
  }
}
