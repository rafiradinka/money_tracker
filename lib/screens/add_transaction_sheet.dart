import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import 'manage_categories_screen.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      // Fix 3: bukan DraggableScrollable — sheet tetap, tap luar = tutup
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
  final _uuid             = const Uuid();
  final _amountController = TextEditingController();
  // note controller hanya untuk menyimpan nilai — input via popup dialog
  String _noteText        = '';

  PaymentMethod _paymentMethod      = PaymentMethod.cash;
  PaymentMethod _transferTo         = PaymentMethod.card;
  String        _selectedCategoryId = 'food';
  DateTime      _selectedDate       = DateTime.now();

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
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formattedDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  Future<void> _pickDateTime() async {
    final currentHour   = _selectedDate.hour;
    final currentMinute = _selectedDate.minute;

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
    if (date == null || !mounted) return;

    // Set tanggal dulu, jam tetap seperti semula
    setState(() {
      _selectedDate = DateTime(
          date.year, date.month, date.day, currentHour, currentMinute);
    });

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (time != null) {
      setState(() {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, time.hour, time.minute);
      });
    }
  }

  // Fix 4: deskripsi sebagai popup dialog di atas keyboard
  Future<void> _openDescriptionDialog() async {
    final ctrl = TextEditingController(text: _noteText);
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            // naik sesuai keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16, right: 16,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.orange.withOpacity(0.4), width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded,
                            color: AppColors.orange, size: 18),
                        const SizedBox(width: 6),
                        const Text('Deskripsi',
                            style: TextStyle(color: AppColors.white,
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Text('· akan tampil di riwayat',
                            style: TextStyle(
                                color: AppColors.greyDark, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      maxLines: 3,
                      minLines: 1,
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: ganti oli, makan siang...',
                        hintStyle: TextStyle(
                            color: AppColors.greyDark, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: const Text('Batal',
                              style: TextStyle(color: AppColors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, ctrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text('Simpan',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (result != null) setState(() => _noteText = result);
  }

  void _showError(String message) {
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
            border: Border.all(
                color: AppColors.red.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Saldo Tidak Cukup',
                  style: TextStyle(color: AppColors.white, fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...message.split('\n').map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, textAlign: TextAlign.center,
                        style: TextStyle(
                          color: line.startsWith('Dibutuhkan')
                              ? AppColors.red
                              : line.startsWith('Saldo')
                                  ? AppColors.green
                                  : AppColors.grey,
                          fontSize: 13,
                          fontWeight: (line.startsWith('Saldo') ||
                                  line.startsWith('Dibutuhkan'))
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final state  = context.read<AppState>();
    final amount = double.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', ''));

    if (amount == null || amount <= 0) {
      _showError('Masukkan jumlah yang valid');
      return;
    }

    final tabIndex    = _tabController.index;
    final description = _noteText.trim();
    BalanceResult result;

    if (tabIndex == 2) {
      result = state.addTransfer(
        amount: amount, from: _paymentMethod, to: _transferTo,
        date: _selectedDate,
        note: description.isEmpty ? null : description,
      );
    } else {
      final type = tabIndex == 0
          ? TransactionType.expense : TransactionType.income;
      final category = state.getCategoryById(_selectedCategoryId);
      final title = description.isEmpty
          ? (category?.name ?? _selectedCategoryId) : description;

      result = state.addTransaction(Transaction(
        id: _uuid.v4(), title: title, amount: amount, type: type,
        paymentMethod: _paymentMethod, date: _selectedDate,
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
    final tab   = _tabController.index;
    final Color accentColor = tab == 0 ? AppColors.red
        : tab == 1 ? AppColors.green : const Color(0xFF4FC3F7);

    // Fix 3: bukan DraggableScrollableSheet — pakai Container biasa
    // sheet muncul dari bawah, tinggi fixed, drag = tutup
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Gunakan SafeArea untuk handle notch bawah
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Tab bar
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

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Amount ───────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          const Text('Rp',
                              style: TextStyle(
                                  color: AppColors.grey, fontSize: 15)),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: accentColor, fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: accentColor.withOpacity(0.3),
                                  fontSize: 40, fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Payment Method ───────────────────────────────────
                    _label('Payment Method'),
                    const SizedBox(height: 8),

                    if (tab == 2) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('From', style: TextStyle(
                                    color: AppColors.grey, fontSize: 11)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.account_balance_wallet_outlined,
                                  label: 'Cash', selected: _paymentMethod == PaymentMethod.cash,
                                  onTap: () => setState(() => _paymentMethod = PaymentMethod.cash)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.credit_card_outlined,
                                  label: 'Card', selected: _paymentMethod == PaymentMethod.card,
                                  onTap: () => setState(() => _paymentMethod = PaymentMethod.card)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.phone_android_outlined,
                                  label: 'E-Money', selected: _paymentMethod == PaymentMethod.emoney,
                                  onTap: () => setState(() => _paymentMethod = PaymentMethod.emoney)),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 24, left: 8, right: 8),
                            child: Icon(Icons.arrow_forward,
                                color: AppColors.grey, size: 18),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('To', style: TextStyle(
                                    color: AppColors.grey, fontSize: 11)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.account_balance_wallet_outlined,
                                  label: 'Cash', selected: _transferTo == PaymentMethod.cash,
                                  onTap: () => setState(() => _transferTo = PaymentMethod.cash)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.credit_card_outlined,
                                  label: 'Card', selected: _transferTo == PaymentMethod.card,
                                  onTap: () => setState(() => _transferTo = PaymentMethod.card)),
                                const SizedBox(height: 6),
                                _PayChip(icon: Icons.phone_android_outlined,
                                  label: 'E-Money', selected: _transferTo == PaymentMethod.emoney,
                                  onTap: () => setState(() => _transferTo = PaymentMethod.emoney)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _PayChip(icon: Icons.account_balance_wallet_outlined,
                            label: 'Cash', selected: _paymentMethod == PaymentMethod.cash,
                            onTap: () => setState(() => _paymentMethod = PaymentMethod.cash)),
                          _PayChip(icon: Icons.credit_card_outlined,
                            label: 'Card', selected: _paymentMethod == PaymentMethod.card,
                            onTap: () => setState(() => _paymentMethod = PaymentMethod.card)),
                          _PayChip(icon: Icons.phone_android_outlined,
                            label: 'E-Money', selected: _paymentMethod == PaymentMethod.emoney,
                            onTap: () => setState(() => _paymentMethod = PaymentMethod.emoney)),
                        ],
                      ),
                    ],

                    // ── Category ─────────────────────────────────────────
                    if (tab != 2) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('Category'),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ManageCategoriesScreen(
                                  initialTab: tab == 0
                                      ? CategoryType.expense
                                      : CategoryType.income,
                                ),
                              ));
                              if (mounted) setState(() {});
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.tune_rounded,
                                    color: AppColors.orange, size: 13),
                                SizedBox(width: 3),
                                Text('Kelola', style: TextStyle(
                                    color: AppColors.orange, fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (tab == 0
                              ? state.expenseCategories
                              : state.incomeCategories).map((cat) {
                            final sel = _selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategoryId = cat.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? accentColor.withOpacity(0.15)
                                        : AppColors.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: sel ? accentColor : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(cat.icon,
                                          style: const TextStyle(fontSize: 15)),
                                      const SizedBox(width: 5),
                                      Text(cat.name,
                                          style: TextStyle(
                                            color: sel ? accentColor : AppColors.grey,
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // ── Date & Time ──────────────────────────────────────
                    const SizedBox(height: 14),
                    _label('Date & Time'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(_formattedDateTime(_selectedDate),
                                style: const TextStyle(
                                    color: AppColors.white, fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),

                    // ── Deskripsi (Fix 4: tap = popup dialog) ───────────
                    const SizedBox(height: 14),
                    _label('Deskripsi'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openDescriptionDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _noteText.isNotEmpty
                                ? AppColors.orange.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _noteText.isEmpty
                                    ? 'Tap untuk menambah deskripsi...'
                                    : _noteText,
                                style: TextStyle(
                                  color: _noteText.isEmpty
                                      ? AppColors.greyDark
                                      : AppColors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _noteText.isEmpty
                                  ? Icons.edit_outlined
                                  : Icons.check_circle_outline,
                              color: _noteText.isEmpty
                                  ? AppColors.greyDark
                                  : AppColors.orange,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fix 3: "Add Transaction" selalu di paling bawah
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Add Transaction',
                      style: TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppColors.grey, fontSize: 12,
          fontWeight: FontWeight.w500));
}

// ── Payment Chip ──────────────────────────────────────────────────────────────

class _PayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayChip({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withOpacity(0.15) : AppColors.card,
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
                size: 15),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              color: selected ? AppColors.orange : AppColors.grey,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
