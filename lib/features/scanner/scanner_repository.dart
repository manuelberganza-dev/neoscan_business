import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import 'models/scanned_product.dart';

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(
    ref.watch(dioClientProvider),
    ref.watch(appConfigProvider),
  );
});

class ScannerRepository {
  const ScannerRepository(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

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
    if (_config.geminiApiKey.isEmpty) {
      throw 'Configura GEMINI_API_KEY con --dart-define-from-file=.env';
    }

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/${_config.geminiModel}:generateContent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': _config.geminiApiKey,
          },
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _invoicePrompt},
                {
                  'inline_data': {
                    'mime_type': _mimeTypeFor(imagePath),
                    'data': base64Encode(await File(imagePath).readAsBytes()),
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0,
          },
        },
      );

      final text = _extractGeminiText(response.data);
      return OcrInvoiceResult.fromJsonText(
        text,
        rawResponse: _unwrap(response.data),
      );
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  String _extractGeminiText(dynamic data) {
    if (data is! Map) return '{}';
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return '{}';
    final content = candidates.first is Map
        ? candidates.first['content']
        : null;
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) return '{}';
    final text = parts.first is Map ? parts.first['text'] : null;
    return text?.toString() ?? '{}';
  }

  String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
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
          (purchase['invoice_number'] ?? json['invoice_number']) as String?,
      message: json['message'] as String?,
      jsonText: _prettyJson(json),
      raw: json,
    );
  }

  factory OcrInvoiceResult.fromJsonText(
    String text, {
    Map<String, dynamic> rawResponse = const {},
  }) {
    final normalized = _stripCodeFence(text);
    final decoded = jsonDecode(normalized);
    final json = decoded is Map<String, dynamic> ? decoded : {'items': decoded};

    return OcrInvoiceResult(
      invoiceNumber: json['document_number'] as String?,
      message: 'Lectura OCR completada',
      jsonText: _prettyJson(json),
      raw: {'invoice': json, 'gemini_response': rawResponse},
    );
  }
}

const _invoicePrompt = '''
Lee esta factura o comprobante fiscal de El Salvador y responde SOLO JSON valido.
No incluyas markdown ni explicaciones.

Usa esta estructura:
{
  "document_type": "CCF | Factura | Ticket | DTE | Otro",
  "document_number": null,
  "control_number": null,
  "generation_code": null,
  "issued_at": null,
  "supplier": {
    "name": null,
    "nit": null,
    "nrc": null,
    "activity": null,
    "address": null
  },
  "customer": {
    "name": null,
    "nit": null,
    "nrc": null
  },
  "currency": "USD",
  "subtotal": 0,
  "tax": 0,
  "discount": 0,
  "total": 0,
  "items": [
    {
      "description": null,
      "quantity": 0,
      "unit_price": 0,
      "tax_rate": 0.13,
      "total": 0
    }
  ],
  "confidence": 0,
  "warnings": []
}
''';

String _stripCodeFence(String text) {
  var value = text.trim();
  if (value.startsWith('```')) {
    value = value.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    value = value.replaceFirst(RegExp(r'\s*```$'), '');
  }
  return value.trim();
}

String _prettyJson(Map<String, dynamic> json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
