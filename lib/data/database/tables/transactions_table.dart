// Database table for Transactions
import 'package:drift/drift.dart';
import 'users_table.dart';
import 'wallets_table.dart';
import 'categories_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get walletId => text().references(Wallets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  RealColumn get amount => real()();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
