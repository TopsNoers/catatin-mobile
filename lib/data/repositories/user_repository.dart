import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class UserRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  UserRepository(this._db);

  // Create a new user (first-run setup)
  Future<User> createUser({
    required String email,
    required String name,
    required String password,
  }) async {
    final id = _uuid.v4();
    final companion = UsersCompanion.insert(
      id: id,
      email: email,
      name: Value(name),
      password: password,
    );
    await _db.into(_db.users).insert(companion);

    // Create default user details
    final detailId = _uuid.v4();
    await _db.into(_db.userDetails).insert(
          UserDetailsCompanion.insert(
            id: detailId,
            userId: id,
          ),
        );

    return (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingle();
  }


  Future<User?> getUserById(String id) {
    return (_db.select(_db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  Future<User?> getFirstUser() {
    return (_db.select(_db.users)..limit(1)).getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) {
    return (_db.select(_db.users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  Future<bool> updateUser({
    required String id,
    String? name,
    String? email,
    String? password,
  }) async {
    final companion = UsersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
      password: password != null ? Value(password) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    final count = await (_db.update(_db.users)..where((u) => u.id.equals(id)))
        .write(companion);
    return count > 0;
  }

  Future<UserDetail?> getUserDetail(String userId) {
    return (_db.select(_db.userDetails)
          ..where((d) => d.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<bool> updateUserDetail({
    required String userId,
    String? theme,
    String? backgroundApp,
  }) async {
    final companion = UserDetailsCompanion(
      theme: theme != null ? Value(theme) : const Value.absent(),
      backgroundApp:
          backgroundApp != null ? Value(backgroundApp) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    final count = await (_db.update(_db.userDetails)
          ..where((d) => d.userId.equals(userId)))
        .write(companion);
    return count > 0;
  }
}
