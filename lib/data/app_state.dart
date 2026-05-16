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

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
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
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Makan Siang',
        amount: 35000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(hours: 3)),
        categoryId: 'food',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Netflix',
        amount: 54000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 1)),
        categoryId: 'entertaint',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Belanja Online',
        amount: 150000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        date: now.subtract(const Duration(days: 2)),
        categoryId: 'shop',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Gaji Bulanan',
        amount: 5000000,
        type: TransactionType.income,
        paymentMethod: PaymentMethod.card,
        date: DateTime(now.year, now.month, 1),
        categoryId: 'food',
      ),
      Transaction(
        id: _uuid.v4(),
        title: 'Apotek',
        amount: 75000,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(days: 3)),
        categoryId: 'health',
      ),
    ];
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    if (transaction.type == TransactionType.expense) {
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
    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: 'Transfer → ${_methodName(to)}',
      amount: amount,
      type: TransactionType.expense,
      paymentMethod: from,
      date: date,
      categoryId: 'transport',
      note: note,
    ));
    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: 'Transfer ← ${_methodName(from)}',
      amount: amount,
      type: TransactionType.income,
      paymentMethod: to,
      date: date,
      categoryId: 'transport',
      note: note,
    ));
    notifyListeners();
  }

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
