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

class AdjustmentScreen extends ConsumerStatefulWidget {
  /// Pre-selected item when coming from "Ajustar" on a stock tile.
  final InventoryItem? preselectedItem;

  const AdjustmentScreen({super.key, this.preselectedItem});

  @override
  ConsumerState<AdjustmentScreen> createState() => _AdjustmentScreenState();
}

class _AdjustmentScreenState extends ConsumerState<AdjustmentScreen> {
  MovementType _type = MovementType.entry;
  InventoryItem? _selectedItem;
  Warehouse? _selectedWarehouse;
  final _quantityCtrl = TextEditingController(text: '1');
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _reasons = [
    'Ajuste manual',
    'Devolución de cliente',
    'Producto dañado',
    'Pérdida / robo',
    'Compra de mercadería',
    'Otro',
  ];
  String _selectedReason = 'Ajuste manual';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _selectedItem = widget.preselectedItem;
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final item = _selectedItem;
    final warehouse =
        _selectedWarehouse ??
        (item != null
            ? Warehouse(id: item.warehouseId, name: item.warehouseName)
            : null);

    if (item == null) {
      _showError('Selecciona un producto');
      return;
    }
    if (warehouse == null) {
      _showError('Selecciona una bodega');
      return;
    }
    final qty = int.tryParse(_quantityCtrl.text);
    if (qty == null || qty <= 0) {
      _showError('Ingresa una cantidad válida');
      return;
    }

    final ok = await ref
        .read(adjustmentViewModelProvider.notifier)
        .submit(
          AdjustmentRequest(
            productId: item.productId,
            warehouseId: warehouse.id,
            type: _type,
            quantity: qty,
            reason: _selectedReason,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajuste guardado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err =
          ref.read(adjustmentViewModelProvider).error?.toString() ??
          'Error al guardar el ajuste';
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
    final isLoading = ref.watch(adjustmentViewModelProvider) is AsyncLoading;

    final warehouses = warehousesAsync.value ?? [];
    final items = inventoryAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuste de inventario'),
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
            // Product selector
            _sectionCard(
              title: 'Producto',
              child: _SearchableDropdown<InventoryItem>(
                value: _selectedItem,
                items: items,
                labelBuilder: (i) => i.productName,
                subtitleBuilder: (i) => 'SKU: ${i.sku} · ${i.warehouseName}',
                hint: 'Selecciona un producto',
                onChanged: (i) => setState(() {
                  _selectedItem = i;
                  if (i != null) {
                    _selectedWarehouse = Warehouse(
                      id: i.warehouseId,
                      name: i.warehouseName,
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            // Warehouse selector
            _sectionCard(
              title: 'Bodega',
              child: _SearchableDropdown<Warehouse>(
                value: _selectedWarehouse,
                items: warehouses,
                labelBuilder: (w) => w.name,
                hint: 'Selecciona una bodega',
                onChanged: (w) => setState(() => _selectedWarehouse = w),
              ),
            ),
            const SizedBox(height: 12),
            // Movement type toggle
            _sectionCard(
              title: 'Tipo de ajuste',
              child: Row(
                children: [
                  _typeButton(
                    MovementType.entry,
                    'Entrada',
                    const Color(0xFFDCFCE7),
                    const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 10),
                  _typeButton(
                    MovementType.exit,
                    'Salida',
                    const Color(0xFFFEE2E2),
                    const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quantity
            _sectionCard(
              title: 'Cantidad',
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
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
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
                    _quantityCtrl.text = '${v + 1}';
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Reason
            _sectionCard(
              title: 'Motivo',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: _reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReason = v!),
                ),
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
              label: 'Guardar ajuste',
              isLoading: isLoading,
              onPressed: _submit,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(MovementType type, String label, Color bg, Color fg) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? bg : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? fg : AppColors.border,
              width: active ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: active ? fg : AppColors.textSecondary,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final String hint;
  final ValueChanged<T?> onChanged;

  const _SearchableDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.hint,
    required this.onChanged,
    this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        hint: Text(hint, style: const TextStyle(color: AppColors.textLight)),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelBuilder(item),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (subtitleBuilder != null)
                      Text(
                        subtitleBuilder!(item),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
