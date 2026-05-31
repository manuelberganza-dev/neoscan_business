import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/security/token_storage.dart';
import 'models/notification_item.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(dioClientProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(appConfigProvider),
  ),
);

final actionCableEventsProvider = StreamProvider<ActionCableEvent>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchRealtimeEvents();
});

class NotificationsRepository {
  const NotificationsRepository(this._dio, this._tokenStorage, this._config);

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AppConfig _config;

  Future<List<NotificationItem>> getNotifications({bool? unread}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'unread': ?unread},
      );
      final list = _unwrapList(response.data, key: 'notifications');
      return list.map(NotificationItem.fromJson).toList();
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(
        '/notifications/read_all',
        queryParameters: {'unread': true},
      );
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Stream<ActionCableEvent> watchRealtimeEvents() async* {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse(
      _config.actionCableBaseUrl,
    ).replace(queryParameters: {'token': token});
    final channel = WebSocketChannel.connect(uri);
    final output = StreamController<ActionCableEvent>();
    late final StreamSubscription<dynamic> subscription;

    void subscribe(String channelName) {
      channel.sink.add(
        jsonEncode({
          'command': 'subscribe',
          'identifier': jsonEncode({'channel': channelName}),
        }),
      );
    }

    subscription = channel.stream.listen(
      (raw) {
        final decoded = jsonDecode(raw.toString());
        if (decoded is! Map) return;

        final type = decoded['type'];
        if (type == 'welcome') {
          subscribe('NotificationChannel');
          subscribe('SalesChannel');
          subscribe('InventoryChannel');
          subscribe('PosChannel');
          return;
        }
        if (type == 'ping' || type == 'confirm_subscription') return;

        final message = decoded['message'];
        if (message is! Map) return;

        final identifier = decoded['identifier'] is String
            ? jsonDecode(decoded['identifier'] as String)
            : const {};
        final channelName = identifier is Map ? identifier['channel'] : null;

        output.add(
          ActionCableEvent(
            channel: channelName?.toString() ?? '',
            event: message['event']?.toString() ?? '',
            payload: Map<String, dynamic>.from(message),
          ),
        );
      },
      onError: output.addError,
      onDone: output.close,
      cancelOnError: false,
    );

    output.onCancel = () async {
      await subscription.cancel();
      await channel.sink.close();
    };

    yield* output.stream;
  }

  List<Map<String, dynamic>> _unwrapList(dynamic data, {required String key}) {
    if (data is Map && data[key] is List) {
      return List<Map<String, dynamic>>.from(data[key] as List);
    }
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }
}

class ActionCableEvent {
  const ActionCableEvent({
    required this.channel,
    required this.event,
    required this.payload,
  });

  final String channel;
  final String event;
  final Map<String, dynamic> payload;

  bool get isNotification => channel == 'NotificationChannel';
  bool get isSale => channel == 'SalesChannel';
}
