import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';
import 'user_provider.dart';

// ─── Selected month/year for filtering ──────────────────────────────────────

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// ─── Categories by type ──────────────────────────────────────────────────────

final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref
      .watch(categoryRepositoryProvider)
      .watchCategoriesByType(userId, TransactionType.income);
});

final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref
      .watch(categoryRepositoryProvider)
      .watchCategoriesByType(userId, TransactionType.expense);
});

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(categoryRepositoryProvider).watchCategories(userId);
});
