import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/currency_utils.dart';
import '../models/scanned_product.dart';
import '../scanner_viewmodel.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  String? _lastHandledCode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastHandledCode) return;

    _lastHandledCode = barcode;
    HapticFeedback.selectionClick();

    final scanner = ref.read(barcodeScannerProvider.notifier);
    final result = await scanner.lookup(barcode);
    final state = ref.read(barcodeScannerProvider);

    if (!mounted || result == null) return;
    HapticFeedback.mediumImpact();

    if (!state.continuous) {
      context.pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(barcodeScannerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          const _ScannerFrame(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(controller: _controller),
                const Spacer(),
                _BottomPanel(state: scannerState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continuous = ref.watch(barcodeScannerProvider).continuous;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Cerrar',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          const Spacer(),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton.filledTonal(
                tooltip: 'Linterna',
                onPressed: state.torchState == TorchState.unavailable
                    ? null
                    : controller.toggleTorch,
                icon: Icon(
                  torchOn
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Modo continuo',
            isSelected: continuous,
            onPressed: () => ref
                .read(barcodeScannerProvider.notifier)
                .setContinuous(!continuous),
            icon: const Icon(Icons.playlist_add_check_rounded),
            selectedIcon: const Icon(Icons.check_circle_rounded),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        height: 210,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _BottomPanel extends ConsumerWidget {
  const _BottomPanel({required this.state});

  final BarcodeScannerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.continuous
                        ? 'Escaneo continuo'
                        : 'Escaneo de producto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (state.isLookingUp)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
            if (state.results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.results.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.results[index];
                    return _ScannedProductTile(
                      scannedProduct: item,
                      onTap: () => context.pop(item),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScannedProductTile extends StatelessWidget {
  const _ScannedProductTile({
    required this.scannedProduct,
    required this.onTap,
  });

  final ScannedProduct scannedProduct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = scannedProduct.product;
    final stock = scannedProduct.stock.selectedWarehouse;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          product.barcode ?? product.sku,
          if (stock != null) '${stock.quantity} en ${stock.warehouseName}',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatCurrency(product.price),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
