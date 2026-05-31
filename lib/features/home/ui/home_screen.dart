import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../auth/auth_viewmodel.dart';
import '../../notifications/models/notification_item.dart';
import '../../notifications/notifications_viewmodel.dart';
import '../home_viewmodel.dart';
import '../models/dashboard_stats.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final salesFeed = ref.watch(salesFeedProvider);
    final dashboard = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.name.split(' ').first ?? ''}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (user?.branch != null)
              Text(
                user!.branch!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          _NotificationButton(
            count: unreadCount,
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(notificationsProvider.notifier).refresh(),
            ref.read(dashboardStatsProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            dashboard.when(
              loading: () => const _DashboardLoading(),
              error: (error, _) => _DashboardError(
                message: error.toString(),
                onRetry: () =>
                    ref.read(dashboardStatsProvider.notifier).refresh(),
              ),
              data: (stats) => _DashboardSection(stats: stats),
            ),
            const SizedBox(height: 18),
            _LiveSalesHeader(count: salesFeed.length),
            const SizedBox(height: 10),
            if (salesFeed.isEmpty)
              const _EmptySalesFeed()
            else
              ...salesFeed.map((item) => _SaleFeedTile(item: item)),
          ],
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Ventas hoy',
                value: formatCurrency(stats.dailySales.total),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Tickets',
                value: '${stats.dailySales.salesCount}',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Impuesto',
                value: formatCurrency(stats.dailySales.tax),
                icon: Icons.percent_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Stock bajo',
                value: '${stats.lowStockProducts.length}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Ventas por hora',
          child: stats.salesByHour.isEmpty
              ? const _EmptyInline('Sin ventas registradas por hora')
              : Column(
                  children: stats.salesByHour
                      .take(8)
                      .map(
                        (item) => _BarRow(
                          label: item.label,
                          value: formatCurrency(item.total),
                          fraction: _fraction(
                            item.total,
                            stats.salesByHour.map((e) => e.total),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Métodos de pago',
          child: stats.paymentMethods.isEmpty
              ? const _EmptyInline('Sin pagos registrados')
              : Column(
                  children: stats.paymentMethods
                      .take(5)
                      .map((item) => _PaymentRow(item: item))
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Productos con stock bajo',
          child: stats.lowStockProducts.isEmpty
              ? const _EmptyInline('Todo el inventario está bien')
              : Column(
                  children: stats.lowStockProducts
                      .take(6)
                      .map((item) => _LowStockRow(item: item))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.05, 1),
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.item});

  final PaymentMethodSummary item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
      title: Text(item.method),
      subtitle: Text('${item.paymentsCount} pagos'),
      trailing: Text(
        formatCurrency(item.amount),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.item});

  final LowStockProduct item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined, color: AppColors.danger),
      title: Text(
        item.productName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(item.warehouseName ?? 'Sin bodega'),
      trailing: Text(
        '${item.quantity}/${item.minStock}',
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveSalesHeader extends StatelessWidget {
  const _LiveSalesHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ventas en vivo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Live $count',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _SaleFeedTile extends StatelessWidget {
  const _SaleFeedTile({required this.item});

  final SaleFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.12),
          child: Icon(_icon, color: _color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (item.cashierName != null) item.cashierName!,
            if (item.saleId != null) 'Venta #${item.saleId}',
            _timeLabel(item.createdAt),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          item.total > 0 ? formatCurrency(item.total) : '',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }

  Color get _color {
    return item.event == 'sale_voided' ? AppColors.danger : AppColors.success;
  }

  IconData get _icon {
    return item.event == 'sale_voided'
        ? Icons.undo_rounded
        : Icons.point_of_sale_rounded;
  }
}

class _EmptySalesFeed extends StatelessWidget {
  const _EmptySalesFeed();

  @override
  Widget build(BuildContext context) {
    return const _EmptyInline('Esperando ventas en tiempo real');
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
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

double _fraction(double value, Iterable<double> values) {
  final max = values.fold<double>(0, (previous, item) {
    return item > previous ? item : previous;
  });
  if (max <= 0) return 0;
  return value / max;
}

String _timeLabel(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
