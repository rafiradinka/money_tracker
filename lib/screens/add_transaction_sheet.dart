import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  PaymentMethod _transferTo = PaymentMethod.card;
  String _selectedCategoryId = 'food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formattedDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _showError(String message) {
    // Pakai dialog supaya langsung muncul di dalam sheet, bukan setelah close
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.red.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Saldo Tidak Cukup',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Parse pesan menjadi baris-baris yang rapi
              ...message.split('\n').map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: line.startsWith('Dibutuhkan')
                            ? AppColors.red
                            : line.startsWith('Saldo')
                                ? AppColors.green
                                : AppColors.grey,
                        fontSize: 13,
                        fontWeight: line.startsWith('Saldo') || line.startsWith('Dibutuhkan')
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final state = context.read<AppState>();
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      _showError('Masukkan jumlah yang valid');
      return;
    }

    final tabIndex = _tabController.index;
    final description = _noteController.text.trim();
    BalanceResult result;

    if (tabIndex == 2) {
      // Transfer
      result = state.addTransfer(
        amount: amount,
        from: _paymentMethod,
        to: _transferTo,
        date: _selectedDate,
        note: description.isEmpty ? null : description,
      );
    } else {
      final type = tabIndex == 0
          ? TransactionType.expense
          : TransactionType.income;

      final category = state.getCategoryById(_selectedCategoryId);
      final title = description.isEmpty
          ? (category?.name ?? _selectedCategoryId)
          : description;

      result = state.addTransaction(Transaction(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        type: type,
        paymentMethod: _paymentMethod,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        note: description.isEmpty ? null : description,
      ));
    }

    if (!result.success) {
      _showError(result.errorMessage ?? 'Terjadi kesalahan');
      return;
    }

    Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tab = _tabController.index;

    final Color accentColor = tab == 0
        ? AppColors.red
        : tab == 1
            ? AppColors.green
            : const Color(0xFF4FC3F7);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Tab bar: Expense / Income / Transfer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.grey,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Expense'),
                      Tab(text: 'Income'),
                      Tab(text: 'Transfer'),
                    ],
                  ),
                ),
              ),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ── Amount ─────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            const Text('Rp',
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 16)),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: accentColor.withOpacity(0.3),
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Payment Method ─────────────────────────────────
                      _sectionLabel('Payment Method'),
                      const SizedBox(height: 10),

                      if (tab == 2) ...[
                        // Transfer: from → to
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('From',
                                      style: TextStyle(
                                          color: AppColors.grey, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  _PaymentChip(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'Cash',
                                    selected: _paymentMethod == PaymentMethod.cash,
                                    onTap: () => setState(
                                        () => _paymentMethod = PaymentMethod.cash),
                                  ),
                                  const SizedBox(height: 6),
                                  _PaymentChip(
                                    icon: Icons.credit_card_outlined,
                                    label: 'Card',
                                    selected: _paymentMethod == PaymentMethod.card,
                                    onTap: () => setState(
                                        () => _paymentMethod = PaymentMethod.card),
                                  ),
                                  const SizedBox(height: 6),
                                  _PaymentChip(
                                    icon: Icons.phone_android_outlined,
                                    label: 'E-Money',
                                    selected:
                                        _paymentMethod == PaymentMethod.emoney,
                                    onTap: () => setState(
                                        () => _paymentMethod = PaymentMethod.emoney),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.only(top: 28, left: 8, right: 8),
                              child: Icon(Icons.arrow_forward,
                                  color: AppColors.grey, size: 20),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('To',
                                      style: TextStyle(
                                          color: AppColors.grey, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  _PaymentChip(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'Cash',
                                    selected: _transferTo == PaymentMethod.cash,
                                    onTap: () => setState(
                                        () => _transferTo = PaymentMethod.cash),
                                  ),
                                  const SizedBox(height: 6),
                                  _PaymentChip(
                                    icon: Icons.credit_card_outlined,
                                    label: 'Card',
                                    selected: _transferTo == PaymentMethod.card,
                                    onTap: () => setState(
                                        () => _transferTo = PaymentMethod.card),
                                  ),
                                  const SizedBox(height: 6),
                                  _PaymentChip(
                                    icon: Icons.phone_android_outlined,
                                    label: 'E-Money',
                                    selected:
                                        _transferTo == PaymentMethod.emoney,
                                    onTap: () => setState(
                                        () => _transferTo = PaymentMethod.emoney),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Expense / Income: single payment method
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PaymentChip(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Cash',
                              selected: _paymentMethod == PaymentMethod.cash,
                              onTap: () => setState(
                                  () => _paymentMethod = PaymentMethod.cash),
                            ),
                            _PaymentChip(
                              icon: Icons.credit_card_outlined,
                              label: 'Card',
                              selected: _paymentMethod == PaymentMethod.card,
                              onTap: () => setState(
                                  () => _paymentMethod = PaymentMethod.card),
                            ),
                            _PaymentChip(
                              icon: Icons.phone_android_outlined,
                              label: 'E-Money',
                              selected: _paymentMethod == PaymentMethod.emoney,
                              onTap: () => setState(
                                  () => _paymentMethod = PaymentMethod.emoney),
                            ),
                          ],
                        ),
                      ],

                      // ── Category (expense & income only) ──────────────
                      if (tab != 2) ...[
                        const SizedBox(height: 20),
                        _sectionLabel('Category'),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: state.categories.map((cat) {
                              final selected = _selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedCategoryId = cat.id),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? accentColor.withOpacity(0.15)
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? accentColor
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(cat.icon,
                                            style: const TextStyle(
                                                fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            color: selected
                                                ? accentColor
                                                : AppColors.grey,
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // ── Date & Time ────────────────────────────────────
                      const SizedBox(height: 20),
                      _sectionLabel('Date & Time'),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: AppColors.orange, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _formattedDate(_selectedDate),
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 14),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.grey),
                            ],
                          ),
                        ),
                      ),

                      // ── Deskripsi ──────────────────────────────────────
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _sectionLabel('Deskripsi'),
                          const SizedBox(width: 6),
                          const Text(
                            '· akan tampil di riwayat',
                            style: TextStyle(
                                color: AppColors.greyDark, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 2,
                          style: const TextStyle(
                              color: AppColors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: ganti oli, makan siang, dll...',
                            hintStyle: TextStyle(
                                color: AppColors.greyDark, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Save button ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Transaction',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: AppColors.grey, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}

// ── Payment Chip widget ───────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withOpacity(0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.orange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppColors.orange : AppColors.grey,
                size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.orange : AppColors.grey,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
