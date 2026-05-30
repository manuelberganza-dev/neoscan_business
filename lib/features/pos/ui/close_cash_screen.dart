import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../pos_viewmodel.dart';

class CloseCashScreen extends ConsumerStatefulWidget {
  const CloseCashScreen({super.key});

  @override
  ConsumerState<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends ConsumerState<CloseCashScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final closed = await ref.read(cashSessionProvider.notifier).close(
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    if (closed != null) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caja cerrada correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(cashSessionProvider);
    final session = sessionState.valueOrNull;
    final isLoading = sessionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerrar caja'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESUMEN DE CAJA',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 16),
                    _summaryRow('Monto inicial',
                        formatCurrency(session?.initialAmount ?? 0)),
                    const Divider(),
                    _summaryRow('Ventas del día',
                        formatCurrency(session?.totalSales ?? 0)),
                    const Divider(),
                    _summaryRow(
                        'Anulaciones',
                        formatCurrency(
                            session?.totalCancellations ?? 0),
                        valueColor: AppColors.danger),
                    const Divider(),
                    _summaryRow('Total esperado',
                        formatCurrency(session?.expectedTotal ?? 0)),
                    const Divider(thickness: 2),
                    const SizedBox(height: 4),
                    _summaryRow(
                      'Monto final en caja',
                      formatCurrency(session?.expectedTotal ?? 0),
                      bold: true,
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 4),
                    _summaryRow('Diferencia',
                        formatCurrency(session?.difference ?? 0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas (opcional)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ingresa una nota',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Cerrar caja',
              isLoading: isLoading,
              onPressed: session != null ? _close : null,
              color: AppColors.danger,
              icon: Icons.lock_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      bold ? FontWeight.w600 : FontWeight.normal,
                  fontSize: bold ? 15 : 14)),
          Text(
            value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: bold ? 17 : 14,
                color: valueColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
