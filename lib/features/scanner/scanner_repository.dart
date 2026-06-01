import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/security/token_storage.dart';
import 'models/ocr_document.dart';
import 'models/scanned_product.dart';

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(
    ref.watch(dioClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class ScannerRepository {
  const ScannerRepository(this._dio, this._tokenStorage);

  static const _ocrTimeout = Duration(minutes: 3);

  final Dio _dio;
  final TokenStorage _tokenStorage;

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

  Future<OcrScanResult> scanInvoicePhoto(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'scan[photo]': await MultipartFile.fromFile(
          imagePath,
          filename: _fileNameFor(imagePath),
        ),
      });

      final response = await _dio.post(
        '/mobile/ocr/scan',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: _ocrTimeout,
          receiveTimeout: _ocrTimeout,
          headers: await _authHeaders(),
        ),
      );

      return OcrScanResult.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw 'El endpoint de OCR no esta disponible en el backend.';
      }
      throw dioErrorMessage(e);
    }
  }

  Future<OcrDocumentDraft> saveOcrDocument(OcrDocumentDraft document) async {
    try {
      final response = await _dio.post(
        '/mobile/ocr/documents',
        data: {'ocr_document': document.toJson()},
      );
      final data = _unwrap(response.data);
      return OcrDocumentDraft.fromJson(_unwrap(data['ocr_document']));
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      return const {'Accept': 'application/json'};
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  String _fileNameFor(String path) => path.split(RegExp(r'[\\/]')).last;
}
