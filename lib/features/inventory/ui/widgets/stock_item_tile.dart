import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/inventory_item.dart';
import 'stock_status_badge.dart';

class StockItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onAdjust;

  const StockItemTile({super.key, required this.item, this.onAdjust});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product image placeholder
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 22,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.sku}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [StockStatusBadge(status: item.status)]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stock count + adjust button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: item.status == StockStatus.out
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'unidades',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
                if (onAdjust != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAdjust,
                    child: const Text(
                      'Ajustar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
