import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_icons.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/category_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/user_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeCategoriesProvider);
    final expenseAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.primary.withOpacity(0.15),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          tabs: const [
            Tab(text: '📈  Pemasukan'),
            Tab(text: '📉  Pengeluaran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(
            asyncCategories: incomeAsync,
            onDelete: (id) async {
              await ref.read(categoryRepositoryProvider).deleteCategory(id);
            },
          ),
          _CategoryList(
            asyncCategories: expenseAsync,
            onDelete: (id) async {
              await ref.read(categoryRepositoryProvider).deleteCategory(id);
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(
        onSubmit: (name, icon, color, type) async {
          final userId = ref.read(currentUserIdProvider)!;
          await ref.read(categoryRepositoryProvider).createCategory(
                userId: userId,
                name: name,
                type: type,
                icon: icon,
                color: color,
              );
        },
      ),
    );
  }
}

// ─── Category List ────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final AsyncValue<List<Category>> asyncCategories;
  final void Function(String id) onDelete;

  const _CategoryList(
      {required this.asyncCategories, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return asyncCategories.when(
      data: (cats) {
        if (cats.isEmpty) {
          return const Center(
              child: Text('Belum ada kategori'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final cat = cats[i];
            final color = cat.color != null
                ? Color(int.parse(
                    cat.color!.replaceFirst('#', 'FF'), radix: 16))
                : AppColors.primary;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.getIcon(cat.icon),
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(cat.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded,
                        color: AppColors.expense, size: 20),
                    onPressed: () => onDelete(cat.id),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Category Dialog ──────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  final Future<void> Function(
      String name, String icon, String color, TransactionType type) onSubmit;

  const _CategoryDialog({required this.onSubmit});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = AppIcons.availableIcons.first;
  String _selectedColor = '#6C63FF';
  TransactionType _type = TransactionType.expense;
  bool _isLoading = false;

  final _icons = AppIcons.availableIcons;

  final _colors = [
    '#6C63FF', '#FF6B6B', '#2DD4BF', '#FFEAA7',
    '#74B9FF', '#A29BFE', '#FD79A8', '#55EFC4',
    '#FDCB6E', '#E17055', '#00B894', '#0984E3',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Kategori Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _type = TransactionType.income),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == TransactionType.income
                            ? AppColors.income.withOpacity(0.2)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == TransactionType.income
                              ? AppColors.income
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Text('📈 Pemasukan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _type == TransactionType.income
                                  ? AppColors.income
                                  : null,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == TransactionType.expense
                            ? AppColors.expense.withOpacity(0.2)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == TransactionType.expense
                              ? AppColors.expense
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Text('📉 Pengeluaran',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _type == TransactionType.expense
                                  ? AppColors.expense
                                  : null,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
              ),
            ),
            const SizedBox(height: 14),
            const Text('Ikon', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _icons.map((ic) {
                final isSelected = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.getIcon(ic),
                        color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
                        size: 22,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Warna', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final color = Color(
                    int.parse(c.replaceFirst('#', 'FF'), radix: 16));
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty) return;
                  setState(() => _isLoading = true);
                  await widget.onSubmit(
                    _nameController.text.trim(),
                    _selectedIcon,
                    _selectedColor,
                    _type,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
