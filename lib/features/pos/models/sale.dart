import 'cart_item.dart';

class SalePayment {
  final String method; // 'cash', 'card', 'other'
  final double amount;
  const SalePayment({required this.method, required this.amount});

  Map<String, dynamic> toJson() => {'payment_method': method, 'amount': amount};
}

class SaleRequest {
  final int cashSessionId;
  final List<CartItem> items;
  final List<SalePayment> payments;

  const SaleRequest({
    required this.cashSessionId,
    required this.items,
    required this.payments,
  });

  Map<String, dynamic> toJson() => {
        'sale': {
          'cash_session_id': cashSessionId,
          'items': items
              .map((i) => {
                    'product_id': i.product.id,
                    'quantity': i.quantity,
                    'unit_price': i.product.price,
                  })
              .toList(),
          'payments': payments.map((p) => p.toJson()).toList(),
        }
      };
}
