// Database table for Wallets
import 'package:drift/drift.dart';
import 'users_table.dart';

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('account_balance_wallet'))();
  TextColumn get color => text().withDefault(const Constant('#6C63FF'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
