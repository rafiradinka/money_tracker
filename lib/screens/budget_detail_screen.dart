import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/circular_chart.dart';
import '../widgets/category_item.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.budgetSummary;

    // Usage percentage (bisa > 100%)
    final usagePct = summary.monthlyBudget > 0
        ? (summary.totalSpent / summary.monthlyBudget * 100)
        : 0.0;
    final isOverBudget = usagePct > 100;
    final usageColor = isOverBudget ? AppColors.red : AppColors.green;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Budget Detail',
          style: TextStyle(
              color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Circular chart + monthly budget ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  LargeCircularChart(
                    percentage: summary.percentage,
                    size: 150,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Budget',
                            style: TextStyle(color: AppColors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          state.formatRupiah(summary.monthlyBudget),
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '= total budget kategori',
                          style: const TextStyle(
                              color: AppColors.greyDark, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Budget Usage (menggantikan "remaining") ───────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Judul
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget Usage',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: usageColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${usagePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: usageColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(
                    label: 'Monthly Budget',
                    value: state.formatRupiah(summary.monthlyBudget),
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 8),
                  _UsageRow(
                    label: 'Total Terpakai',
                    value: state.formatRupiah(summary.totalSpent),
                    color: AppColors.red,
                  ),
                  const SizedBox(height: 8),
                  _UsageRow(
                    label: summary.remaining >= 0 ? 'Sisa Budget' : 'Melebihi Budget',
                    value: state.formatRupiah(summary.remaining.abs()),
                    color: summary.remaining >= 0 ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(height: 10),
                  // Progress bar (capped visual 100%, teks bisa > 100%)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: summary.percentage.clamp(0.0, 1.0),
                      backgroundColor: AppColors.greyDark.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? AppColors.red : AppColors.orange),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Categories ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategori',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Tap kategori untuk edit budget',
                        style: const TextStyle(
                            color: AppColors.greyDark, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...state.expenseCategories.asMap().entries.map((entry) {
                    final cat = entry.value;
                    final isLast = entry.key == state.expenseCategories.length - 1;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _showEditCategoryBudget(context, state, cat),
                          child: CategoryProgressItem(
                            category: cat,
                            formatRupiah: state.formatRupiah,
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            color: AppColors.greyDark.withOpacity(0.3),
                            height: 1,
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryBudget(
      BuildContext context, AppState state, Category category) {
    final controller = TextEditingController(
      text: category.budget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Budget ${category.name}',
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sudah terpakai: ${state.formatRupiah(category.spent)}',
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: AppColors.orange),
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.greyDark),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.orange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(
                  controller.text.replaceAll('.', '').replaceAll(',', ''));
              if (val != null && val >= 0) {
                state.updateCategoryBudget(category.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan',
                style: TextStyle(color: AppColors.orange)),
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

  const _UsageRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
