import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/async_state.dart';
import '../domain/chat_models.dart';
import 'chat_controller.dart';

class DispatcherChatScreen extends ConsumerStatefulWidget {
  const DispatcherChatScreen({
    super.key,
    required this.orderId,
    this.title = 'Чат с парком',
  });

  final String orderId;
  final String title;

  @override
  ConsumerState<DispatcherChatScreen> createState() =>
      _DispatcherChatScreenState();
}

class _DispatcherChatScreenState extends ConsumerState<DispatcherChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshActiveOrderOnly(),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatcherChatProvider(widget.orderId));
    final data =
        state.value ??
        const ChatViewData(threadId: '', chatType: '', messages: []);

    ref.listen<Loadable<ChatViewData>>(dispatcherChatProvider(widget.orderId), (
      previous,
      next,
    ) {
      final previousCount = previous?.value?.messages.length ?? 0;
      final nextCount = next.value?.messages.length ?? 0;
      if (nextCount > previousCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: state.isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(onPressed: _load, child: const Text('Обновить')),
              ],
            ),
          Expanded(
            child: data.messages.isEmpty && state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.messages.isEmpty
                ? const Center(child: Text('Сообщений пока нет'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: data.messages.length,
                    itemBuilder: (context, index) {
                      final message = data.messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Сообщение диспетчеру',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: data.isSending ? null : _send,
                    icon: data.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _load() {
    ref.read(dispatcherChatProvider(widget.orderId).notifier).load();
  }

  void _refreshActiveOrderOnly() {
    ref.read(dispatcherChatProvider(widget.orderId).notifier).refreshIfActive();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) {
      return;
    }
    _messageController.clear();
    await ref.read(dispatcherChatProvider(widget.orderId).notifier).send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 72,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isOwn = message.isFromDriver;
    final alignment = isOwn ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isOwn
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isOwn
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Card(
          color: bubbleColor,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwn ? 'Вы' : 'Парк',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message.body, style: TextStyle(color: textColor)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat(
                        'dd.MM HH:mm',
                      ).format(message.createdAt.toLocal()),
                      style: TextStyle(color: textColor.withValues(alpha: 0.8)),
                    ),
                    if (message.isPending) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Отправляется',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
