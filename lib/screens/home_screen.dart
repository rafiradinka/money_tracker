import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/circular_chart.dart';
import '../widgets/transaction_item.dart';
import '../screens/budget_detail_screen.dart';
import '../screens/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _balanceExpanded = false;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnim;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _expandAnim = CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  void _toggleBalance() {
    setState(() => _balanceExpanded = !_balanceExpanded);
    if (_balanceExpanded) {
      _arrowController.forward();
    } else {
      _arrowController.reverse();
    }
  }

  String _dayOfWeek() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  String _formattedDate() {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final now = DateTime.now();
    return '${_dayOfWeek()}, ${now.day} ${months[now.month - 1]}';
  }

  String _monthYearLabel() {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  String _formatK(double val) {
    if (val >= 1000000) return 'Rp${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return 'Rp${(val / 1000).round()}k';
    return 'Rp${val.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.budgetSummary;
    final latest = state.latestTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${state.userName}!',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.grey,
                          size: 28,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Total Balance Card ──────────────────────────────────
                GestureDetector(
                  onTap: _toggleBalance,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.formatRupiah(state.totalBalance),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            RotationTransition(
                              turns: _arrowAnim,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Dropdown breakdown
                        SizeTransition(
                          sizeFactor: _expandAnim,
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: AppColors.greyDark.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BalanceTypeCard(
                                      icon: Icons.account_balance_wallet_outlined,
                                      label: 'Cash',
                                      amount: state.formatRupiah(state.cashBalance),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BalanceTypeCard(
                                      icon: Icons.credit_card_outlined,
                                      label: 'Card',
                                      amount: state.formatRupiah(state.cardBalance),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BalanceTypeCard(
                                      icon: Icons.phone_android_outlined,
                                      label: 'E-Money',
                                      amount: state.formatRupiah(state.eMoneyBalance),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Monthly Budget Card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Budget',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _monthYearLabel(),
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetDetailScreen(),
                              ),
                            ),
                            child: const Text(
                              'detail',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      CircularBudgetChart(
                        percentage: summary.percentage,
                        spent: summary.totalSpent,
                        total: summary.monthlyBudget,
                        size: 160,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _RateInfo(
                            label: 'Average',
                            value: '${_formatK(state.averagePerDay)}/days',
                            valueColor: AppColors.orange,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.greyDark.withOpacity(0.4),
                          ),
                          _RateInfo(
                            label: 'Safe Rate',
                            value: '${_formatK(state.safeRatePerDay)}/days',
                            valueColor: AppColors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Latest Transactions ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Latest Transactions',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AppShellState.of(context)?.switchTab(1);
                      },
                      child: const Text(
                        'see all',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                latest.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: latest.take(5).toList().asMap().entries.map((e) {
                            final i = e.key;
                            final t = e.value;
                            final isLast = i == (latest.take(5).length - 1);
                            return Column(
                              children: [
                                TransactionItem(
                                  transaction: t,
                                  category: state.getCategoryById(t.categoryId),
                                  formatRupiah: state.formatRupiah,
                                ),
                                if (!isLast)
                                  Divider(
                                    color: AppColors.greyDark.withOpacity(0.3),
                                    height: 1,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _BalanceTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;

  const _BalanceTypeCard({
    required this.icon,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              amount,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _RateInfo({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
