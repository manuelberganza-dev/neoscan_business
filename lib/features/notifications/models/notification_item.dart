class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.event,
    required this.title,
    this.body,
    this.metadata = const {},
    this.read = false,
    this.createdAt,
  });

  final int id;
  final String event;
  final String title;
  final String? body;
  final Map<String, dynamic> metadata;
  final bool read;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _parseInt(json['id']),
      event: (json['event'] ?? 'system_alert') as String,
      title: (json['title'] ?? json['event'] ?? 'Notificación') as String,
      body: (json['body'] ?? json['message']) as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      read: json['read'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  factory NotificationItem.fromRealtime(Map<String, dynamic> message) {
    final payload = message['payload'] is Map
        ? Map<String, dynamic>.from(message['payload'] as Map)
        : const <String, dynamic>{};

    return NotificationItem(
      id: _parseInt(payload['id'] ?? DateTime.now().microsecondsSinceEpoch),
      event: (message['event'] ?? payload['event'] ?? 'system_alert') as String,
      title: (payload['title'] ?? _titleForEvent(message['event'])) as String,
      body: (payload['body'] ?? payload['message']) as String?,
      metadata: payload['metadata'] is Map
          ? Map<String, dynamic>.from(payload['metadata'] as Map)
          : payload,
      read: false,
      createdAt:
          DateTime.tryParse((message['sent_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      event: event,
      title: title,
      body: body,
      metadata: metadata,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

class SaleFeedItem {
  const SaleFeedItem({
    required this.event,
    required this.title,
    required this.total,
    this.saleId,
    this.cashierName,
    this.createdAt,
  });

  final String event;
  final String title;
  final double total;
  final int? saleId;
  final String? cashierName;
  final DateTime? createdAt;

  factory SaleFeedItem.fromRealtime(Map<String, dynamic> message) {
    final payload = message['payload'] is Map
        ? Map<String, dynamic>.from(message['payload'] as Map)
        : const <String, dynamic>{};
    final event = (message['event'] ?? 'sale_created') as String;

    return SaleFeedItem(
      event: event,
      title: _titleForEvent(event),
      total: _parseDouble(
        payload['total'] ?? payload['amount'] ?? payload['daily_total'],
      ),
      saleId: _parseNullableInt(payload['sale_id'] ?? payload['id']),
      cashierName: (payload['cashier_name'] ?? payload['user_name']) as String?,
      createdAt:
          DateTime.tryParse((message['sent_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

String _titleForEvent(dynamic event) {
  return switch (event?.toString()) {
    'sale_created' => 'Venta registrada',
    'sale_voided' => 'Venta anulada',
    'daily_total_updated' => 'Total diario actualizado',
    'low_stock' => 'Stock bajo',
    'stock_updated' => 'Inventario actualizado',
    'purchase_received' => 'Compra recibida',
    'ocr_ready' => 'OCR listo',
    _ => 'Notificación',
  };
}

int _parseInt(dynamic value) => _parseNullableInt(value) ?? 0;

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
