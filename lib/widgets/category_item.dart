import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class CategoryProgressItem extends StatelessWidget {
  final Category category;
  final String Function(double) formatRupiah;

  const CategoryProgressItem({
    super.key,
    required this.category,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = category.isOverBudget;
    final progressColor = isOver ? AppColors.red : AppColors.orange;

    // Persentase untuk teks (bisa > 100%)
    final pctDisplay = category.budget > 0
        ? (category.spent / category.budget * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nama + edit hint
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            color: AppColors.greyDark, size: 13),
                      ],
                    ),
                    // Amount + persentase
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatRupiah(category.spent),
                          style: TextStyle(
                            color: isOver ? AppColors.red : AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'of ${formatRupiah(category.budget)}',
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 10),
                            ),
                            if (isOver) ...[
                              const SizedBox(width: 4),
                              Text(
                                '$pctDisplay%',
                                style: const TextStyle(
                                    color: AppColors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: category.percentage, // sudah di-clamp 0..1
                    backgroundColor: AppColors.greyDark.withOpacity(0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}