import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/providers/transaction_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthlySummary(),
            const SizedBox(height: 24),
            Text(
              'Pengeluaran per Kategori',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildExpenseChart(),
            const SizedBox(height: 24),
            Text(
              'Pemasukan per Kategori',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildIncomeChart(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Sisa Saldo Bulan Ini',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(summary.netBalance),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      icon: LucideIcons.arrowDownCircle,
                      iconColor: AppColors.income,
                      label: 'Pemasukan',
                      amount: summary.totalIncome,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: LucideIcons.arrowUpCircle,
                      iconColor: AppColors.expense,
                      label: 'Pengeluaran',
                      amount: summary.totalExpense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildExpenseChart() {
    final expenseAsync = ref.watch(categoryExpenseSummaryProvider);
    return _buildChartFromAsync(expenseAsync, isExpense: true);
  }

  Widget _buildIncomeChart() {
    final incomeAsync = ref.watch(categoryIncomeSummaryProvider);
    return _buildChartFromAsync(incomeAsync, isExpense: false);
  }

  Widget _buildChartFromAsync(AsyncValue<Map<String, double>> asyncValue, {required bool isExpense}) {
    return asyncValue.when(
      data: (data) {
        if (data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: const Center(
              child: Text('Belum ada data untuk bulan ini.'),
            ),
          );
        }

        final colors = [
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.income,
          const Color(0xFFFFB74D),
          AppColors.expense,
          const Color(0xFF9C27B0),
          const Color(0xFF009688),
          const Color(0xFFFF9800),
        ];

        final total = data.values.fold<double>(0, (sum, value) => sum + value);
        
        List<PieChartSectionData> sections = [];
        List<Widget> legend = [];
        
        int i = 0;
        // Sort data by amount descending
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (final entry in sortedEntries) {
          final category = entry.key;
          final amount = entry.value;
          final color = colors[i % colors.length];
          final percentage = (amount / total) * 100;
          
          sections.add(
            PieChartSectionData(
              color: color,
              value: amount,
              title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );

          legend.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _currencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
          
          i++;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ...legend,
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
