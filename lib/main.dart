import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/app.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _keepScreenOn();
  await PushNotificationService.initialize();
  runApp(const ProviderScope(child: TaxiDriverApplication()));
}

Future<void> _keepScreenOn() async {
  try {
    await WakelockPlus.enable();
  } catch (error) {
    debugPrint('wakelock enable failed: $error');
  }
}
