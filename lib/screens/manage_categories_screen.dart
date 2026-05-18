import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

const _emojiList = [
  '🍴','🍕','☕','🛒','🚌','🚗','✈️','🏠','💊','❤️',
  '🎮','🎬','🎵','📚','👗','👟','💄','🐾','⚽','🏋️',
  '💡','📱','💻','🔧','🌿','🎁','💰','📊','🧾','🏦',
  '💼','📈','🤝','🎓','🏪','🌟','🛵','🏖️','🍺','🎪',
];

class ManageCategoriesScreen extends StatefulWidget {
  final CategoryType initialTab;
  const ManageCategoriesScreen({super.key, this.initialTab = CategoryType.expense});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, vsync: this,
      initialIndex: widget.initialTab == CategoryType.income ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CategoryType get _currentType =>
      _tabController.index == 0 ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Kelola Kategori',
            style: TextStyle(color: AppColors.white, fontSize: 18,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showForm(context, state, null),
            icon: const Icon(Icons.add_rounded, color: AppColors.orange, size: 20),
            label: const Text('Tambah',
                style: TextStyle(color: AppColors.orange, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.orange, width: 3),
          ),
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(
            categories: state.expenseCategories,
            state: state,
            onEdit: (cat) => _showForm(context, state, cat),
            onDelete: (cat) => _confirmDelete(context, state, cat),
          ),
          _CategoryList(
            categories: state.incomeCategories,
            state: state,
            onEdit: (cat) => _showForm(context, state, cat),
            onDelete: (cat) => _confirmDelete(context, state, cat),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, AppState state, Category? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        existing: existing,
        state: state,
        defaultType: _currentType,
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(children: [
          Text(cat.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Hapus ${cat.name}?',
              style: const TextStyle(color: AppColors.white, fontSize: 16)),
        ]),
        content: const Text(
          'Transaksi yang sudah ada tidak akan terhapus.',
          style: TextStyle(color: AppColors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.grey))),
          TextButton(
            onPressed: () { state.deleteCategory(cat.id); Navigator.pop(ctx); },
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Category list with reorder ────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final List<Category> categories;
  final AppState state;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;

  const _CategoryList({
    required this.categories, required this.state,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📂', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('Belum ada kategori.',
                style: TextStyle(color: AppColors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Tap "Tambah" untuk membuat kategori baru.',
                style: TextStyle(color: AppColors.greyDark, fontSize: 12)),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: categories.length,
      onReorder: (o, n) {
        // Cari index asli di state.categories
        final allCats = state.categories.toList();
        final oldGlobal = allCats.indexWhere((c) => c.id == categories[o].id);
        final newGlobal = allCats.indexWhere((c) => c.id == categories[n > o ? n - 1 : n].id);
        if (oldGlobal != -1 && newGlobal != -1) {
          state.reorderCategories(oldGlobal, newGlobal);
        }
      },
      itemBuilder: (_, i) {
        final cat = categories[i];
        return _CategoryTile(
          key: ValueKey(cat.id),
          category: cat,
          formatRupiah: state.formatRupiah,
          onEdit: () => onEdit(cat),
          onDelete: () => onDelete(cat),
        );
      },
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final String Function(double) formatRupiah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    super.key, required this.category, required this.formatRupiah,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = category.categoryType == CategoryType.expense;
    final pct = category.budget > 0
        ? (category.spent / category.budget * 100).round() : 0;
    final isOver = category.isOverBudget;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle_rounded, color: AppColors.greyDark, size: 20),
          const SizedBox(width: 12),
          Text(category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(color: AppColors.white,
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                if (isExpense)
                  Text(
                    '${formatRupiah(category.spent)} / ${formatRupiah(category.budget)}'
                    '  ($pct%${isOver ? ' ⚠️' : ''})',
                    style: TextStyle(
                      color: isOver ? AppColors.red : AppColors.grey,
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    'Total masuk: ${formatRupiah(category.spent)}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.orange, size: 18),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Form Sheet ────────────────────────────────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final Category?    existing;
  final AppState     state;
  final CategoryType defaultType;

  const _CategoryFormSheet({
    required this.existing, required this.state, required this.defaultType,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameController   = TextEditingController();
  final _budgetController = TextEditingController();
  String       _emoji        = '💰';
  CategoryType _categoryType = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text   = e.name;
      _budgetController.text = e.budget.toStringAsFixed(0);
      _emoji                 = e.icon;
      _categoryType          = e.categoryType;
    } else {
      _categoryType = widget.defaultType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() {
    final name   = _nameController.text.trim();
    final budget = double.tryParse(
        _budgetController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nama tidak boleh kosong'),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    if (widget.existing != null) {
      widget.state.editCategory(
        id: widget.existing!.id, newName: name, newIcon: _emoji,
        newCategoryType: _categoryType, newBudget: budget,
      );
    } else {
      widget.state.addCategory(
        name: name, icon: _emoji, categoryType: _categoryType, budget: budget,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit    = widget.existing != null;
    final isExpense = _categoryType == CategoryType.expense;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyDark, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Kategori' : 'Kategori Baru',
                style: const TextStyle(color: AppColors.white, fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Tipe kategori
            Container(
              decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TypeBtn(label: 'Pengeluaran',
                      selected: isExpense,
                      color: AppColors.red,
                      onTap: () => setState(() => _categoryType = CategoryType.expense)),
                  _TypeBtn(label: 'Pemasukan',
                      selected: !isExpense,
                      color: AppColors.green,
                      onTap: () => setState(() => _categoryType = CategoryType.income)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            const Text('Ikon', style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiList.length,
                itemBuilder: (_, i) {
                  final e   = _emojiList[i];
                  final sel = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.orange.withOpacity(0.15) : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.orange : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Nama
            const Text('Nama Kategori',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Olahraga, Salary...',
                  hintStyle: TextStyle(color: AppColors.greyDark, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            // Budget (hanya untuk expense)
            if (isExpense) ...[
              const SizedBox(height: 14),
              const Text('Budget Bulanan',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card, borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(color: AppColors.orange),
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.greyDark),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kategori',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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

  const _TypeBtn({required this.label, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.grey,
                fontWeight: FontWeight.w600, fontSize: 13,
              )),
        ),
      ),
    );
  }
}
