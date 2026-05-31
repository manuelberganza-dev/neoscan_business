import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import 'models/scanned_product.dart';

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(ref.watch(dioClientProvider));
});

class ScannerRepository {
  const ScannerRepository(this._dio);

  final Dio _dio;

  Future<ScannedProduct> scanProduct({
    required String barcode,
    int? warehouseId,
    int? branchId,
  }) async {
    final scan = <String, Object>{'barcode': barcode};
    if (warehouseId != null) scan['warehouse_id'] = warehouseId;
    if (branchId != null) scan['branch_id'] = branchId;

    try {
      final response = await _dio.post(
        '/mobile/scan_product',
        data: {'scan': scan},
      );
      return ScannedProduct.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw 'Producto no encontrado';
      throw dioErrorMessage(e);
    }
  }

  Future<OcrInvoiceResult> uploadInvoiceImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: _fileNameFor(imagePath),
        ),
      });

      final response = await _dio.post(
        '/mobile/ocr_invoice',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return OcrInvoiceResult.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'El endpoint de OCR no está disponible en el backend.';
      }
      throw dioErrorMessage(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  String _fileNameFor(String path) => path.split(RegExp(r'[\\/]')).last;
}

class OcrInvoiceResult {
  const OcrInvoiceResult({
    this.purchaseId,
    this.invoiceNumber,
    this.message,
    this.jsonText = '{}',
    this.raw = const {},
  });

  final int? purchaseId;
  final String? invoiceNumber;
  final String? message;
  final String jsonText;
  final Map<String, dynamic> raw;

  factory OcrInvoiceResult.fromJson(Map<String, dynamic> json) {
    final purchase = json['purchase'] is Map
        ? Map<String, dynamic>.from(json['purchase'] as Map)
        : const <String, dynamic>{};

    return OcrInvoiceResult(
      purchaseId: _parseInt(purchase['id'] ?? json['purchase_id']),
      invoiceNumber:
          (purchase['invoice_number'] ??
                  json['invoice_number'] ??
                  json['document_number'])
              as String?,
      message: json['message'] as String?,
      jsonText: _prettyJson(json),
      raw: json,
    );
  }
}

String _prettyJson(Map<String, dynamic> json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
