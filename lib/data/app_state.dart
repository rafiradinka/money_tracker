import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();

  String userName = 'Radinka';

  double _cashBalance = 800000;
  double _cardBalance = 12000000;
  double _eMoneyBalance = 0;
  double _monthlyBudget = 1000000;

  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  double get cashBalance => _cashBalance;
  double get cardBalance => _cardBalance;
  double get eMoneyBalance => _eMoneyBalance;
  double get totalBalance => _cashBalance + _cardBalance + _eMoneyBalance;
  double get monthlyBudget => _monthlyBudget;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;

  // Budget hanya dari EXPENSE yang BUKAN transfer
  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.isTransfer &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  BudgetSummary get budgetSummary => BudgetSummary(
        monthlyBudget: _monthlyBudget,
        totalSpent: totalSpentThisMonth,
      );

  double get averagePerDay {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return _monthlyBudget / daysInMonth;
  }

  double get safeRatePerDay {
    final now = DateTime.now();
    final remainingDays =
        DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final remaining = _monthlyBudget - totalSpentThisMonth;
    if (remainingDays <= 0) return 0;
    return (remaining / remainingDays).clamp(0, double.infinity);
  }

  List<Transaction> get latestTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  AppState() {
    _initSampleData();
  }

  void _initSampleData() {
    _categories = [
      Category(id: 'food', name: 'Food', icon: '🍴', budget: 200000, spent: 120000),
      Category(id: 'transport', name: 'Transportation', icon: '🚌', budget: 300000, spent: 220000),
      Category(id: 'entertaint', name: 'Entertaint', icon: '😊', budget: 100000, spent: 120000),
      Category(id: 'shop', name: 'Shop', icon: '🛒', budget: 200000, spent: 220000),
      Category(id: 'health', name: 'Health', icon: '❤️', budget: 200000, spent: 120000),
    ];

    final now = DateTime.now();
    _transactions = [
      Transaction(
        id: _uuid.v4(),
        title: 'Bensin Pertalite',
        amount: 50000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.cash,
        date: now,
        categoryId: 'transport',
        note: 'Bensin Pertalite',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Makan Siang',
        amount: 35000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(hours: 3)),
        categoryId: 'food',
        note: 'Makan Siang',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Langganan Netflix',
        amount: 54000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 1)),
        categoryId: 'entertaint',
        note: 'Langganan Netflix',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Beli Baju Online',
        amount: 150000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 2)),
        categoryId: 'shop',
        note: 'Beli Baju Online',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Gaji Bulanan',
        amount: 5000000,
        type: TransactionType.income,
        paymentMethod: PaymentMethod.card,
        date: DateTime(now.year, now.month, 1),
        categoryId: 'food',
        note: 'Gaji Bulanan',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Beli Obat Apotek',
        amount: 75000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(days: 3)),
        categoryId: 'health',
        note: 'Beli Obat Apotek',
      ),
    ];
  }

  // ── ADD ───────────────────────────────────────────────────────────────────────

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    // Hanya expense non-transfer yang masuk budget kategori
    if (transaction.type == TransactionType.expense && !transaction.isTransfer) {
      final idx = _categories.indexWhere((c) => c.id == transaction.categoryId);
      if (idx != -1) _categories[idx].spent += transaction.amount;
    }
    final sign = transaction.type == TransactionType.expense ? -1 : 1;
    _adjustBalance(transaction.paymentMethod, sign * transaction.amount);
    notifyListeners();
  }

  void addTransfer({
    required double amount,
    required PaymentMethod from,
    required PaymentMethod to,
    required DateTime date,
    String? note,
  }) {
    _adjustBalance(from, -amount);
    _adjustBalance(to, amount);
    // Catat sebagai dua entri dengan isTransfer=true → tidak masuk budget
    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: note?.isNotEmpty == true ? note! : 'Transfer → ${_methodName(to)}',
      amount: amount,
      type: TransactionType.expense,
      paymentMethod: from,
      date: date,
      categoryId: 'transfer',
      note: note,
      isTransfer: true,
    ));
    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: note?.isNotEmpty == true ? note! : 'Transfer ← ${_methodName(from)}',
      amount: amount,
      type: TransactionType.income,
      paymentMethod: to,
      date: date,
      categoryId: 'transfer',
      note: note,
      isTransfer: true,
    ));
    notifyListeners();
  }

  // ── EDIT ──────────────────────────────────────────────────────────────────────

  void editTransaction({
    required String id,
    required String newTitle,
    required double newAmount,
    required TransactionType newType,
    required PaymentMethod newPaymentMethod,
    required DateTime newDate,
    required String newCategoryId,
    String? newNote,
  }) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _transactions[idx];

    // Balik efek transaksi lama ke balance
    final oldSign = old.type == TransactionType.expense ? -1 : 1;
    _adjustBalance(old.paymentMethod, -oldSign * old.amount); // reverse

    // Balik efek lama ke category spent (hanya expense non-transfer)
    if (old.type == TransactionType.expense && !old.isTransfer) {
      final catIdx = _categories.indexWhere((c) => c.id == old.categoryId);
      if (catIdx != -1) _categories[catIdx].spent -= old.amount;
    }

    // Terapkan transaksi baru
    final updated = Transaction(
      id: id,
      title: newTitle,
      amount: newAmount,
      type: newType,
      paymentMethod: newPaymentMethod,
      date: newDate,
      categoryId: newCategoryId,
      note: newNote,
      isTransfer: old.isTransfer,
    );

    _transactions[idx] = updated;

    // Terapkan efek baru ke balance
    final newSign = newType == TransactionType.expense ? -1 : 1;
    _adjustBalance(newPaymentMethod, newSign * newAmount);

    // Terapkan efek baru ke category spent
    if (newType == TransactionType.expense && !old.isTransfer) {
      final catIdx = _categories.indexWhere((c) => c.id == newCategoryId);
      if (catIdx != -1) _categories[catIdx].spent += newAmount;
    }

    notifyListeners();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────────

  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final t = _transactions[idx];

    // Balik balance
    final sign = t.type == TransactionType.expense ? -1 : 1;
    _adjustBalance(t.paymentMethod, -sign * t.amount);

    // Balik category spent
    if (t.type == TransactionType.expense && !t.isTransfer) {
      final catIdx = _categories.indexWhere((c) => c.id == t.categoryId);
      if (catIdx != -1) _categories[catIdx].spent -= t.amount;
    }

    _transactions.removeAt(idx);
    notifyListeners();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────────

  void _adjustBalance(PaymentMethod method, double delta) {
    switch (method) {
      case PaymentMethod.cash:
        _cashBalance += delta;
        break;
      case PaymentMethod.card:
        _cardBalance += delta;
        break;
      case PaymentMethod.emoney:
        _eMoneyBalance += delta;
        break;
    }
  }

  String _methodName(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.emoney:
        return 'E-Money';
    }
  }

  void updateMonthlyBudget(double budget) {
    _monthlyBudget = budget;
    notifyListeners();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String formatRupiah(double amount) {
    final abs = amount.abs();
    final formatted = abs
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp$formatted';
  }
}
