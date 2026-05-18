import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class _Keys {
  static const userName      = 'user_name';
  static const cashBalance   = 'cash_balance';
  static const cardBalance   = 'card_balance';
  static const eMoneyBalance = 'emoney_balance';
  static const transactions  = 'transactions';
  static const categories    = 'categories';
  static const isFirstLaunch = 'is_first_launch';
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool   get isFirstLaunch => _prefs.getBool(_Keys.isFirstLaunch) ?? true;
  Future<void> setFirstLaunchDone() => _prefs.setBool(_Keys.isFirstLaunch, false);

  String get userName => _prefs.getString(_Keys.userName) ?? '';
  Future<void> saveUserName(String name) => _prefs.setString(_Keys.userName, name);

  double get cashBalance   => _prefs.getDouble(_Keys.cashBalance)   ?? 0;
  double get cardBalance   => _prefs.getDouble(_Keys.cardBalance)   ?? 0;
  double get eMoneyBalance => _prefs.getDouble(_Keys.eMoneyBalance) ?? 0;

  Future<void> saveBalances({
    required double cash, required double card, required double emoney,
  }) async {
    await _prefs.setDouble(_Keys.cashBalance,   cash);
    await _prefs.setDouble(_Keys.cardBalance,   card);
    await _prefs.setDouble(_Keys.eMoneyBalance, emoney);
  }

  List<Transaction> get transactions {
    final raw = _prefs.getString(_Keys.transactions);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => _txFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) { return []; }
  }

  Future<void> saveTransactions(List<Transaction> txs) =>
      _prefs.setString(_Keys.transactions, jsonEncode(txs.map(_txToJson).toList()));

  List<Category> get categories {
    final raw = _prefs.getString(_Keys.categories);
    if (raw == null) return _defaultCategories();
    try {
      return (jsonDecode(raw) as List)
          .map((e) => _catFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) { return _defaultCategories(); }
  }

  Future<void> saveCategories(List<Category> cats) =>
      _prefs.setString(_Keys.categories, jsonEncode(cats.map(_catToJson).toList()));

  Future<void> clearAll() => _prefs.clear();

  // ── Serialization ────────────────────────────────────────────────────────
  Map<String, dynamic> _txToJson(Transaction t) => {
    'id': t.id, 'title': t.title, 'amount': t.amount,
    'type': t.type.name, 'paymentMethod': t.paymentMethod.name,
    'date': t.date.toIso8601String(), 'categoryId': t.categoryId,
    'note': t.note, 'isTransfer': t.isTransfer,
  };

  Transaction _txFromJson(Map<String, dynamic> j) => Transaction(
    id: j['id'] as String, title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(),
    type: TransactionType.values.byName(j['type'] as String),
    paymentMethod: PaymentMethod.values.byName(j['paymentMethod'] as String),
    date: DateTime.parse(j['date'] as String),
    categoryId: j['categoryId'] as String,
    note: j['note'] as String?,
    isTransfer: j['isTransfer'] as bool? ?? false,
  );

  Map<String, dynamic> _catToJson(Category c) => {
    'id': c.id, 'name': c.name, 'icon': c.icon,
    'categoryType': c.categoryType.name,
    'budget': c.budget, 'spent': c.spent,
  };

  Category _catFromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String, name: j['name'] as String, icon: j['icon'] as String,
    categoryType: CategoryType.values.byName(j['categoryType'] as String? ?? 'expense'),
    budget: (j['budget'] as num).toDouble(),
    spent:  (j['spent']  as num).toDouble(),
  );

  List<Category> _defaultCategories() => [
    // Expense defaults
    Category(id: 'food',       name: 'Food',          icon: '🍴', categoryType: CategoryType.expense, budget: 200000),
    Category(id: 'transport',  name: 'Transportation', icon: '🚌', categoryType: CategoryType.expense, budget: 300000),
    Category(id: 'entertaint', name: 'Entertaint',     icon: '😊', categoryType: CategoryType.expense, budget: 100000),
    Category(id: 'shop',       name: 'Shop',           icon: '🛒', categoryType: CategoryType.expense, budget: 200000),
    Category(id: 'health',     name: 'Health',         icon: '❤️', categoryType: CategoryType.expense, budget: 200000),
    // Income defaults
    Category(id: 'salary',     name: 'Salary',         icon: '💼', categoryType: CategoryType.income,  budget: 0),
    Category(id: 'sidehustle', name: 'Side Hustle',    icon: '💡', categoryType: CategoryType.income,  budget: 0),
    Category(id: 'investment', name: 'Investment',     icon: '📈', categoryType: CategoryType.income,  budget: 0),
  ];
}
