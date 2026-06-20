import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

// ─── Current User ────────────────────────────────────────────────────────────

// Holds the current logged-in user (null = not set up yet)
final currentUserProvider = StateProvider<User?>((ref) => null);

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

// App initialization state
final appInitProvider = FutureProvider<User?>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final existingUser = await userRepo.getFirstUser();
  if (existingUser != null) {
    ref.read(currentUserProvider.notifier).state = existingUser;
  }
  return existingUser;
});
