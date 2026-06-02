import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_controller.dart';
import 'dispatcher_chat_screen.dart';

class DispatcherChatButton extends ConsumerWidget {
  const DispatcherChatButton({
    super.key,
    required this.orderId,
    this.filled = false,
  });

  final String orderId;
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(dispatcherChatUnreadCountProvider(orderId));
    final child = Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 8),
            Text('Чат с парком'),
          ],
        ),
        if (unreadCount > 0)
          Positioned(
            right: -10,
            top: -10,
            child: _UnreadBadge(count: unreadCount),
          ),
      ],
    );

    void onPressed() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DispatcherChatScreen(orderId: orderId),
        ),
      );
    }

    if (filled) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
