import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

// Return type untuk validasi saldo
class BalanceResult {
  final bool success;
  final String? errorMessage;
  const BalanceResult.ok() : success = true, errorMessage = null;
  const BalanceResult.error(this.errorMessage) : success = false;
}

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();

  String userName = 'Radinka';

  double _cashBalance = 800000;
  double _cardBalance = 12000000;
  double _eMoneyBalance = 0;

  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  double get cashBalance => _cashBalance;
  double get cardBalance => _cardBalance;
  double get eMoneyBalance => _eMoneyBalance;
  double get totalBalance => _cashBalance + _cardBalance + _eMoneyBalance;

  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;

  // Monthly budget = total budget semua kategori
  double get monthlyBudget =>
      _categories.fold(0.0, (sum, c) => sum + c.budget);

  // Total spent bulan ini (expense non-transfer saja)
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
        monthlyBudget: monthlyBudget,
        totalSpent: totalSpentThisMonth,
      );

  double get averagePerDay {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final budget = monthlyBudget;
    return budget > 0 ? budget / daysInMonth : 0;
  }

  double get safeRatePerDay {
    final now = DateTime.now();
    final remainingDays =
        DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final remaining = monthlyBudget - totalSpentThisMonth;
    if (remainingDays <= 0) return 0;
    return (remaining / remainingDays).clamp(0, double.infinity);
  }

  List<Transaction> get latestTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  // ── Saldo per metode pembayaran ────────────────────────────────────────────
  double balanceOf(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return _cashBalance;
      case PaymentMethod.card:
        return _cardBalance;
      case PaymentMethod.emoney:
        return _eMoneyBalance;
    }
  }

  String methodName(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.emoney:
        return 'E-Money';
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────
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
      Transaction(id: _uuid.v4(), title: 'Bensin Pertalite', amount: 50000,
          type: TransactionType.expense, paymentMethod: PaymentMethod.cash,
          date: now, categoryId: 'transport', note: 'Bensin Pertalite'),
      Transaction(id: _uuid.v4(), title: 'Makan Siang', amount: 35000,
          type: TransactionType.expense, paymentMethod: PaymentMethod.cash,
          date: now.subtract(const Duration(hours: 3)), categoryId: 'food', note: 'Makan Siang'),
      Transaction(id: _uuid.v4(), title: 'Langganan Netflix', amount: 54000,
          type: TransactionType.expense, paymentMethod: PaymentMethod.card,
          date: now.subtract(const Duration(days: 1)), categoryId: 'entertaint', note: 'Langganan Netflix'),
      Transaction(id: _uuid.v4(), title: 'Beli Baju Online', amount: 150000,
          type: TransactionType.expense, paymentMethod: PaymentMethod.card,
          date: now.subtract(const Duration(days: 2)), categoryId: 'shop', note: 'Beli Baju Online'),
      Transaction(id: _uuid.v4(), title: 'Gaji Bulanan', amount: 5000000,
          type: TransactionType.income, paymentMethod: PaymentMethod.card,
          date: DateTime(now.year, now.month, 1), categoryId: 'food', note: 'Gaji Bulanan'),
      Transaction(id: _uuid.v4(), title: 'Beli Obat Apotek', amount: 75000,
          type: TransactionType.expense, paymentMethod: PaymentMethod.cash,
          date: now.subtract(const Duration(days: 3)), categoryId: 'health', note: 'Beli Obat Apotek'),
    ];
  }

  // ── ADD — dengan validasi saldo ───────────────────────────────────────────
  BalanceResult addTransaction(Transaction transaction) {
    // Validasi saldo untuk expense
    if (transaction.type == TransactionType.expense) {
      final currentBalance = balanceOf(transaction.paymentMethod);
      if (transaction.amount > currentBalance) {
        return BalanceResult.error(
          'Saldo ${methodName(transaction.paymentMethod)} tidak cukup.\n'
          'Saldo: ${formatRupiah(currentBalance)}\n'
          'Dibutuhkan: ${formatRupiah(transaction.amount)}',
        );
      }
    }

    _transactions.add(transaction);
    if (transaction.type == TransactionType.expense && !transaction.isTransfer) {
      final idx = _categories.indexWhere((c) => c.id == transaction.categoryId);
      if (idx != -1) _categories[idx].spent += transaction.amount;
    }
    final sign = transaction.type == TransactionType.expense ? -1 : 1;
    _adjustBalance(transaction.paymentMethod, sign * transaction.amount);
    notifyListeners();
    return const BalanceResult.ok();
  }

  BalanceResult addTransfer({
    required double amount,
    required PaymentMethod from,
    required PaymentMethod to,
    required DateTime date,
    String? note,
  }) {
    // Validasi saldo sumber
    final sourceBalance = balanceOf(from);
    if (amount > sourceBalance) {
      return BalanceResult.error(
        'Saldo ${methodName(from)} tidak cukup untuk transfer.\n'
        'Saldo: ${formatRupiah(sourceBalance)}\n'
        'Dibutuhkan: ${formatRupiah(amount)}',
      );
    }
    if (from == to) {
      return BalanceResult.error('Sumber dan tujuan transfer tidak boleh sama.');
    }

    _adjustBalance(from, -amount);
    _adjustBalance(to, amount);
    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: note?.isNotEmpty == true ? note! : 'Transfer → ${methodName(to)}',
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
      title: note?.isNotEmpty == true ? note! : 'Transfer ← ${methodName(from)}',
      amount: amount,
      type: TransactionType.income,
      paymentMethod: to,
      date: date,
      categoryId: 'transfer',
      note: note,
      isTransfer: true,
    ));
    notifyListeners();
    return const BalanceResult.ok();
  }

  // ── EDIT — dengan validasi saldo ──────────────────────────────────────────
  BalanceResult editTransaction({
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
    if (idx == -1) return BalanceResult.error('Transaksi tidak ditemukan.');

    final old = _transactions[idx];

    // Hitung saldo setelah reverse transaksi lama
    final oldSign = old.type == TransactionType.expense ? -1 : 1;
    double simulatedBalance = balanceOf(newPaymentMethod);
    // Jika payment method sama, tambahkan balik efek lama
    if (old.paymentMethod == newPaymentMethod) {
      simulatedBalance -= oldSign * old.amount; // reverse
    }

    // Validasi saldo untuk transaksi baru (jika expense)
    if (newType == TransactionType.expense) {
      // Kalkulasi saldo yang tersedia setelah reverse lama
      double availableBalance = balanceOf(newPaymentMethod);
      if (old.paymentMethod == newPaymentMethod) {
        final oldSignForReverse = old.type == TransactionType.expense ? 1 : -1;
        availableBalance += oldSignForReverse * old.amount;
      }
      if (newAmount > availableBalance) {
        return BalanceResult.error(
          'Saldo ${methodName(newPaymentMethod)} tidak cukup.\n'
          'Tersedia: ${formatRupiah(availableBalance)}\n'
          'Dibutuhkan: ${formatRupiah(newAmount)}',
        );
      }
    }

    // Balik efek lama ke balance
    _adjustBalance(old.paymentMethod, -oldSign * old.amount);

    // Balik efek lama ke category spent
    if (old.type == TransactionType.expense && !old.isTransfer) {
      final catIdx = _categories.indexWhere((c) => c.id == old.categoryId);
      if (catIdx != -1) _categories[catIdx].spent -= old.amount;
    }

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
    return const BalanceResult.ok();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final t = _transactions[idx];
    final sign = t.type == TransactionType.expense ? -1 : 1;
    _adjustBalance(t.paymentMethod, -sign * t.amount);
    if (t.type == TransactionType.expense && !t.isTransfer) {
      final catIdx = _categories.indexWhere((c) => c.id == t.categoryId);
      if (catIdx != -1) _categories[catIdx].spent -= t.amount;
    }
    _transactions.removeAt(idx);
    notifyListeners();
  }

  // ── UPDATE CATEGORY BUDGET — monthly budget otomatis menyesuaikan ─────────
  void updateCategoryBudget(String categoryId, double newBudget) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      _categories[idx] = Category(
        id: _categories[idx].id,
        name: _categories[idx].name,
        icon: _categories[idx].icon,
        budget: newBudget,
        spent: _categories[idx].spent,
      );
      notifyListeners();
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
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

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String formatRupiah(double amount) {
    final abs = amount.abs();
    final formatted = abs.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp$formatted';
  }
}
