import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/notification_item.dart';
import 'notifications_repository.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsViewModel, List<NotificationItem>>(
      NotificationsViewModel.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((item) => !item.read).length;
});

final salesFeedProvider =
    NotifierProvider<SalesFeedViewModel, List<SaleFeedItem>>(
      SalesFeedViewModel.new,
    );

class NotificationsViewModel extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    _listenRealtime();
    return ref.read(notificationsRepositoryProvider).getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }

  Future<void> markAsRead(NotificationItem item) async {
    if (item.read) return;
    final current = state.value ?? const <NotificationItem>[];
    state = AsyncData(
      current
          .map(
            (notification) => notification.id == item.id
                ? notification.copyWith(read: true)
                : notification,
          )
          .toList(),
    );
    await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
  }

  Future<void> markAllAsRead() async {
    final current = state.value ?? const <NotificationItem>[];
    state = AsyncData(
      current.map((item) => item.copyWith(read: true)).toList(),
    );
    await ref.read(notificationsRepositoryProvider).markAllAsRead();
  }

  void _listenRealtime() {
    ref.listen(actionCableEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null || !event.isNotification) return;

      final current = state.value ?? const <NotificationItem>[];
      final notification = NotificationItem.fromRealtime(event.payload);
      state = AsyncData([notification, ...current]);
    });
  }
}

class SalesFeedViewModel extends Notifier<List<SaleFeedItem>> {
  @override
  List<SaleFeedItem> build() {
    ref.listen(actionCableEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null || !event.isSale) return;

      final item = SaleFeedItem.fromRealtime(event.payload);
      state = [item, ...state].take(12).toList();
    });
    return const [];
  }
}
