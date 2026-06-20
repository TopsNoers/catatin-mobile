import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/providers/wallet_provider.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/user_provider.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddWalletDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total balance banner
          totalBalanceAsync.when(
            data: (total) => _TotalBalanceBanner(total: total),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Wallets list
          Expanded(
            child: walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return _EmptyWallets(
                    onAdd: () => _showAddWalletDialog(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final wallet = wallets[i];
                    final color = Color(int.parse(
                        wallet.color.replaceFirst('#', 'FF'),
                        radix: 16));
                    return _WalletCard(
                      name: wallet.name,
                      balance: wallet.balance,
                      color: color,
                      onEdit: () =>
                          _showEditWalletDialog(context, ref, wallet.id, wallet.name),
                      onDelete: () async {
                        await ref
                            .read(walletRepositoryProvider)
                            .deleteWallet(wallet.id);
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _WalletDialog(
        onSubmit: (name, color) async {
          final userId = ref.read(currentUserIdProvider)!;
          await ref.read(walletRepositoryProvider).createWallet(
                userId: userId,
                name: name,
                color: color,
              );
        },
      ),
    );
  }

  void _showEditWalletDialog(
      BuildContext context, WidgetRef ref, String id, String currentName) {
    showDialog(
      context: context,
      builder: (ctx) => _WalletDialog(
        initialName: currentName,
        onSubmit: (name, color) async {
          await ref
              .read(walletRepositoryProvider)
              .updateWallet(id: id, name: name, color: color);
        },
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _TotalBalanceBanner extends StatelessWidget {
  final double total;

  const _TotalBalanceBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Semua Dompet',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final String name;
  final double balance;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WalletCard({
    required this.name,
    required this.balance,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(balance),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).textTheme.bodySmall?.color),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.expense),
                    const SizedBox(width: 8),
                    Text('Hapus',
                        style: TextStyle(color: AppColors.expense)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyWallets({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👛', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Belum Ada Dompet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tambahkan dompet untuk mulai mencatat',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Dompet'),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet Dialog ───────────────────────────────────────────────────────────

class _WalletDialog extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(String name, String color) onSubmit;

  const _WalletDialog({this.initialName, required this.onSubmit});

  @override
  State<_WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<_WalletDialog> {
  late final TextEditingController _nameController;
  String _selectedColor = '#6C63FF';
  bool _isLoading = false;

  final _colors = [
    '#6C63FF', '#FF6B6B', '#2DD4BF', '#FFEAA7',
    '#74B9FF', '#A29BFE', '#FD79A8', '#55EFC4',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.initialName != null ? 'Edit Dompet' : 'Dompet Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Dompet',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Warna', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((c) {
              final color =
                  Color(int.parse(c.replaceFirst('#', 'FF'), radix: 16));
              final isSelected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty) return;
                  setState(() => _isLoading = true);
                  await widget.onSubmit(
                      _nameController.text.trim(), _selectedColor);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
