import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/async_state.dart';
import '../../orders/presentation/orders_controllers.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

class ChatViewData {
  const ChatViewData({
    required this.threadId,
    required this.chatType,
    required this.messages,
    this.isSending = false,
  });

  final String threadId;
  final String chatType;
  final List<ChatMessage> messages;
  final bool isSending;

  ChatViewData copyWith({
    String? threadId,
    String? chatType,
    List<ChatMessage>? messages,
    bool? isSending,
  }) {
    return ChatViewData(
      threadId: threadId ?? this.threadId,
      chatType: chatType ?? this.chatType,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatThreadMeta {
  const ChatThreadMeta({
    this.unreadCount = 0,
    this.isOpen = false,
    this.knownMessageKeys = const [],
  });

  final int unreadCount;
  final bool isOpen;
  final List<String> knownMessageKeys;

  ChatThreadMeta copyWith({
    int? unreadCount,
    bool? isOpen,
    List<String>? knownMessageKeys,
  }) {
    return ChatThreadMeta(
      unreadCount: unreadCount ?? this.unreadCount,
      isOpen: isOpen ?? this.isOpen,
      knownMessageKeys: knownMessageKeys ?? this.knownMessageKeys,
    );
  }
}

class _QueuedChatMessage {
  const _QueuedChatMessage({
    required this.clientId,
    required this.body,
    required this.createdAt,
  });

  final String clientId;
  final String body;
  final DateTime createdAt;
}

class ChatRealtimeBus {
  final _controller = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get stream => _controller.stream;

  void emit(ChatMessage message) {
    if (!_controller.isClosed) {
      _controller.add(message);
    }
  }

  void dispose() {
    _controller.close();
  }
}

class ChatThreadsController extends StateNotifier<Map<String, ChatThreadMeta>> {
  ChatThreadsController() : super(const {});

  void registerOpenThread(String orderId) {
    final current = state[orderId] ?? const ChatThreadMeta();
    state = {...state, orderId: current.copyWith(isOpen: true, unreadCount: 0)};
  }

  void unregisterOpenThread(String orderId) {
    final current = state[orderId];
    if (current == null) {
      return;
    }
    state = {...state, orderId: current.copyWith(isOpen: false)};
  }

  void markRead(String orderId) {
    final current = state[orderId] ?? const ChatThreadMeta();
    state = {...state, orderId: current.copyWith(unreadCount: 0)};
  }

  void applyThreadSnapshot(String orderId, List<ChatMessage> messages) {
    final current = state[orderId] ?? const ChatThreadMeta();
    final knownKeys = Set<String>.from(current.knownMessageKeys);
    var unreadCount = current.unreadCount;
    for (final message in messages) {
      final key = message.uniqueKey;
      if (knownKeys.add(key) && !current.isOpen && !message.isFromDriver) {
        unreadCount++;
      }
    }

    state = {
      ...state,
      orderId: current.copyWith(
        unreadCount: current.isOpen ? 0 : unreadCount,
        knownMessageKeys: _trimKnownKeys(knownKeys),
      ),
    };
  }

  void applyIncomingMessage(ChatMessage message) {
    final orderId = message.orderId;
    if (orderId.isEmpty) {
      return;
    }
    final current = state[orderId] ?? const ChatThreadMeta();
    final knownKeys = Set<String>.from(current.knownMessageKeys);
    if (!knownKeys.add(message.uniqueKey)) {
      return;
    }

    state = {
      ...state,
      orderId: current.copyWith(
        unreadCount: current.isOpen || message.isFromDriver
            ? 0
            : current.unreadCount + 1,
        knownMessageKeys: _trimKnownKeys(knownKeys),
      ),
    };
  }

  static List<String> _trimKnownKeys(Set<String> keys) {
    final list = keys.toList(growable: false);
    if (list.length <= 300) {
      return list;
    }
    return list.sublist(list.length - 300);
  }
}

final chatRealtimeBusProvider = Provider<ChatRealtimeBus>((ref) {
  final bus = ChatRealtimeBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final chatThreadsProvider =
    StateNotifierProvider<ChatThreadsController, Map<String, ChatThreadMeta>>((
      ref,
    ) {
      return ChatThreadsController();
    });

final dispatcherChatUnreadCountProvider = Provider.family<int, String>((
  ref,
  orderId,
) {
  final meta = ref.watch(chatThreadsProvider.select((value) => value[orderId]));
  return meta?.unreadCount ?? 0;
});

final dispatcherChatProvider = StateNotifierProvider.autoDispose
    .family<DispatcherChatController, Loadable<ChatViewData>, String>((
      ref,
      orderId,
    ) {
      return DispatcherChatController(
        ref,
        ref.watch(chatRepositoryProvider),
        orderId,
      );
    });

class DispatcherChatController extends StateNotifier<Loadable<ChatViewData>> {
  DispatcherChatController(this._ref, this._repository, this._orderId)
    : super(
        const Loadable.idle(
          ChatViewData(threadId: '', chatType: '', messages: []),
        ),
      ) {
    _subscription = _ref
        .read(chatRealtimeBusProvider)
        .stream
        .listen(_handleIncomingMessage);
  }

  final Ref _ref;
  final ChatRepository _repository;
  final String _orderId;
  final List<_QueuedChatMessage> _queue = [];
  StreamSubscription<ChatMessage>? _subscription;
  bool _flushInProgress = false;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = Loadable.loading(state.value);
    }

    try {
      final thread = await _repository.dispatcherMessages(_orderId);
      final mergedMessages = _mergeWithPending(thread.messages);
      state = Loadable.idle(
        ChatViewData(
          threadId: thread.threadId,
          chatType: thread.chatType,
          messages: mergedMessages,
          isSending: _flushInProgress,
        ),
      );
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> refreshIfActive() async {
    final currentOrder = _ref.read(currentOrderProvider).value;
    if (currentOrder?.orderId != _orderId || currentOrder?.isTerminal == true) {
      return;
    }
    await retryPendingMessages();
    await load(silent: true);
  }

  Future<void> send(String body) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final clientId = 'local_${now.microsecondsSinceEpoch}';
    final pendingMessage = ChatMessage.pending(
      clientId: clientId,
      orderId: _orderId,
      body: trimmedBody,
      createdAt: now,
    );
    _queue.add(
      _QueuedChatMessage(clientId: clientId, body: trimmedBody, createdAt: now),
    );

    final current =
        state.value ??
        const ChatViewData(threadId: '', chatType: '', messages: []);
    state = Loadable.idle(
      current.copyWith(
        messages: _sortedMessages([...current.messages, pendingMessage]),
        isSending: true,
      ),
    );

    await _flushQueue();
  }

  Future<void> retryPendingMessages() => _flushQueue();

  Future<void> _flushQueue() async {
    if (_flushInProgress || _queue.isEmpty) {
      state = Loadable.idle(
        (state.value ??
                const ChatViewData(threadId: '', chatType: '', messages: []))
            .copyWith(isSending: false),
      );
      return;
    }

    _flushInProgress = true;
    state = Loadable.idle(
      (state.value ??
              const ChatViewData(threadId: '', chatType: '', messages: []))
          .copyWith(isSending: true),
    );

    while (_queue.isNotEmpty) {
      final queued = _queue.first;
      try {
        final message = await _repository.sendDispatcherMessage(
          _orderId,
          queued.body,
        );
        _queue.removeAt(0);
        _applySentMessage(queued.clientId, message);
      } on ApiException catch (error) {
        if (_isRetryable(error)) {
          state = Loadable(
            isLoading: false,
            value: state.value?.copyWith(isSending: false),
            errorMessage: 'Сообщение будет отправлено при восстановлении связи',
          );
          _flushInProgress = false;
          return;
        }
        _dropQueuedMessage(queued.clientId, error.userMessage);
        _queue.removeAt(0);
      } catch (_) {
        state = Loadable(
          isLoading: false,
          value: state.value?.copyWith(isSending: false),
          errorMessage: 'Сообщение будет отправлено при восстановлении связи',
        );
        _flushInProgress = false;
        return;
      }
    }

    _flushInProgress = false;
    state = Loadable.idle(
      (state.value ??
              const ChatViewData(threadId: '', chatType: '', messages: []))
          .copyWith(isSending: false),
    );
  }

  void _handleIncomingMessage(ChatMessage message) {
    if (message.orderId != _orderId) {
      return;
    }
    final current =
        state.value ??
        const ChatViewData(threadId: '', chatType: '', messages: []);
    final exists = current.messages.any(
      (item) => item.uniqueKey == message.uniqueKey || item.id == message.id,
    );
    if (exists) {
      return;
    }

    final updated = current.copyWith(
      threadId: message.threadId.isEmpty ? current.threadId : message.threadId,
      chatType: message.chatType.isEmpty ? current.chatType : message.chatType,
      messages: _sortedMessages([...current.messages, message]),
      isSending: _flushInProgress,
    );
    state = Loadable.idle(updated);
  }

  List<ChatMessage> _mergeWithPending(List<ChatMessage> remoteMessages) {
    final pendingMessages = _queue
        .map(
          (item) => ChatMessage.pending(
            clientId: item.clientId,
            orderId: _orderId,
            body: item.body,
            createdAt: item.createdAt,
          ),
        )
        .toList(growable: false);
    return _sortedMessages([...remoteMessages, ...pendingMessages]);
  }

  void _applySentMessage(String clientId, ChatMessage message) {
    final current =
        state.value ??
        const ChatViewData(threadId: '', chatType: '', messages: []);
    final updatedMessages = current.messages
        .map((item) {
          if (item.clientId == clientId) {
            return message;
          }
          return item;
        })
        .toList(growable: false);

    state = Loadable.idle(
      current.copyWith(
        threadId: message.threadId.isEmpty
            ? current.threadId
            : message.threadId,
        chatType: message.chatType.isEmpty
            ? current.chatType
            : message.chatType,
        messages: _sortedMessages(updatedMessages),
        isSending: _queue.isNotEmpty,
      ),
    );
  }

  void _dropQueuedMessage(String clientId, String errorMessage) {
    final current =
        state.value ??
        const ChatViewData(threadId: '', chatType: '', messages: []);
    final updatedMessages = current.messages
        .where((item) => item.clientId != clientId)
        .toList(growable: false);
    state = Loadable(
      isLoading: false,
      value: current.copyWith(
        messages: updatedMessages,
        isSending: _queue.isNotEmpty,
      ),
      errorMessage: errorMessage,
    );
  }

  bool _isRetryable(ApiException error) {
    if (error.isUnauthorized || error.isForbidden || error.isOrderNotFound) {
      return false;
    }
    return true;
  }

  List<ChatMessage> _sortedMessages(List<ChatMessage> messages) {
    final unique = <String, ChatMessage>{};
    for (final message in messages) {
      unique[message.uniqueKey] = message;
    }
    final values = unique.values.toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
