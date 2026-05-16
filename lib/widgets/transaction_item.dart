import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final String Function(double) formatRupiah;
  final VoidCallback? onEdit;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.category,
    required this.formatRupiah,
    this.onEdit,
  });

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.emoney:
        return 'E-Money';
    }
  }

  // Income & Transfer → ikon payment method
  // Expense biasa → ikon category
  Widget _buildIcon() {
    final isExpense = transaction.type == TransactionType.expense;

    if (!isExpense || transaction.isTransfer) {
      // Tampilkan ikon payment method
      IconData iconData;
      switch (transaction.paymentMethod) {
        case PaymentMethod.cash:
          iconData = Icons.account_balance_wallet_outlined;
          break;
        case PaymentMethod.card:
          iconData = Icons.credit_card_outlined;
          break;
        case PaymentMethod.emoney:
          iconData = Icons.phone_android_outlined;
          break;
      }
      final color = transaction.isTransfer
          ? const Color(0xFF4FC3F7) // biru untuk transfer
          : AppColors.green;

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(iconData, color: color, size: 22),
        ),
      );
    }

    // Expense → ikon emoji category
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          category?.icon ?? '💰',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = transaction.isTransfer
        ? const Color(0xFF4FC3F7)
        : isExpense
            ? AppColors.red
            : AppColors.green;
    final amountPrefix = isExpense ? '-' : '+';

    // Subtitle: untuk expense → "Category · Cash · waktu"
    //           untuk income  → "Income · Cash · waktu"
    //           untuk transfer → "Transfer · waktu"
    final parts = <String>[];
    if (transaction.isTransfer) {
      parts.add('Transfer');
    } else if (isExpense && category != null) {
      parts.add(category!.name);
      parts.add(_paymentLabel(transaction.paymentMethod));
    } else {
      parts.add('Income');
      parts.add(_paymentLabel(transaction.paymentMethod));
    }
    parts.add(_timeAgo(transaction.date));
    final subtitle = parts.join(' · ');

    return GestureDetector(
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.more_vert, color: AppColors.greyDark, size: 18),
                ),
              ),
            Text(
              '${transaction.isTransfer ? '↔' : amountPrefix}${formatRupiah(transaction.amount)}',
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
