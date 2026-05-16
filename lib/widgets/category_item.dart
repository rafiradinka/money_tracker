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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                            Text(
                              'of ${formatRupiah(category.budget)}',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: category.percentage,
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
        ],
      ),
    );
  }
}
