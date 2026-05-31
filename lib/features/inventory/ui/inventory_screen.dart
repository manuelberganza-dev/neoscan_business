import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../inventory_viewmodel.dart';
import '../models/inventory_item.dart';
import '../models/warehouse.dart';
import 'widgets/stock_item_tile.dart';
import 'widgets/stock_status_badge.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Stock'),
            Tab(text: 'Ajustes'),
            Tab(text: 'Transferencias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_StockTab(), _AdjustmentsTab(), _TransfersTab()],
      ),
    );
  }
}

// ── Stock tab ─────────────────────────────────────────────────────────────────

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final selected = ref.watch(selectedWarehouseProvider);

    return Column(
      children: [
        // Warehouse selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: warehousesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              e.toString(),
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (warehouses) => _WarehouseDropdown(
              warehouses: warehouses,
              selected: selected,
              onChanged: (w) =>
                  ref.read(selectedWarehouseProvider.notifier).select(w),
            ),
          ),
        ),
        // Stats row
        inventoryAsync.whenData((items) => _StatsRow(items: items)).value ??
            const SizedBox.shrink(),
        // Product list
        Expanded(
          child: inventoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              message: e.toString(),
              onRetry: () => ref.read(inventoryProvider.notifier).refresh(),
            ),
            data: (items) => items.isEmpty
                ? const _EmptyInventory()
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(inventoryProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16, top: 4),
                      itemCount: items.length,
                      itemBuilder: (_, i) => StockItemTile(
                        item: items[i],
                        onAdjust: () => context.push(
                          '/inventory/adjustment',
                          extra: items[i],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _WarehouseDropdown extends StatelessWidget {
  final List<Warehouse> warehouses;
  final Warehouse? selected;
  final ValueChanged<Warehouse?> onChanged;

  const _WarehouseDropdown({
    required this.warehouses,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Warehouse?>(
          value: selected,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          hint: const Row(
            children: [
              Icon(
                Icons.warehouse_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Todas las bodegas',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          items: [
            const DropdownMenuItem<Warehouse?>(
              value: null,
              child: Text('Todas las bodegas'),
            ),
            ...warehouses.map(
              (w) => DropdownMenuItem<Warehouse?>(
                value: w,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warehouse_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(w.name),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<InventoryItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final available = items
        .where((i) => i.status == StockStatus.available)
        .length;
    final low = items.where((i) => i.status == StockStatus.low).length;
    final out = items.where((i) => i.status == StockStatus.out).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _StatChip(
            label: 'Disponibles',
            count: available,
            status: StockStatus.available,
          ),
          const SizedBox(width: 8),
          _StatChip(label: 'Bajo mínimo', count: low, status: StockStatus.low),
          const SizedBox(width: 8),
          _StatChip(label: 'Agotados', count: out, status: StockStatus.out),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final StockStatus status;
  const _StatChip({
    required this.label,
    required this.count,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            StockStatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.textLight,
          ),
          SizedBox(height: 12),
          Text(
            'Sin productos en inventario',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Selecciona otra bodega o recarga',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textLight,
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
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Adjustments tab ───────────────────────────────────────────────────────────

class _AdjustmentsTab extends StatelessWidget {
  const _AdjustmentsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 56,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajuste rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra entradas y salidas de inventario',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/inventory/adjustment'),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo ajuste'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transfers tab ─────────────────────────────────────────────────────────────

class _TransfersTab extends StatelessWidget {
  const _TransfersTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              size: 56,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Transferencia entre bodegas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mueve productos de una bodega a otra',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/inventory/transfer'),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Nueva transferencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
