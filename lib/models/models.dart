enum TransactionType { income, expense }
enum PaymentMethod   { cash, card, emoney }
// untuk memisahkan kategori expense vs income
enum CategoryType    { expense, income }

class Category {
  final String       id;
  final String       name;
  final String       icon;
  final CategoryType categoryType; // expense atau income
  final double       budget;       // hanya relevan untuk expense
  double             spent;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.categoryType = CategoryType.expense,
    this.budget       = 0,
    this.spent        = 0,
  });

  double get remaining    => budget - spent;
  double get percentage   => budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0;
  bool   get isOverBudget => spent > budget;
}

class Transaction {
  final String          id;
  final String          title;
  final double          amount;
  final TransactionType type;
  final PaymentMethod   paymentMethod;
  final DateTime        date;
  final String          categoryId;
  final String?         note;
  final bool            isTransfer;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.date,
    required this.categoryId,
    this.note       = null,
    this.isTransfer = false,
  });

  Transaction copyWith({
    String? title, double? amount, TransactionType? type,
    PaymentMethod? paymentMethod, DateTime? date,
    String? categoryId, String? note,
  }) => Transaction(
    id: id,
    title:         title         ?? this.title,
    amount:        amount        ?? this.amount,
    type:          type          ?? this.type,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    date:          date          ?? this.date,
    categoryId:    categoryId    ?? this.categoryId,
    note:          note          ?? this.note,
    isTransfer:    isTransfer,
  );
}

class BudgetSummary {
  final double monthlyBudget;
  final double totalSpent;

  BudgetSummary({required this.monthlyBudget, required this.totalSpent});

  double get remaining     => monthlyBudget - totalSpent;
  double get percentage    =>
      monthlyBudget > 0 ? (totalSpent / monthlyBudget).clamp(0.0, 1.0) : 0;
  int    get percentageInt => (percentage * 100).round();
}
