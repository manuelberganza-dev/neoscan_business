import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/notification_item.dart';
import '../notifications_viewmodel.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          unreadCount > 0 ? 'Notificaciones ($unreadCount)' : 'Notificaciones',
        ),
        actions: [
          IconButton(
            tooltip: 'Marcar todo como leído',
            onPressed: unreadCount == 0
                ? null
                : () =>
                      ref.read(notificationsProvider.notifier).markAllAsRead(),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationTile(
                  item: item,
                  onTap: () =>
                      ref.read(notificationsProvider.notifier).markAsRead(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: _color.withValues(alpha: 0.12),
              child: Icon(_icon, color: _color),
            ),
            if (!item.read)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          item.body ?? _metadataPreview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          _timeLabel(item.createdAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
      ),
    );
  }

  Color get _color {
    return switch (item.event) {
      'low_stock' => AppColors.warning,
      'sale_created' || 'purchase_received' || 'ocr_ready' => AppColors.success,
      'sale_voided' => AppColors.danger,
      _ => AppColors.primary,
    };
  }

  IconData get _icon {
    return switch (item.event) {
      'low_stock' => Icons.warning_amber_rounded,
      'sale_created' => Icons.point_of_sale_rounded,
      'purchase_received' => Icons.inventory_2_rounded,
      'ocr_ready' => Icons.receipt_long_rounded,
      _ => Icons.notifications_outlined,
    };
  }

  String get _metadataPreview {
    if (item.metadata.isEmpty) return item.event;
    return item.metadata.entries
        .take(2)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' · ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: AppColors.textLight,
          ),
          SizedBox(height: 12),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeLabel(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
