import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  // 'weekly' atau 'daily'
  String _mode = 'weekly';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now   = DateTime.now();

    // Hitung data sesuai mode
    final chartData = _mode == 'weekly'
        ? _buildWeeklyData(state.transactions, now)
        : _buildDailyData(state.transactions, now);

    final totalIncome  = state.transactions
        .where((t) => t.type == TransactionType.income && !t.isTransfer &&
            t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);

    final totalExpense = state.totalSpentThisMonth;
    final net          = totalIncome - totalExpense;

    // Hari paling boros bulan ini
    final Map<String, double> dayExpense = {};
    for (final t in state.transactions) {
      if (t.type == TransactionType.expense && !t.isTransfer &&
          t.date.month == now.month && t.date.year == now.year) {
        final key = '${t.date.day}/${t.date.month}';
        dayExpense[key] = (dayExpense[key] ?? 0) + t.amount;
      }
    }
    String? borosDay;
    double borosAmount = 0;
    dayExpense.forEach((k, v) {
      if (v > borosAmount) { borosAmount = v; borosDay = k; }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Insight',
            style: TextStyle(color: AppColors.white, fontSize: 18,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Summary cards ──────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  label: 'Pemasukan', value: state.formatRupiah(totalIncome),
                  color: AppColors.green, icon: Icons.arrow_downward_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(
                  label: 'Pengeluaran', value: state.formatRupiah(totalExpense),
                  color: AppColors.red, icon: Icons.arrow_upward_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            _NetCard(net: net, formatRupiah: state.formatRupiah),
            const SizedBox(height: 20),

            // ── Bar chart ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _mode == 'weekly' ? '7 Hari Terakhir' : '30 Hari Terakhir',
                        style: const TextStyle(color: AppColors.white,
                            fontSize: 15, fontWeight: FontWeight.w600)),
                      // Toggle mode
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _ModeBtn(label: 'Mingguan',
                                selected: _mode == 'weekly',
                                onTap: () => setState(() => _mode = 'weekly')),
                            _ModeBtn(label: 'Harian',
                                selected: _mode == 'daily',
                                onTap: () => setState(() => _mode = 'daily')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Legend
                  Row(
                    children: [
                      _LegendDot(color: AppColors.green, label: 'Pemasukan'),
                      const SizedBox(width: 16),
                      _LegendDot(color: AppColors.red, label: 'Pengeluaran'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  chartData.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Belum ada data transaksi.',
                                style: TextStyle(color: AppColors.grey)),
                          ))
                      : _BarChart(data: chartData,
                            formatRupiah: state.formatRupiah),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hari paling boros ──────────────────────────────────────
            if (borosDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.red, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hari Paling Boros Bulan Ini',
                              style: TextStyle(color: AppColors.grey, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(borosDay!,
                              style: const TextStyle(color: AppColors.white,
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text(state.formatRupiah(borosAmount),
                        style: const TextStyle(color: AppColors.red,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // ── Top kategori pengeluaran ───────────────────────────────
            const SizedBox(height: 16),
            _TopCategories(state: state, now: now),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Data builders ──────────────────────────────────────────────────────────

  List<_BarData> _buildWeeklyData(List<Transaction> txs, DateTime now) {
    const days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    final result = <_BarData>[];
    for (int i = 6; i >= 0; i--) {
      final day  = now.subtract(Duration(days: i));
      final label = days[day.weekday - 1];
      double inc = 0, exp = 0;
      for (final t in txs) {
        if (t.date.year == day.year && t.date.month == day.month &&
            t.date.day == day.day && !t.isTransfer) {
          if (t.type == TransactionType.income)  inc += t.amount;
          if (t.type == TransactionType.expense) exp += t.amount;
        }
      }
      result.add(_BarData(label: label, income: inc, expense: exp));
    }
    return result;
  }

  List<_BarData> _buildDailyData(List<Transaction> txs, DateTime now) {
    final result = <_BarData>[];
    for (int i = 13; i >= 0; i--) {
      final day   = now.subtract(Duration(days: i));
      final label = '${day.day}';
      double inc = 0, exp = 0;
      for (final t in txs) {
        if (t.date.year == day.year && t.date.month == day.month &&
            t.date.day == day.day && !t.isTransfer) {
          if (t.type == TransactionType.income)  inc += t.amount;
          if (t.type == TransactionType.expense) exp += t.amount;
        }
      }
      result.add(_BarData(label: label, income: inc, expense: exp));
    }
    return result;
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarData {
  final String label;
  final double income;
  final double expense;
  const _BarData({required this.label, required this.income, required this.expense});
  double get max => income > expense ? income : expense;
}

class _BarChart extends StatelessWidget {
  final List<_BarData> data;
  final String Function(double) formatRupiah;

  const _BarChart({required this.data, required this.formatRupiah});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (m, d) => d.max > m ? d.max : m);
    const chartH = 140.0;

    return Column(
      children: [
        SizedBox(
          height: chartH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final incH  = maxVal > 0 ? (d.income  / maxVal * chartH) : 0.0;
              final expH  = maxVal > 0 ? (d.expense / maxVal * chartH) : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Income bar
                      Expanded(
                        child: Tooltip(
                          message: 'Masuk: ${formatRupiah(d.income)}',
                          child: Container(
                            height: incH.clamp(2, chartH),
                            decoration: BoxDecoration(
                              color: d.income > 0
                                  ? AppColors.green
                                  : AppColors.greyDark.withOpacity(0.2),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Expense bar
                      Expanded(
                        child: Tooltip(
                          message: 'Keluar: ${formatRupiah(d.expense)}',
                          child: Container(
                            height: expH.clamp(2, chartH),
                            decoration: BoxDecoration(
                              color: d.expense > 0
                                  ? AppColors.red
                                  : AppColors.greyDark.withOpacity(0.2),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // X-axis labels
        Row(
          children: data.map((d) => Expanded(
            child: Text(d.label, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey, fontSize: 10)),
          )).toList(),
        ),
      ],
    );
  }
}

// ── Top categories ────────────────────────────────────────────────────────────

class _TopCategories extends StatelessWidget {
  final AppState state;
  final DateTime now;

  const _TopCategories({required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    // Hitung pengeluaran per kategori bulan ini
    final Map<String, double> catSpend = {};
    for (final t in state.transactions) {
      if (t.type == TransactionType.expense && !t.isTransfer &&
          t.date.month == now.month && t.date.year == now.year) {
        catSpend[t.categoryId] = (catSpend[t.categoryId] ?? 0) + t.amount;
      }
    }
    if (catSpend.isEmpty) return const SizedBox.shrink();

    final sorted = catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top    = sorted.take(5).toList();
    final maxAmt = top.first.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Pengeluaran Bulan Ini',
              style: TextStyle(color: AppColors.white, fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...top.map((e) {
            final cat = state.getCategoryById(e.key);
            final pct = maxAmt > 0 ? e.value / maxAmt : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(cat?.icon ?? '💰',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat?.name ?? e.key,
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 13)),
                            Text(state.formatRupiah(e.value),
                                style: const TextStyle(
                                    color: AppColors.orange, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor:
                                AppColors.greyDark.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Kecil-kecilan ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    color: AppColors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetCard extends StatelessWidget {
  final double net;
  final String Function(double) formatRupiah;
  const _NetCard({required this.net, required this.formatRupiah});

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = isPositive ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isPositive ? '📈 Net bulan ini' : '📉 Net bulan ini',
              style: const TextStyle(color: AppColors.white, fontSize: 13)),
          Text(
            '${isPositive ? '+' : '-'}${formatRupiah(net.abs())}',
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.grey,
          fontSize: 11, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      ],
    );
  }
}
