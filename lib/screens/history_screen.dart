import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/transaction_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var transactions = List<Transaction>.from(state.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_filter != null) {
      transactions = transactions.where((t) => t.type == _filter).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expense',
                  selected: _filter == TransactionType.expense,
                  onTap: () => setState(() => _filter = TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Income',
                  selected: _filter == TransactionType.income,
                  onTap: () => setState(() => _filter = TransactionType.income),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text('No transactions', style: TextStyle(color: AppColors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.greyDark.withOpacity(0.3),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return TransactionItem(
                        transaction: t,
                        category: state.getCategoryById(t.categoryId),
                        formatRupiah: state.formatRupiah,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
