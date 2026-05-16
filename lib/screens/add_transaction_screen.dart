import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _uuid = const Uuid();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  String _selectedCategoryId = 'food';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();

    final amount =
        double.tryParse(_amountController.text);

    if (_titleController.text.isEmpty ||
        amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill title and amount',
          ),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final transaction = Transaction(
      id: _uuid.v4(),
      title: _titleController.text,
      amount: amount,
      type: _type,
      paymentMethod: _paymentMethod,
      date: DateTime.now(),
      categoryId: _selectedCategoryId,
      note: _noteController.text.isEmpty
          ? null
          : _noteController.text,
    );

    state.addTransaction(transaction);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        title: const Text(
          'Add Transaction',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // TYPE TOGGLE
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Row(
                children: [
                  _TypeButton(
                    label: 'Expense',
                    selected:
                        _type ==
                        TransactionType.expense,
                    onTap:
                        () => setState(
                          () => _type =
                              TransactionType
                                  .expense,
                        ),
                  ),

                  _TypeButton(
                    label: 'Income',
                    selected:
                        _type ==
                        TransactionType.income,
                    onTap:
                        () => setState(
                          () => _type =
                              TransactionType
                                  .income,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AMOUNT
            _buildLabel('Amount'),

            const SizedBox(height: 8),

            _buildTextField(
              controller: _amountController,
              hint: '0',
              prefix: 'Rp ',
              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 16),

            // TITLE
            _buildLabel('Title'),

            const SizedBox(height: 8),

            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Makan Siang',
            ),

            const SizedBox(height: 16),

            // PAYMENT METHOD
            _buildLabel('Payment Method'),

            const SizedBox(height: 8),

            Row(
              children: [
                _PaymentChip(
                  label: 'Cash',
                  selected:
                      _paymentMethod ==
                      PaymentMethod.cash,
                  onTap:
                      () => setState(
                        () => _paymentMethod =
                            PaymentMethod.cash,
                      ),
                ),

                const SizedBox(width: 10),

                _PaymentChip(
                  label: 'Card',
                  selected:
                      _paymentMethod ==
                      PaymentMethod.card,
                  onTap:
                      () => setState(
                        () => _paymentMethod =
                            PaymentMethod.card,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CATEGORY
            _buildLabel('Category'),

            const SizedBox(height: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: DropdownButton<String>(
                value: _selectedCategoryId,

                isExpanded: true,

                dropdownColor:
                    AppColors.surface,

                underline: const SizedBox(),

                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ),

                items:
                    state.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,

                        child: Row(
                          children: [
                            Text(cat.icon),

                            const SizedBox(
                              width: 10,
                            ),

                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),

                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategoryId =
                          val;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // NOTE
            _buildLabel('Note (optional)'),

            const SizedBox(height: 8),

            _buildTextField(
              controller: _noteController,
              hint: 'Add a note...',
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _save,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.orange,

                  padding:
                      const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                  ),
                ),

                child: const Text(
                  'Save Transaction',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,

      style: const TextStyle(
        color: AppColors.grey,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,

    String? prefix,

    TextInputType keyboardType =
        TextInputType.text,

    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(12),
      ),

      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,

        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
        ),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(
            color: AppColors.greyDark,
          ),

          prefixText: prefix,

          prefixStyle: const TextStyle(
            color: AppColors.orange,
          ),

          border: InputBorder.none,

          contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.symmetric(
                vertical: 12,
              ),

          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.orange
                    : Colors.transparent,

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Text(
            label,

            textAlign: TextAlign.center,

            style: TextStyle(
              color:
                  selected
                      ? Colors.white
                      : AppColors.grey,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),

        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.orange
                  : AppColors.surface,

          borderRadius:
              BorderRadius.circular(10),

          border: Border.all(
            color:
                selected
                    ? AppColors.orange
                    : AppColors.greyDark,
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color:
                selected
                    ? Colors.white
                    : AppColors.grey,

            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}