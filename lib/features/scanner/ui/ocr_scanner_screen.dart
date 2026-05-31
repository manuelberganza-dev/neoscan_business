import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/theme/app_theme.dart';
import '../scanner_viewmodel.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image == null) return;
    ref.read(ocrScannerProvider.notifier).setImage(image.path);
  }

  Future<void> _upload() async {
    final ok = await ref.read(ocrScannerProvider.notifier).upload();
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Factura enviada al backend'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ocrScannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OCR de factura')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: state.imagePath == null
                  ? const _EmptyInvoiceFrame()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(state.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isUploading
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isUploading
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Cámara'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: state.imagePath == null || state.isUploading
                ? null
                : _upload,
            icon: state.isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(state.isUploading ? 'Enviando' : 'Enviar al backend'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            _MessageBox(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              text: state.error!,
            ),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 12),
            _MessageBox(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
              text:
                  state.result!.message ??
                  'Imagen procesada${state.result!.invoiceNumber != null ? ': ${state.result!.invoiceNumber}' : ''}',
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyInvoiceFrame extends StatelessWidget {
  const _EmptyInvoiceFrame();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.receipt_long_outlined,
        size: 64,
        color: AppColors.textLight,
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
