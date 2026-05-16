import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
          style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pengeluaran',
                  selected: _filter == TransactionType.expense,
                  onTap: () => setState(() => _filter = TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pemasukan',
                  selected: _filter == TransactionType.income,
                  onTap: () => setState(() => _filter = TransactionType.income),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        onEdit: t.isTransfer
                            ? null // transfer tidak bisa diedit individual
                            : () => _showEditSheet(context, t, state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, Transaction transaction, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTransactionSheet(
        transaction: transaction,
        state: state,
      ),
    );
  }
}

// ── Edit Bottom Sheet ─────────────────────────────────────────────────────────

class _EditTransactionSheet extends StatefulWidget {
  final Transaction transaction;
  final AppState state;

  const _EditTransactionSheet({
    required this.transaction,
    required this.state,
  });

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late TextEditingController _descController;
  late TextEditingController _amountController;
  late TransactionType _type;
  late PaymentMethod _paymentMethod;
  late String _categoryId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _descController = TextEditingController(text: t.title);
    _amountController =
        TextEditingController(text: t.amount.toStringAsFixed(0));
    _type = t.type;
    _paymentMethod = t.paymentMethod;
    _categoryId = t.categoryId;
    _date = t.date;
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formattedDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah yang valid'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final desc = _descController.text.trim();
    final category = widget.state.getCategoryById(_categoryId);
    final title = desc.isEmpty ? (category?.name ?? _categoryId) : desc;

    final result = widget.state.editTransaction(
      id: widget.transaction.id,
      newTitle: title,
      newAmount: amount,
      newType: _type,
      newPaymentMethod: _paymentMethod,
      newDate: _date,
      newCategoryId: _categoryId,
      newNote: desc.isEmpty ? null : desc,
    );

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage ?? 'Terjadi kesalahan'),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Transaksi?',
            style: TextStyle(color: AppColors.white)),
        content: Text(
          'Transaksi "${widget.transaction.title}" akan dihapus.',
          style: const TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              widget.state.deleteTransaction(widget.transaction.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final accentColor = isExpense ? AppColors.red : AppColors.green;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
              // Handle + header
              Padding(
                padding: const EdgeInsets.only(top: 12),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Transaksi',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: _delete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: AppColors.red, size: 16),
                            SizedBox(width: 4),
                            Text('Hapus',
                                style: TextStyle(
                                    color: AppColors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _TypeBtn(
                              label: 'Pengeluaran',
                              selected: _type == TransactionType.expense,
                              color: AppColors.red,
                              onTap: () => setState(
                                  () => _type = TransactionType.expense),
                            ),
                            _TypeBtn(
                              label: 'Pemasukan',
                              selected: _type == TransactionType.income,
                              color: AppColors.green,
                              onTap: () => setState(
                                  () => _type = TransactionType.income),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Amount
                      _label('Jumlah'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _amountController,
                        hint: '0',
                        prefix: 'Rp ',
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _label('Deskripsi · tampil di riwayat'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _descController,
                        hint: 'Contoh: ganti oli, makan siang...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Payment method
                      _label('Metode Pembayaran'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PayChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Cash',
                            selected: _paymentMethod == PaymentMethod.cash,
                            onTap: () => setState(
                                () => _paymentMethod = PaymentMethod.cash),
                          ),
                          _PayChip(
                            icon: Icons.credit_card_outlined,
                            label: 'Card',
                            selected: _paymentMethod == PaymentMethod.card,
                            onTap: () => setState(
                                () => _paymentMethod = PaymentMethod.card),
                          ),
                          _PayChip(
                            icon: Icons.phone_android_outlined,
                            label: 'E-Money',
                            selected: _paymentMethod == PaymentMethod.emoney,
                            onTap: () => setState(
                                () => _paymentMethod = PaymentMethod.emoney),
                          ),
                        ],
                      ),

                      // Category (hanya expense)
                      if (_type == TransactionType.expense) ...[
                        const SizedBox(height: 16),
                        _label('Kategori'),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.state.categories.map((cat) {
                              final sel = _categoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _categoryId = cat.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? accentColor.withOpacity(0.15)
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? accentColor
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(cat.icon),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            color: sel
                                                ? accentColor
                                                : AppColors.grey,
                                            fontSize: 13,
                                            fontWeight: sel
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

                      // Date
                      const SizedBox(height: 16),
                      _label('Tanggal'),
                      const SizedBox(height: 8),
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
                                _formattedDate(_date),
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

                      const SizedBox(height: 28),

                      // Save button
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
                            'Simpan Perubahan',
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: AppColors.grey, fontSize: 13),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.greyDark, fontSize: 13),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: AppColors.orange),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

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

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayChip(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.orange.withOpacity(0.15) : AppColors.card,
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