import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class WalletRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  WalletRepository(this._db);

  // Stream all wallets for a user
  Stream<List<Wallet>> watchWallets(String userId) {
    return (_db.select(_db.wallets)
          ..where((w) => w.userId.equals(userId))
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .watch();
  }

  Future<List<Wallet>> getWallets(String userId) {
    return (_db.select(_db.wallets)
          ..where((w) => w.userId.equals(userId))
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .get();
  }

  Future<Wallet?> getWalletById(String id) {
    return (_db.select(_db.wallets)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Wallet> createWallet({
    required String userId,
    required String name,
    double initialBalance = 0.0,
    String icon = 'account_balance_wallet',
    String color = '#6C63FF',
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.wallets).insert(
          WalletsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            balance: Value(initialBalance),
            icon: Value(icon),
            color: Value(color),
          ),
        );
    return (_db.select(_db.wallets)..where((w) => w.id.equals(id))).getSingle();
  }

  Future<bool> updateWallet({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final companion = WalletsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    final count =
        await (_db.update(_db.wallets)..where((w) => w.id.equals(id)))
            .write(companion);
    return count > 0;
  }

  Future<bool> updateBalance(String walletId, double newBalance) async {
    final count = await (_db.update(_db.wallets)
          ..where((w) => w.id.equals(walletId)))
        .write(WalletsCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  Future<bool> adjustBalance(String walletId, double delta) async {
    final wallet = await getWalletById(walletId);
    if (wallet == null) return false;
    return updateBalance(walletId, wallet.balance + delta);
  }

  Future<int> deleteWallet(String id) {
    return (_db.delete(_db.wallets)..where((w) => w.id.equals(id))).go();
  }

  // Get total balance across all wallets for a user
  Future<double> getTotalBalance(String userId) async {
    final wallets = await getWallets(userId);
    return wallets.fold<double>(0.0, (sum, w) => sum + w.balance);
  }

  Stream<double> watchTotalBalance(String userId) {
    return watchWallets(userId)
        .map((wallets) => wallets.fold<double>(0.0, (sum, w) => sum + w.balance));
  }
}
