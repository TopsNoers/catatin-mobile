import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/database/tables/users_table.dart';
import 'database_provider.dart';
import 'user_provider.dart';
import 'category_provider.dart';

// ─── Transaction list (with joined details) ──────────────────────────────────

final transactionsProvider =
    StreamProvider<List<TransactionWithDetails>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  if (userId == null) return const Stream.empty();

  return ref.watch(transactionRepositoryProvider).watchTransactions(
        userId,
        month: selectedMonth.month,
        year: selectedMonth.year,
      );
});

final recentTransactionsProvider =
    StreamProvider<List<TransactionWithDetails>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final now = DateTime.now();
  return ref.watch(transactionRepositoryProvider).watchTransactions(
        userId,
        month: now.month,
        year: now.year,
      );
});

// ─── Monthly summary ─────────────────────────────────────────────────────────

final monthlySummaryProvider = StreamProvider<MonthlySummary>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  if (userId == null) {
    return Stream.value(
        const MonthlySummary(totalIncome: 0, totalExpense: 0));
  }
  return ref.watch(transactionRepositoryProvider).watchMonthlySummary(
        userId,
        selectedMonth.month,
        selectedMonth.year,
      );
});

// ─── Category Summaries ──────────────────────────────────────────────────────

final categoryExpenseSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  if (userId == null) return {};

  return ref.watch(transactionRepositoryProvider).getCategorySummary(
        userId,
        selectedMonth.month,
        selectedMonth.year,
        TransactionType.expense,
      );
});

final categoryIncomeSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  if (userId == null) return {};

  return ref.watch(transactionRepositoryProvider).getCategorySummary(
        userId,
        selectedMonth.month,
        selectedMonth.year,
        TransactionType.income,
      );
});
