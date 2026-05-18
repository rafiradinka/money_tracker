import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'storage_service.dart';

class BalanceResult {
  final bool    success;
  final String? errorMessage;
  const BalanceResult.ok()                : success = true,  errorMessage = null;
  const BalanceResult.error(this.errorMessage) : success = false;
}

class AppState extends ChangeNotifier {
  final _uuid    = const Uuid();
  final _storage = StorageService.instance;

  String _userName      = '';
  double _cashBalance   = 0;
  double _cardBalance   = 0;
  double _eMoneyBalance = 0;

  List<Transaction> _transactions = [];
  List<Category>    _categories   = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  String get userName      => _userName;
  double get cashBalance   => _cashBalance;
  double get cardBalance   => _cardBalance;
  double get eMoneyBalance => _eMoneyBalance;
  double get totalBalance  => _cashBalance + _cardBalance + _eMoneyBalance;

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  // Semua kategori
  List<Category> get categories => List.unmodifiable(_categories);

  // Hanya kategori expense (untuk budget & add expense)
  List<Category> get expenseCategories =>
      _categories.where((c) => c.categoryType == CategoryType.expense).toList();

  // Hanya kategori income (untuk add income)
  List<Category> get incomeCategories =>
      _categories.where((c) => c.categoryType == CategoryType.income).toList();

  // Monthly budget = total budget kategori expense saja
  double get monthlyBudget =>
      expenseCategories.fold(0.0, (s, c) => s + c.budget);

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.isTransfer &&
            t.date.month == now.month &&
            t.date.year  == now.year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  BudgetSummary get budgetSummary =>
      BudgetSummary(monthlyBudget: monthlyBudget, totalSpent: totalSpentThisMonth);

  double get averagePerDay {
    final days = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    return monthlyBudget > 0 ? monthlyBudget / days : 0;
  }

  double get safeRatePerDay {
    final now  = DateTime.now();
    final left = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final rem  = monthlyBudget - totalSpentThisMonth;
    return left > 0 ? (rem / left).clamp(0, double.infinity) : 0;
  }

  List<Transaction> get latestTransactions {
    final sorted = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  double balanceOf(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:   return _cashBalance;
      case PaymentMethod.card:   return _cardBalance;
      case PaymentMethod.emoney: return _eMoneyBalance;
    }
  }

  String methodName(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:   return 'Cash';
      case PaymentMethod.card:   return 'Card';
      case PaymentMethod.emoney: return 'E-Money';
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> loadFromStorage() async {
    _userName      = _storage.userName;
    _cashBalance   = _storage.cashBalance;
    _cardBalance   = _storage.cardBalance;
    _eMoneyBalance = _storage.eMoneyBalance;
    _transactions  = List.from(_storage.transactions);
    _categories    = List.from(_storage.categories);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _storage.saveUserName(name);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveBalances(
      cash: _cashBalance, card: _cardBalance, emoney: _eMoneyBalance,
    );
    await _storage.saveTransactions(_transactions);
    await _storage.saveCategories(_categories);
  }

  // ── ADD Transaction ───────────────────────────────────────────────────────
  BalanceResult addTransaction(Transaction tx) {
    if (tx.type == TransactionType.expense) {
      final bal = balanceOf(tx.paymentMethod);
      if (tx.amount > bal) {
        return BalanceResult.error(
          'Saldo ${methodName(tx.paymentMethod)} tidak cukup.\n'
          'Saldo: ${formatRupiah(bal)}\n'
          'Dibutuhkan: ${formatRupiah(tx.amount)}',
        );
      }
    }
    _transactions.add(tx);
    if (tx.type == TransactionType.expense && !tx.isTransfer) {
      final i = _categories.indexWhere((c) => c.id == tx.categoryId);
      if (i != -1) _categories[i].spent += tx.amount;
    }
    _adjustBalance(tx.paymentMethod,
        tx.type == TransactionType.expense ? -tx.amount : tx.amount);
    _persist();
    notifyListeners();
    return const BalanceResult.ok();
  }

  BalanceResult addTransfer({
    required double amount, required PaymentMethod from,
    required PaymentMethod to, required DateTime date, String? note,
  }) {
    if (from == to) return BalanceResult.error('Sumber dan tujuan tidak boleh sama.');
    final src = balanceOf(from);
    if (amount > src) {
      return BalanceResult.error(
        'Saldo ${methodName(from)} tidak cukup.\n'
        'Saldo: ${formatRupiah(src)}\n'
        'Dibutuhkan: ${formatRupiah(amount)}',
      );
    }
    _adjustBalance(from, -amount);
    _adjustBalance(to,    amount);
    _transactions.addAll([
      Transaction(id: _uuid.v4(),
        title: note?.isNotEmpty == true ? note! : 'Transfer → ${methodName(to)}',
        amount: amount, type: TransactionType.expense, paymentMethod: from,
        date: date, categoryId: 'transfer', note: note, isTransfer: true),
      Transaction(id: _uuid.v4(),
        title: note?.isNotEmpty == true ? note! : 'Transfer ← ${methodName(from)}',
        amount: amount, type: TransactionType.income, paymentMethod: to,
        date: date, categoryId: 'transfer', note: note, isTransfer: true),
    ]);
    _persist();
    notifyListeners();
    return const BalanceResult.ok();
  }

  // ── EDIT Transaction ──────────────────────────────────────────────────────
  BalanceResult editTransaction({
    required String id, required String newTitle, required double newAmount,
    required TransactionType newType, required PaymentMethod newPaymentMethod,
    required DateTime newDate, required String newCategoryId, String? newNote,
  }) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return BalanceResult.error('Transaksi tidak ditemukan.');
    final old = _transactions[idx];

    if (newType == TransactionType.expense) {
      double avail = balanceOf(newPaymentMethod);
      if (old.paymentMethod == newPaymentMethod) {
        avail += old.type == TransactionType.expense ? old.amount : -old.amount;
      }
      if (newAmount > avail) {
        return BalanceResult.error(
          'Saldo ${methodName(newPaymentMethod)} tidak cukup.\n'
          'Tersedia: ${formatRupiah(avail)}\n'
          'Dibutuhkan: ${formatRupiah(newAmount)}',
        );
      }
    }

    // Reverse lama
    _adjustBalance(old.paymentMethod,
        old.type == TransactionType.expense ? old.amount : -old.amount);
    if (old.type == TransactionType.expense && !old.isTransfer) {
      final i = _categories.indexWhere((c) => c.id == old.categoryId);
      if (i != -1) _categories[i].spent -= old.amount;
    }

    // Terapkan baru
    _transactions[idx] = Transaction(
      id: id, title: newTitle, amount: newAmount, type: newType,
      paymentMethod: newPaymentMethod, date: newDate,
      categoryId: newCategoryId, note: newNote, isTransfer: old.isTransfer,
    );
    _adjustBalance(newPaymentMethod,
        newType == TransactionType.expense ? -newAmount : newAmount);
    if (newType == TransactionType.expense && !old.isTransfer) {
      final i = _categories.indexWhere((c) => c.id == newCategoryId);
      if (i != -1) _categories[i].spent += newAmount;
    }

    _persist();
    notifyListeners();
    return const BalanceResult.ok();
  }

  // ── DELETE Transaction ────────────────────────────────────────────────────
  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final t = _transactions[idx];
    _adjustBalance(t.paymentMethod,
        t.type == TransactionType.expense ? t.amount : -t.amount);
    if (t.type == TransactionType.expense && !t.isTransfer) {
      final i = _categories.indexWhere((c) => c.id == t.categoryId);
      if (i != -1) _categories[i].spent -= t.amount;
    }
    _transactions.removeAt(idx);
    _persist();
    notifyListeners();
  }

  // ── CATEGORY CRUD ─────────────────────────────────────────────────────────
  void addCategory({
    required String       name,
    required String       icon,
    required CategoryType categoryType,
    required double       budget,
  }) {
    _categories = [
      ..._categories,
      Category(id: _uuid.v4(), name: name, icon: icon,
               categoryType: categoryType, budget: budget),
    ];
    _persist();
    notifyListeners();
  }

  void editCategory({
    required String       id,
    required String       newName,
    required String       newIcon,
    required CategoryType newCategoryType,
    required double       newBudget,
  }) {
    final i = _categories.indexWhere((c) => c.id == id);
    if (i == -1) return;
    final old = _categories[i];
    _categories[i] = Category(
      id: old.id, name: newName, icon: newIcon,
      categoryType: newCategoryType, budget: newBudget, spent: old.spent,
    );
    _persist();
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categories = _categories.where((c) => c.id != id).toList();
    _persist();
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<Category>.from(_categories);
    list.insert(newIndex, list.removeAt(oldIndex));
    _categories = list;
    _persist();
    notifyListeners();
  }

  void updateCategoryBudget(String categoryId, double newBudget) {
    final i = _categories.indexWhere((c) => c.id == categoryId);
    if (i == -1) return;
    final old = _categories[i];
    _categories[i] = Category(
      id: old.id, name: old.name, icon: old.icon,
      categoryType: old.categoryType, budget: newBudget, spent: old.spent,
    );
    _persist();
    notifyListeners();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  void _adjustBalance(PaymentMethod m, double delta) {
    switch (m) {
      case PaymentMethod.cash:   _cashBalance   += delta; break;
      case PaymentMethod.card:   _cardBalance   += delta; break;
      case PaymentMethod.emoney: _eMoneyBalance += delta; break;
    }
  }

  Category? getCategoryById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  String formatRupiah(double amount) {
    final s = amount.abs().toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp$s';
  }
}
