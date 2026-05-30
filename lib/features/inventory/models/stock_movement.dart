enum MovementType { entry, exit }

class AdjustmentRequest {
  final int productId;
  final int warehouseId;
  final MovementType type;
  final int quantity;
  final String reason;
  final String? notes;

  const AdjustmentRequest({
    required this.productId,
    required this.warehouseId,
    required this.type,
    required this.quantity,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'stock_movement': {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'movement_type': type == MovementType.entry ? 'entry' : 'exit',
          'quantity': quantity,
          'reason': reason,
          if (notes != null && notes!.isNotEmpty) 'notes': notes,
        },
      };
}

class TransferRequest {
  final int sourceWarehouseId;
  final int destinationWarehouseId;
  final int productId;
  final int quantity;
  final String? notes;

  const TransferRequest({
    required this.sourceWarehouseId,
    required this.destinationWarehouseId,
    required this.productId,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'transfer': {
          'source_warehouse_id': sourceWarehouseId,
          'destination_warehouse_id': destinationWarehouseId,
          'product_id': productId,
          'quantity': quantity,
          if (notes != null && notes!.isNotEmpty) 'notes': notes,
        },
      };
}
