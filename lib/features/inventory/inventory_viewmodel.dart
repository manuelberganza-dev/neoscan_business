import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'inventory_repository.dart';
import 'models/inventory_item.dart';
import 'models/stock_movement.dart';
import 'models/warehouse.dart';

// ── Warehouses (loaded once) ──────────────────────────────────────────────────

final warehousesProvider = AsyncNotifierProvider<WarehousesViewModel, List<Warehouse>>(
  WarehousesViewModel.new,
);

class WarehousesViewModel extends AsyncNotifier<List<Warehouse>> {
  @override
  Future<List<Warehouse>> build() =>
      ref.read(inventoryRepositoryProvider).getWarehouses();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).getWarehouses(),
    );
  }
}

// ── Selected warehouse filter ─────────────────────────────────────────────────

final selectedWarehouseProvider = StateProvider<Warehouse?>((ref) => null);

// ── Inventory list (reacts to warehouse filter) ───────────────────────────────

final inventoryProvider =
    AsyncNotifierProvider<InventoryViewModel, List<InventoryItem>>(
  InventoryViewModel.new,
);

class InventoryViewModel extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() {
    // Re-runs whenever the warehouse filter changes
    final warehouse = ref.watch(selectedWarehouseProvider);
    return ref
        .read(inventoryRepositoryProvider)
        .getInventory(warehouseId: warehouse?.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final warehouse = ref.read(selectedWarehouseProvider);
    state = await AsyncValue.guard(
      () => ref
          .read(inventoryRepositoryProvider)
          .getInventory(warehouseId: warehouse?.id),
    );
  }
}

// ── Adjustment ────────────────────────────────────────────────────────────────

final adjustmentViewModelProvider =
    NotifierProvider<AdjustmentViewModel, AsyncValue<void>>(
  AdjustmentViewModel.new,
);

class AdjustmentViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(AdjustmentRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).createAdjustment(request),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(inventoryProvider);
    }
    return !result.hasError;
  }
}

// ── Transfer ──────────────────────────────────────────────────────────────────

final transferViewModelProvider =
    NotifierProvider<TransferViewModel, AsyncValue<void>>(
  TransferViewModel.new,
);

class TransferViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(TransferRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).createTransfer(request),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(inventoryProvider);
    }
    return !result.hasError;
  }
}
