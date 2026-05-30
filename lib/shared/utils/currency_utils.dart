String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';

double parseAmount(String value) =>
    double.tryParse(value.replaceAll(',', '').replaceAll('\$', '')) ?? 0.0;
