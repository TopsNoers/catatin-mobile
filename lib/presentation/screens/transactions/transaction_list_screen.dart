import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/tables/users_table.dart';
import '../../../domain/providers/transaction_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../widgets/transaction_card.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau kategori...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pemasukan'),
                        selected: _selectedType == TransactionType.income,
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = TransactionType.income;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pengeluaran'),
                        selected: _selectedType == TransactionType.expense,
                        selectedColor: Colors.red.withOpacity(0.2),
                        checkmarkColor: Colors.red,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = TransactionType.expense;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (txList) {
          final filteredList = txList.where((tx) {
            final matchesType = _selectedType == null || tx.transaction.type == _selectedType;
            final matchesSearch = _searchQuery.isEmpty ||
                (tx.transaction.note?.toLowerCase().contains(_searchQuery) ?? false) ||
                (tx.category.name.toLowerCase().contains(_searchQuery));
            return matchesType && matchesSearch;
          }).toList();

          if (filteredList.isEmpty) {
            return const Center(
              child: Text('Tidak ada transaksi ditemukan'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final tx = filteredList[index];
              return TransactionCard(
                data: tx,
                onDelete: () async {
                  await ref
                      .read(transactionRepositoryProvider)
                      .deleteTransaction(tx.transaction.id);
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
