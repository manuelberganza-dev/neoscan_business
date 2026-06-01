import 'dart:convert';

class OcrScanResult {
  const OcrScanResult({
    required this.document,
    required this.photo,
    required this.raw,
  });

  final OcrDocumentDraft document;
  final OcrPhotoReference photo;
  final Map<String, dynamic> raw;

  String get jsonText => const JsonEncoder.withIndent('  ').convert(raw);

  factory OcrScanResult.fromJson(Map<String, dynamic> json) {
    final ocr = _asMap(json['ocr'] ?? json);
    final photo = OcrPhotoReference.fromJson(_asMap(json['photo']));

    return OcrScanResult(
      document: OcrDocumentDraft.fromJson(ocr, photoReference: photo.reference),
      photo: photo,
      raw: json,
    );
  }
}

class OcrPhotoReference {
  const OcrPhotoReference({this.reference, this.originalFilename});

  final String? reference;
  final String? originalFilename;

  factory OcrPhotoReference.fromJson(Map<String, dynamic> json) {
    return OcrPhotoReference(
      reference: _string(json['reference']),
      originalFilename: _string(json['original_filename']),
    );
  }
}

class OcrDocumentDraft {
  const OcrDocumentDraft({
    this.id,
    this.photoReference,
    this.documentType = 'Otro',
    this.documentNumber,
    this.controlNumber,
    this.generationCode,
    this.issuedAt,
    this.supplier = const OcrParty(),
    this.customer = const OcrParty(),
    this.currency = 'USD',
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.items = const [],
    this.confidence = 0,
    this.warnings = const [],
    this.status,
  });

  final int? id;
  final String? photoReference;
  final String documentType;
  final String? documentNumber;
  final String? controlNumber;
  final String? generationCode;
  final String? issuedAt;
  final OcrParty supplier;
  final OcrParty customer;
  final String currency;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final List<OcrDocumentItem> items;
  final double confidence;
  final List<String> warnings;
  final String? status;

  factory OcrDocumentDraft.fromJson(
    Map<String, dynamic> json, {
    String? photoReference,
  }) {
    return OcrDocumentDraft(
      id: _parseInt(json['id']),
      photoReference: _string(json['photo_reference']) ?? photoReference,
      documentType: _string(json['document_type']) ?? 'Otro',
      documentNumber: _string(json['document_number']),
      controlNumber: _string(json['control_number']),
      generationCode: _string(json['generation_code']),
      issuedAt: _string(json['issued_at']),
      supplier: OcrParty.fromJson(_asMap(json['supplier'])),
      customer: OcrParty.fromJson(_asMap(json['customer'])),
      currency: _string(json['currency']) ?? 'USD',
      subtotal: _parseDouble(json['subtotal']),
      tax: _parseDouble(json['tax']),
      discount: _parseDouble(json['discount']),
      total: _parseDouble(json['total']),
      items: _asList(
        json['items'],
      ).map((item) => OcrDocumentItem.fromJson(_asMap(item))).toList(),
      confidence: _parseDouble(json['confidence']),
      warnings: _asList(json['warnings'])
          .map((warning) => warning.toString())
          .where((warning) => warning.trim().isNotEmpty)
          .toList(),
      status: _string(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_reference': photoReference,
      'document_type': documentType,
      'document_number': documentNumber,
      'control_number': controlNumber,
      'generation_code': generationCode,
      'issued_at': issuedAt,
      'supplier': supplier.toSupplierJson(),
      'customer': customer.toCustomerJson(),
      'currency': currency,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
      'confidence': confidence,
      'warnings': warnings,
    };
  }
}

class OcrParty {
  const OcrParty({this.name, this.nit, this.nrc, this.activity, this.address});

  final String? name;
  final String? nit;
  final String? nrc;
  final String? activity;
  final String? address;

  factory OcrParty.fromJson(Map<String, dynamic> json) {
    return OcrParty(
      name: _string(json['name']),
      nit: _string(json['nit']),
      nrc: _string(json['nrc']),
      activity: _string(json['activity']),
      address: _string(json['address']),
    );
  }

  Map<String, dynamic> toSupplierJson() {
    return {
      'name': name,
      'nit': nit,
      'nrc': nrc,
      'activity': activity,
      'address': address,
    };
  }

  Map<String, dynamic> toCustomerJson() {
    return {'name': name, 'nit': nit, 'nrc': nrc};
  }
}

class OcrDocumentItem {
  const OcrDocumentItem({
    this.id,
    this.description,
    this.quantity = 0,
    this.unitPrice = 0,
    this.taxRate = 0.13,
    this.total = 0,
  });

  final int? id;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double total;

  factory OcrDocumentItem.fromJson(Map<String, dynamic> json) {
    return OcrDocumentItem(
      id: _parseInt(json['id']),
      description: _string(json['description']),
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      taxRate: _parseDouble(json['tax_rate'], fallback: 0.13),
      total: _parseDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'total': total,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String? _string(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
