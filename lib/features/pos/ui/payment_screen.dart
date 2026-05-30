import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/currency_utils.dart';
import '../models/sale.dart';
import '../pos_viewmodel.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _cashCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  String _activeMethod = 'cash';

  @override
  void dispose() {
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  double get _cashAmount => parseAmount(_cashCtrl.text);
  double get _cardAmount => parseAmount(_cardCtrl.text);
  double get _otherAmount => parseAmount(_otherCtrl.text);
  double get _paidTotal => _cashAmount + _cardAmount + _otherAmount;

  Future<void> _confirm() async {
    final cart = ref.read(cartProvider);
    final session = ref.read(cashSessionProvider).valueOrNull;
    if (session == null) return;

    if (_paidTotal < cart.total - 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Monto insuficiente. Faltan ${formatCurrency(cart.total - _paidTotal)}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final payments = <SalePayment>[
      if (_cashAmount > 0)
        SalePayment(method: 'cash', amount: _cashAmount),
      if (_cardAmount > 0)
        SalePayment(method: 'card', amount: _cardAmount),
      if (_otherAmount > 0)
        SalePayment(method: 'other', amount: _otherAmount),
    ];

    final ok = await ref.read(cartProvider.notifier).processSale(
          cashSessionId: session.id,
          payments: payments,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta procesada exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/pos');
    } else {
      final err = ref.read(cartProvider).error ?? 'Error al procesar la venta';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procesar pago'),
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
            // Total card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a pagar',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    Text(
                      formatCurrency(cart.total),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Method selector
            Row(
              children: [
                _methodBtn('cash', Icons.payments_outlined, 'Efectivo'),
                const SizedBox(width: 8),
                _methodBtn('card', Icons.credit_card_outlined, 'Tarjeta'),
                const SizedBox(width: 8),
                _methodBtn('other', Icons.more_horiz, 'Otro'),
              ],
            ),
            const SizedBox(height: 16),
            // Amount inputs
            Card(
              child: Column(
                children: [
                  _amountRow(
                    icon: Icons.payments_outlined,
                    label: 'Efectivo',
                    controller: _cashCtrl,
                    method: 'cash',
                  ),
                  const Divider(height: 0),
                  _amountRow(
                    icon: Icons.credit_card_outlined,
                    label: 'Tarjeta',
                    controller: _cardCtrl,
                    method: 'card',
                  ),
                  const Divider(height: 0),
                  _amountRow(
                    icon: Icons.more_horiz,
                    label: 'Otro método',
                    controller: _otherCtrl,
                    method: 'other',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Change (rebuilds via setState in each field's onChanged)
            _changeCard(_paidTotal - cart.total),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed:
                  cart.isProcessing ? null : _confirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: cart.isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Confirmar pago',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodBtn(String method, IconData icon, String label) {
    final active = _activeMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMethod = method),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _changeCard(double change) => Card(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cambio',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15)),
              Text(
                formatCurrency(change > 0 ? change : 0),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success),
              ),
            ],
          ),
        ),
      );

  Widget _amountRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String method,
  }) {
    final active = _activeMethod == method;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              color: active
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w500 : FontWeight.normal)),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
