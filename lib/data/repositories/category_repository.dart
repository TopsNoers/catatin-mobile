import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CategoryRepository(this._db);

  Stream<List<Category>> watchCategories(String userId) {
    return (_db.select(_db.categories)
          ..where((c) => c.userId.equals(userId))
          ..orderBy([
            (c) => OrderingTerm.asc(c.type),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  Stream<List<Category>> watchCategoriesByType(
      String userId, TransactionType type) {
    return (_db.select(_db.categories)
          ..where((c) =>
              c.userId.equals(userId) &
              c.type.equals(TransactionType.values.indexOf(type)))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<List<Category>> getCategoriesByType(
      String userId, TransactionType type) {
    return (_db.select(_db.categories)
          ..where((c) =>
              c.userId.equals(userId) &
              c.type.equals(TransactionType.values.indexOf(type))))
        .get();
  }

  Future<Category?> getCategoryById(String id) {
    return (_db.select(_db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Category> createCategory({
    required String userId,
    required String name,
    required TransactionType type,
    String? icon,
    String? color,
    bool isDefault = false,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            icon: Value(icon),
            color: Value(color),
            isDefault: Value(isDefault),
          ),
        );
    return (_db.select(_db.categories)..where((c) => c.id.equals(id)))
        .getSingle();
  }

  Future<bool> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final companion = CategoriesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    final count =
        await (_db.update(_db.categories)..where((c) => c.id.equals(id)))
            .write(companion);
    return count > 0;
  }

  Future<int> deleteCategory(String id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  /// Seeds default categories for a new user
  Future<void> seedDefaultCategories(String userId) async {
    final expenseCategories = [
      ('Lainnya', 'other', '#B0B0B0'),
    ];

    final incomeCategories = [
      ('Lainnya', 'other', '#B0B0B0'),
    ];

    for (final cat in expenseCategories) {
      await createCategory(
        userId: userId,
        name: cat.$1,
        type: TransactionType.expense,
        icon: cat.$2,
        color: cat.$3,
        isDefault: true,
      );
    }

    for (final cat in incomeCategories) {
      await createCategory(
        userId: userId,
        name: cat.$1,
        type: TransactionType.income,
        icon: cat.$2,
        color: cat.$3,
        isDefault: true,
      );
    }
  }
}
