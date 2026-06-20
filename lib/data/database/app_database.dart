import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/wallets_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';

export 'tables/users_table.dart' show TransactionType;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    UserDetails,
    Wallets,
    Categories,
    Transactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Singleton
  static AppDatabase? _instance;
  static AppDatabase getInstance() {
    _instance ??= AppDatabase();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'catatin.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
