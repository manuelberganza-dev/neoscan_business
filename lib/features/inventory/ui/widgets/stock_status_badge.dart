import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';

class StockStatusBadge extends StatelessWidget {
  final StockStatus status;

  const StockStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      StockStatus.available => ('Disponible', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      StockStatus.low       => ('Bajo mínimo', const Color(0xFFFEF9C3), const Color(0xFFCA8A04)),
      StockStatus.out       => ('Agotado',     const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
