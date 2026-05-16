import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.budgetSummary;

    // Calculate per category spending
    final categories = state.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Insight',
          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Spent',
                    amount: state.formatRupiah(summary.totalSpent),
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Remaining',
                    amount: state.formatRupiah(summary.remaining),
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category breakdown
            const Text(
              'Spending by Category',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: categories.map((cat) {
                  final maxSpent = categories
                      .map((c) => c.spent)
                      .reduce((a, b) => a > b ? a : b);
                  final barWidth = maxSpent > 0 ? cat.spent / maxSpent : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    state.formatRupiah(cat.spent),
                                    style: TextStyle(
                                      color: cat.isOverBudget
                                          ? AppColors.red
                                          : AppColors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barWidth,
                                  backgroundColor:
                                      AppColors.greyDark.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cat.isOverBudget
                                        ? AppColors.red
                                        : AppColors.orange,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Budget usage
            const Text(
              'Budget Usage',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _UsageRow(
                    label: 'Monthly Budget',
                    value: state.formatRupiah(summary.monthlyBudget),
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: 'Total Spent',
                    value: state.formatRupiah(summary.totalSpent),
                    color: AppColors.red,
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: 'Remaining',
                    value: state.formatRupiah(summary.remaining),
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: 'Usage',
                    value: '${summary.percentageInt}%',
                    color: summary.percentage > 0.9 ? AppColors.red : AppColors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _UsageRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
