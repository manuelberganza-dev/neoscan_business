class CashSession {
  final int id;
  final double initialAmount;
  final String status;
  final String? registerName;
  final String? branchName;
  final DateTime openedAt;

  // Populated on close
  final double? totalSales;
  final double? totalCancellations;
  final double? expectedTotal;
  final double? finalAmount;
  final double? difference;

  const CashSession({
    required this.id,
    required this.initialAmount,
    required this.status,
    required this.openedAt,
    this.registerName,
    this.branchName,
    this.totalSales,
    this.totalCancellations,
    this.expectedTotal,
    this.finalAmount,
    this.difference,
  });

  bool get isOpen => status == 'open';

  factory CashSession.fromJson(Map<String, dynamic> json) {
    final register = json['cash_register'] ?? json['register'];
    final branch = json['branch'];
    return CashSession(
      id: json['id'] as int,
      initialAmount: _parseDouble(json['initial_amount'] ?? 0) ?? 0.0,
      status: json['status'] as String? ?? 'open',
      openedAt: DateTime.tryParse(json['opened_at']?.toString() ?? '') ??
          DateTime.now(),
      registerName: register is Map ? register['name'] as String? : null,
      branchName: branch is Map ? branch['name'] as String? : null,
      totalSales: _parseDouble(json['total_sales']),
      totalCancellations: _parseDouble(json['total_cancellations']),
      expectedTotal: _parseDouble(json['expected_total']),
      finalAmount: _parseDouble(json['final_amount']),
      difference: _parseDouble(json['difference']),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
