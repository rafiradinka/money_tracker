import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Semua key yang digunakan untuk SharedPreferences
class _Keys {
  static const userName       = 'user_name';
  static const cashBalance    = 'cash_balance';
  static const cardBalance    = 'card_balance';
  static const eMoneyBalance  = 'emoney_balance';
  static const transactions   = 'transactions';
  static const categories     = 'categories';
  static const isFirstLaunch  = 'is_first_launch';
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── First launch ──────────────────────────────────────────────────────────
  bool get isFirstLaunch => _prefs.getBool(_Keys.isFirstLaunch) ?? true;
  Future<void> setFirstLaunchDone() =>
      _prefs.setBool(_Keys.isFirstLaunch, false);

  // ── User ──────────────────────────────────────────────────────────────────
  String get userName => _prefs.getString(_Keys.userName) ?? '';
  Future<void> saveUserName(String name) =>
      _prefs.setString(_Keys.userName, name);

  // ── Balances ──────────────────────────────────────────────────────────────
  double get cashBalance   => _prefs.getDouble(_Keys.cashBalance)   ?? 800000;
  double get cardBalance   => _prefs.getDouble(_Keys.cardBalance)   ?? 12000000;
  double get eMoneyBalance => _prefs.getDouble(_Keys.eMoneyBalance) ?? 0;

  Future<void> saveBalances({
    required double cash,
    required double card,
    required double emoney,
  }) async {
    await _prefs.setDouble(_Keys.cashBalance,   cash);
    await _prefs.setDouble(_Keys.cardBalance,   card);
    await _prefs.setDouble(_Keys.eMoneyBalance, emoney);
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  List<Transaction> get transactions {
    final raw = _prefs.getString(_Keys.transactions);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _txFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<Transaction> txs) async {
    final list = txs.map(_txToJson).toList();
    await _prefs.setString(_Keys.transactions, jsonEncode(list));
  }

  // ── Categories ────────────────────────────────────────────────────────────
  List<Category> get categories {
    final raw = _prefs.getString(_Keys.categories);
    if (raw == null) return _defaultCategories();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _catFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultCategories();
    }
  }

  Future<void> saveCategories(List<Category> cats) async {
    final list = cats.map(_catToJson).toList();
    await _prefs.setString(_Keys.categories, jsonEncode(list));
  }

  // ── Clear all (logout / reset) ────────────────────────────────────────────
  Future<void> clearAll() => _prefs.clear();

  // ── Serialization helpers ─────────────────────────────────────────────────
  Map<String, dynamic> _txToJson(Transaction t) => {
        'id': t.id,
        'title': t.title,
        'amount': t.amount,
        'type': t.type.name,
        'paymentMethod': t.paymentMethod.name,
        'date': t.date.toIso8601String(),
        'categoryId': t.categoryId,
        'note': t.note,
        'isTransfer': t.isTransfer,
      };

  Transaction _txFromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: TransactionType.values.byName(j['type'] as String),
        paymentMethod: PaymentMethod.values.byName(j['paymentMethod'] as String),
        date: DateTime.parse(j['date'] as String),
        categoryId: j['categoryId'] as String,
        note: j['note'] as String?,
        isTransfer: j['isTransfer'] as bool? ?? false,
      );

  Map<String, dynamic> _catToJson(Category c) => {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'budget': c.budget,
        'spent': c.spent,
      };

  Category _catFromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        budget: (j['budget'] as num).toDouble(),
        spent: (j['spent'] as num).toDouble(),
      );

  List<Category> _defaultCategories() => [
        Category(id: 'food',       name: 'Food',          icon: '🍴', budget: 200000),
        Category(id: 'transport',  name: 'Transportation', icon: '🚌', budget: 300000),
        Category(id: 'entertaint', name: 'Entertaint',     icon: '😊', budget: 100000),
        Category(id: 'shop',       name: 'Shop',           icon: '🛒', budget: 200000),
        Category(id: 'health',     name: 'Health',         icon: '❤️', budget: 200000),
      ];
}
