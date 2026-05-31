import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/scanned_product.dart';
import 'scanner_repository.dart';

final barcodeScannerProvider =
    NotifierProvider<BarcodeScannerViewModel, BarcodeScannerState>(
      BarcodeScannerViewModel.new,
    );

final ocrScannerProvider =
    NotifierProvider<OcrScannerViewModel, OcrScannerState>(
      OcrScannerViewModel.new,
    );

class BarcodeScannerState {
  const BarcodeScannerState({
    this.continuous = false,
    this.isLookingUp = false,
    this.lastBarcode,
    this.results = const [],
    this.error,
  });

  final bool continuous;
  final bool isLookingUp;
  final String? lastBarcode;
  final List<ScannedProduct> results;
  final String? error;

  BarcodeScannerState copyWith({
    bool? continuous,
    bool? isLookingUp,
    String? lastBarcode,
    List<ScannedProduct>? results,
    String? error,
  }) {
    return BarcodeScannerState(
      continuous: continuous ?? this.continuous,
      isLookingUp: isLookingUp ?? this.isLookingUp,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      results: results ?? this.results,
      error: error,
    );
  }
}

class BarcodeScannerViewModel extends Notifier<BarcodeScannerState> {
  @override
  BarcodeScannerState build() => const BarcodeScannerState();

  void setContinuous(bool value) {
    state = state.copyWith(continuous: value, error: null);
  }

  void clearResults() {
    state = state.copyWith(results: const [], error: null);
  }

  Future<ScannedProduct?> lookup(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty || state.isLookingUp) return null;

    state = state.copyWith(
      isLookingUp: true,
      lastBarcode: normalized,
      error: null,
    );

    try {
      final result = await ref
          .read(scannerRepositoryProvider)
          .scanProduct(barcode: normalized);
      state = state.copyWith(
        isLookingUp: false,
        results: [result, ...state.results],
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLookingUp: false, error: e.toString());
      return null;
    }
  }
}

class OcrScannerState {
  const OcrScannerState({
    this.imagePath,
    this.isUploading = false,
    this.result,
    this.jsonPreview,
    this.error,
  });

  final String? imagePath;
  final bool isUploading;
  final OcrInvoiceResult? result;
  final String? jsonPreview;
  final String? error;

  OcrScannerState copyWith({
    String? imagePath,
    bool? isUploading,
    OcrInvoiceResult? result,
    String? jsonPreview,
    String? error,
    bool clearImage = false,
    bool clearResult = false,
  }) {
    return OcrScannerState(
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      isUploading: isUploading ?? this.isUploading,
      result: clearResult ? null : result ?? this.result,
      jsonPreview: clearResult ? null : jsonPreview ?? this.jsonPreview,
      error: error,
    );
  }
}

class OcrScannerViewModel extends Notifier<OcrScannerState> {
  @override
  OcrScannerState build() => const OcrScannerState();

  void setImage(String path) {
    state = state.copyWith(imagePath: path, clearResult: true, error: null);
  }

  void clear() {
    state = const OcrScannerState();
  }

  Future<bool> upload() async {
    final imagePath = state.imagePath;
    if (imagePath == null || state.isUploading) return false;

    state = state.copyWith(isUploading: true, error: null);
    try {
      final result = await ref
          .read(scannerRepositoryProvider)
          .uploadInvoiceImage(imagePath);
      state = state.copyWith(
        isUploading: false,
        result: result,
        jsonPreview: result.jsonText,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }
}
