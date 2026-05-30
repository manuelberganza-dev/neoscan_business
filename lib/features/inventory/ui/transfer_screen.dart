import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../inventory_viewmodel.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/warehouse.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  Warehouse? _sourceWarehouse;
  Warehouse? _destinationWarehouse;
  InventoryItem? _selectedItem;
  final _quantityCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sourceWarehouse == null) {
      _showError('Selecciona la bodega de origen');
      return;
    }
    if (_destinationWarehouse == null) {
      _showError('Selecciona la bodega de destino');
      return;
    }
    if (_sourceWarehouse!.id == _destinationWarehouse!.id) {
      _showError('Las bodegas deben ser diferentes');
      return;
    }
    if (_selectedItem == null) {
      _showError('Selecciona un producto');
      return;
    }
    final qty = int.tryParse(_quantityCtrl.text);
    if (qty == null || qty <= 0) {
      _showError('Ingresa una cantidad válida');
      return;
    }
    if (_selectedItem!.quantity < qty) {
      _showError(
          'Stock insuficiente. Disponible: ${_selectedItem!.quantity}');
      return;
    }

    final ok = await ref.read(transferViewModelProvider.notifier).submit(
          TransferRequest(
            sourceWarehouseId: _sourceWarehouse!.id,
            destinationWarehouseId: _destinationWarehouse!.id,
            productId: _selectedItem!.productId,
            quantity: qty,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transferencia completada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err =
          ref.read(transferViewModelProvider).error?.toString() ??
              'Error al realizar la transferencia';
      _showError(err);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final isLoading =
        ref.watch(transferViewModelProvider) is AsyncLoading;

    final warehouses = warehousesAsync.valueOrNull ?? [];
    // Only show items from source warehouse
    final items = (inventoryAsync.valueOrNull ?? [])
        .where((i) =>
            _sourceWarehouse == null ||
            i.warehouseId == _sourceWarehouse!.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencia entre bodegas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warehouses row
            Row(
              children: [
                Expanded(
                  child: _sectionCard(
                    title: 'Bodega origen',
                    child: _WarehouseDropdown(
                      value: _sourceWarehouse,
                      warehouses: warehouses,
                      hint: 'Origen',
                      onChanged: (w) => setState(() {
                        _sourceWarehouse = w;
                        _selectedItem = null; // reset product when source changes
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 28),
                ),
                Expanded(
                  child: _sectionCard(
                    title: 'Bodega destino',
                    child: _WarehouseDropdown(
                      value: _destinationWarehouse,
                      warehouses: warehouses
                          .where((w) => w.id != _sourceWarehouse?.id)
                          .toList(),
                      hint: 'Destino',
                      onChanged: (w) =>
                          setState(() => _destinationWarehouse = w),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Product selector
            _sectionCard(
              title: 'Producto',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<InventoryItem>(
                  value: _selectedItem,
                  isExpanded: true,
                  hint: const Text('Selecciona un producto',
                      style: TextStyle(color: AppColors.textLight)),
                  items: items
                      .map((i) => DropdownMenuItem<InventoryItem>(
                            value: i,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(i.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  'Stock: ${i.quantity}  ·  SKU: ${i.sku}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (i) => setState(() => _selectedItem = i),
                ),
              ),
            ),
            if (_selectedItem != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Stock disponible: ${_selectedItem!.quantity} unidades',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Quantity
            _sectionCard(
              title: 'Cantidad a transferir',
              child: Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    final v = int.tryParse(_quantityCtrl.text) ?? 1;
                    if (v > 1) _quantityCtrl.text = '${v - 1}';
                  }),
                  Expanded(
                    child: TextField(
                      controller: _quantityCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  _qtyBtn(Icons.add, () {
                    final v = int.tryParse(_quantityCtrl.text) ?? 0;
                    final max = _selectedItem?.quantity ?? 9999;
                    if (v < max) _quantityCtrl.text = '${v + 1}';
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Notes
            _sectionCard(
              title: 'Notas (opcional)',
              child: TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ingresa una nota',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Transferir',
              isLoading: isLoading,
              onPressed: _submit,
              icon: Icons.swap_horiz_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _WarehouseDropdown extends StatelessWidget {
  final Warehouse? value;
  final List<Warehouse> warehouses;
  final String hint;
  final ValueChanged<Warehouse?> onChanged;

  const _WarehouseDropdown({
    required this.value,
    required this.warehouses,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Warehouse>(
        value: value,
        isExpanded: true,
        hint: Text(hint,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textLight)),
        items: warehouses
            .map((w) => DropdownMenuItem<Warehouse>(
                  value: w,
                  child: Text(w.name,
                      style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
