import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';
import 'user_provider.dart';

// ─── Active User's Wallets ──────────────────────────────────────────────────

final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(walletRepositoryProvider).watchWallets(userId);
});

final totalBalanceProvider = StreamProvider<double>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0.0);
  return ref.watch(walletRepositoryProvider).watchTotalBalance(userId);
});

final selectedWalletIdProvider = StateProvider<String?>((ref) => null);
