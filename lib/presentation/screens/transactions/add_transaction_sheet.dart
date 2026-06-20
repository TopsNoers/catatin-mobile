import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/category_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/user_provider.dart';
import '../../../domain/providers/wallet_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategoryId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.expense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _type = _tabController.index == 0
              ? TransactionType.income
              : TransactionType.expense;
          _selectedCategoryId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''));
      final userId = ref.read(currentUserIdProvider)!;

      await ref.read(transactionRepositoryProvider).createTransaction(
            userId: userId,
            walletId: _selectedWalletId!,
            categoryId: _selectedCategoryId!,
            amount: amount,
            type: _type,
            note: _noteController.text.isEmpty ? null : _noteController.text,
            date: _selectedDate,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = _type == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    // Auto-select first wallet
    walletsAsync.whenData((wallets) {
      if (wallets.isNotEmpty && _selectedWalletId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedWalletId = wallets.first.id);
        });
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Tab bar (income / expense)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _type == TransactionType.income
                            ? AppColors.incomeGradient
                            : AppColors.expenseGradient,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        Theme.of(context).textTheme.bodySmall?.color,
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: '📈  Pemasukan'),
                      Tab(text: '📉  Pengeluaran'),
                    ],
                  ),
                ),
              ),
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    children: [
                      // Amount input
                      _buildAmountField(context),
                      const SizedBox(height: 16),
                      // Category grid
                      Text('Kategori',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      categoriesAsync.when(
                        data: (cats) => _buildCategoryGrid(cats),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 16),
                      // Wallet selector
                      Text('Dompet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      walletsAsync.when(
                        data: (wallets) => _buildWalletSelector(wallets),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 16),
                      // Date picker
                      Text('Tanggal',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      _buildDatePicker(context),
                      const SizedBox(height: 16),
                      // Note
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _type == TransactionType.income
                                    ? AppColors.income
                                    : AppColors.expense,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan Transaksi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _type == TransactionType.income
              ? AppColors.incomeGradient
              : AppColors.expenseGradient,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _type == TransactionType.income ? 'Jumlah Pemasukan' : 'Jumlah Pengeluaran',
            style:
                const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 28),
            ),
            validator: (v) =>
                (v == null || v.isEmpty || v == '0') ? 'Masukkan jumlah' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;
        final catColor = cat.color != null
            ? Color(int.parse(
                cat.color!.replaceFirst('#', 'FF'), radix: 16))
            : AppColors.primary;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoryId = cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withOpacity(0.2)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? catColor
                    : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.getIcon(cat.icon),
                    size: 20,
                    color: isSelected ? catColor : Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? catColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletSelector(List<Wallet> wallets) {
    if (wallets.isEmpty) {
      return const Text('Belum ada dompet. Tambahkan di tab Dompet.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wallets.map((w) {
        final isSelected = _selectedWalletId == w.id;
        final wColor = Color(
            int.parse(w.color.replaceFirst('#', 'FF'), radix: 16));
        return GestureDetector(
          onTap: () => setState(() => _selectedWalletId = w.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? wColor.withOpacity(0.15)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? wColor
                    : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    size: 18, color: isSelected ? wColor : null),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? wColor : null,
                        )),
                    Text(
                      CurrencyFormatter.formatCompact(w.balance),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormatter.formatDate(_selectedDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
