import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'wallet_repository.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Category category;
  final Wallet wallet;

  const TransactionWithDetails({
    required this.transaction,
    required this.category,
    required this.wallet,
  });
}

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  double get netBalance => totalIncome - totalExpense;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
  });
}

class TransactionRepository {
  final AppDatabase _db;
  final WalletRepository _walletRepo;
  final _uuid = const Uuid();

  TransactionRepository(this._db, this._walletRepo);

  // Watch all transactions for a user with joins
  Stream<List<TransactionWithDetails>> watchTransactions(
    String userId, {
    int? month,
    int? year,
    String? walletId,
    String? categoryId,
    TransactionType? type,
  }) {
    final query = _db.select(_db.transactions).join([
      innerJoin(
          _db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
      innerJoin(
          _db.wallets, _db.wallets.id.equalsExp(_db.transactions.walletId)),
    ])
      ..where(_db.transactions.userId.equals(userId));

    if (walletId != null) {
      query.where(_db.transactions.walletId.equals(walletId));
    }
    if (categoryId != null) {
      query.where(_db.transactions.categoryId.equals(categoryId));
    }
    if (type != null) {
      query.where(_db.transactions.type
          .equals(TransactionType.values.indexOf(type)));
    }
    if (month != null && year != null) {
      query.where(
        _db.transactions.date.isBetweenValues(
          DateTime(year, month, 1),
          DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1)),
        ),
      );
    }

    query.orderBy([
      OrderingTerm.desc(_db.transactions.date),
    ]);

    return query.watch().map((rows) => rows
        .map((row) => TransactionWithDetails(
              transaction: row.readTable(_db.transactions),
              category: row.readTable(_db.categories),
              wallet: row.readTable(_db.wallets),
            ))
        .toList());
  }

  Future<List<TransactionWithDetails>> getTransactions(
    String userId, {
    int? month,
    int? year,
    String? walletId,
    String? categoryId,
    TransactionType? type,
  }) {
    final query = _db.select(_db.transactions).join([
      innerJoin(
          _db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
      innerJoin(
          _db.wallets, _db.wallets.id.equalsExp(_db.transactions.walletId)),
    ])
      ..where(_db.transactions.userId.equals(userId));

    if (month != null && year != null) {
      query.where(
        _db.transactions.date.isBetweenValues(
          DateTime(year, month, 1),
          DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1)),
        ),
      );
    }
    if (walletId != null) {
      query.where(_db.transactions.walletId.equals(walletId));
    }
    if (type != null) {
      query.where(_db.transactions.type
          .equals(TransactionType.values.indexOf(type)));
    }
    query.orderBy([OrderingTerm.desc(_db.transactions.date)]);

    return query.get().then((rows) => rows
        .map((row) => TransactionWithDetails(
              transaction: row.readTable(_db.transactions),
              category: row.readTable(_db.categories),
              wallet: row.readTable(_db.wallets),
            ))
        .toList());
  }

  Future<Transaction> createTransaction({
    required String userId,
    required String walletId,
    required String categoryId,
    required double amount,
    required TransactionType type,
    String? note,
    DateTime? date,
  }) async {
    final id = _uuid.v4();
    final txDate = date ?? DateTime.now();

    await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: id,
            userId: userId,
            walletId: walletId,
            categoryId: categoryId,
            amount: amount,
            type: type,
            note: Value(note),
            date: Value(txDate),
          ),
        );

    // Update wallet balance
    final delta =
        type == TransactionType.income ? amount : -amount;
    await _walletRepo.adjustBalance(walletId, delta);

    return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<bool> deleteTransaction(String transactionId) async {
    final tx = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingleOrNull();
    if (tx == null) return false;

    // Reverse wallet balance
    final delta =
        tx.type == TransactionType.income ? -tx.amount : tx.amount;
    await _walletRepo.adjustBalance(tx.walletId, delta);

    final count = await (_db.delete(_db.transactions)
          ..where((t) => t.id.equals(transactionId)))
        .go();
    return count > 0;
  }

  Future<bool> updateTransaction({
    required String id,
    String? categoryId,
    String? walletId,
    double? amount,
    TransactionType? type,
    String? note,
    DateTime? date,
  }) async {
    final companion = TransactionsCompanion(
      categoryId:
          categoryId != null ? Value(categoryId) : const Value.absent(),
      walletId: walletId != null ? Value(walletId) : const Value.absent(),
      amount: amount != null ? Value(amount) : const Value.absent(),
      type: type != null ? Value(type) : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
      date: date != null ? Value(date) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    final count = await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .write(companion);
    return count > 0;
  }

  // Get monthly summary
  Stream<MonthlySummary> watchMonthlySummary(
      String userId, int month, int year) {
    return watchTransactions(userId, month: month, year: year).map((txList) {
      double income = 0;
      double expense = 0;
      for (final tx in txList) {
        if (tx.transaction.type == TransactionType.income) {
          income += tx.transaction.amount;
        } else {
          expense += tx.transaction.amount;
        }
      }
      return MonthlySummary(totalIncome: income, totalExpense: expense);
    });
  }

  // Get summary per category for charts
  Future<Map<String, double>> getCategorySummary(
      String userId, int month, int year, TransactionType type) async {
    final txList = await getTransactions(userId,
        month: month, year: year, type: type);
    final Map<String, double> summary = {};
    for (final tx in txList) {
      final catName = tx.category.name;
      summary[catName] = (summary[catName] ?? 0) + tx.transaction.amount;
    }
    return summary;
  }
}
