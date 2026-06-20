content = """# 🤖 AI Agent Brief: Flutter Personal Finance App (Drift ORM)

**Role:** You are an expert Flutter Developer and Software Architect specializing in offline-first mobile applications. 

**Task:** Build a mobile Personal Finance Application (Aplikasi Pencatatan Keuangan Pribadi) using **Flutter** and **Drift (formerly Moor)** for local SQLite storage. Translate the provided conceptual schema into fully typed Drift Table classes and generate the database layer.

### 🛠 Tech Stack
* **Frontend:** Flutter (Dart)
* **Local Database:** `drift`, `sqlite3_flutter_libs`
* **Code Generation:** `build_runner`, `drift_dev`
* **State Management:** (Choose your preferred/standard approach, e.g., Provider, Riverpod, or Bloc)
* **Dependencies to include:** `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `uuid` (for PKs), `intl` (for currency/date formatting). 
* **Dev Dependencies:** `drift_dev`, `build_runner`

### 🗄️ Database Schema (Drift Implementation)
Please implement the following schema using **Drift**. 
* **Primary Keys:** Use `TextColumn` and generate UUIDs via the `uuid` package before inserting. Set the `id` as the `primaryKey`.
* **Relations:** Use Drift's `.references()` for Foreign Keys.
* **Enums:** Use Drift's `intEnum<T>()` feature to store the `TransactionType` enum natively.
* **Timestamps:** Use `dateTime().withDefault(currentDateAndTime)()` for creation dates.

**Reference Schema (Draft):**

Created file: ai_agent_brief_flutter_drift.md

```dart
import 'package:drift/drift.dart';

enum TransactionType { income, expense }

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get password => text()(); // For local PIN/Password
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserDetails extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  TextColumn get backgroundApp => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text()();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

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