import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/category_provider.dart';
import '../../../domain/providers/transaction_provider.dart';
import '../../../domain/providers/wallet_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_card.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_list_screen.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                // Logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.wallet, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catatin',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Keuangan Pribadi',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                // Month picker
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ref, selectedMonth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatMonthYear(selectedMonth),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Balance Summary Card ───────────────────────────────
                summaryAsync.when(
                  data: (summary) => totalBalanceAsync.when(
                    data: (total) => BalanceSummaryCard(
                      totalBalance: total,
                      totalIncome: summary.totalIncome,
                      totalExpense: summary.totalExpense,
                      monthLabel: DateFormatter.formatMonthYear(selectedMonth),
                    ),
                    loading: () => const _ShimmerCard(height: 200),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const _ShimmerCard(height: 200),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 28),

                // ── Quick Stats Row ────────────────────────────────────
                recentTxAsync.when(
                  data: (txList) => _QuickStatsRow(
                    transactionCount: txList.length,
                    avgExpense: txList
                        .where((t) =>
                            t.transaction.type ==
                            TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.transaction.amount),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 28),

                // ── Recent Transactions ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaksi Terbaru',
                        style: Theme.of(context).textTheme.headlineSmall),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                recentTxAsync.when(
                  data: (txList) {
                    if (txList.isEmpty) {
                      return const _EmptyState();
                    }
                    final limited = txList.take(5).toList();
                    return Column(
                      children: limited
                          .map((tx) => TransactionCard(
                                data: tx,
                                onDelete: () async {
                                  await ref
                                      .read(transactionRepositoryProvider)
                                      .deleteTransaction(
                                          tx.transaction.id);
                                },
                              ))
                          .toList(),
                    );
                  },
                  loading: () => Column(
                    children: List.generate(
                        4, (_) => const _ShimmerCard(height: 72)),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 100), // FAB clearance
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(context),
        child: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _showMonthPicker(
      BuildContext context, WidgetRef ref, DateTime current) {
    showDialog(
      context: context,
      builder: (ctx) => _MonthPickerDialog(
        current: current,
        onSelected: (dt) {
          ref.read(selectedMonthProvider.notifier).state = dt;
        },
      ),
    );
  }
}

// ─── Month Picker Dialog ─────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  final DateTime current;
  final void Function(DateTime) onSelected;

  const _MonthPickerDialog(
      {required this.current, required this.onSelected});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _month = widget.current.month;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setState(() => _year--)),
          Text('$_year',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => setState(() => _year++)),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (ctx, i) {
            final isSelected = i + 1 == _month && _year == widget.current.year;
            return GestureDetector(
              onTap: () {
                widget.onSelected(DateTime(_year, i + 1));
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    months[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Quick Stats Row ─────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final int transactionCount;
  final double avgExpense;

  const _QuickStatsRow(
      {required this.transactionCount, required this.avgExpense});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Transaksi',
            value: '$transactionCount',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_down_rounded,
            label: 'Total Keluar',
            value: CurrencyFormatter.formatCompact(avgExpense),
            color: AppColors.expense,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💸', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Transaksi',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah\ntransaksi pertamamu',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer placeholder ─────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final double height;

  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
