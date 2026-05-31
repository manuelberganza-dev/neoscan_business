import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../scanner/models/scanned_product.dart';
import '../models/cash_session.dart';
import '../models/product.dart';
import '../pos_viewmodel.dart';
import 'widgets/cart_item_tile.dart';
import 'widgets/quantity_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await context.push<ScannedProduct>('/scanner/barcode');
    if (!mounted || result == null) return;
    await _addProduct(result.product);
  }

  Future<void> _onBarcodeSubmitted(String barcode) async {
    final product = await lookupBarcode(ref, barcode);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto no encontrado'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _addProduct(product);
  }

  Future<void> _addProduct(Product product) async {
    final qty = await showQuantityDialog(context, product);
    if (qty != null && qty > 0) {
      ref.read(cartProvider.notifier).addProduct(product, qty);
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(cashSessionProvider);
    final cart = ref.watch(cartProvider);
    final isScanning = ref.watch(scannerLoadingProvider);

    if (sessionAsync is AsyncLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = sessionAsync.value;

    if (session == null && sessionAsync is AsyncData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos/open-cash');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta actual'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: cart.items.isEmpty
                ? null
                : () => _confirmClear(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/scanner/ocr'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Teclado'),
            Tab(text: 'Carrito'),
            Tab(text: 'Clientes'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto o escanear',
                prefixIcon: isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: _openScanner,
                ),
              ),
              onSubmitted: (value) {
                final barcode = value.trim();
                if (barcode.isNotEmpty) _onBarcodeSubmitted(barcode);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const Center(
                  child: Text(
                    'Teclado numérico',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
                cart.items.isEmpty
                    ? const _EmptyCart()
                    : ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (_, i) {
                          final item = cart.items[i];
                          return CartItemTile(
                            item: item,
                            onRemove: () => ref
                                .read(cartProvider.notifier)
                                .removeItem(item.product.id),
                            onQuantityChanged: (qty) => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(item.product.id, qty),
                          );
                        },
                      ),
                const Center(
                  child: Text(
                    'Selección de clientes',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),
          if (cart.items.isNotEmpty) _SummaryBar(cart: cart, session: session),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar carrito'),
        content: const Text('¿Eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends ConsumerWidget {
  const _SummaryBar({required this.cart, required this.session});

  final CartState cart;
  final CashSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _row('Subtotal', formatCurrency(cart.subtotal)),
          const SizedBox(height: 4),
          _row('Impuesto (13%)', formatCurrency(cart.tax)),
          const SizedBox(height: 4),
          _row('Total', formatCurrency(cart.total), bold: true),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => ref.read(cartProvider.notifier).clear(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Icon(Icons.close),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/pos/payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Pagar ${formatCurrency(cart.total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.textLight,
          ),
          SizedBox(height: 12),
          Text(
            'El carrito está vacío',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Escanea un código o busca un producto',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
