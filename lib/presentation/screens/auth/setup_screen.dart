import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/providers/database_provider.dart';
import '../../../domain/providers/user_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _step = 0; // 0 = welcome, 1 = name, 2 = first wallet

  final _walletController = TextEditingController(text: 'Dompet Utama');
  String _walletColor = '#6C63FF';

  @override
  void dispose() {
    _nameController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);

      // Create or update user
      var user = await userRepo.getUserByEmail('local@catatin.app');
      final name = _nameController.text.trim().isEmpty ? 'Pengguna' : _nameController.text.trim();
      
      if (user == null) {
        user = await userRepo.createUser(
          email: 'local@catatin.app',
          name: name,
          password: '1234',
        );
      } else {
        await userRepo.updateUser(id: user.id, name: name);
        // Refresh to get updated object if needed, but for ID it's fine
      }

      // Create first wallet if none exist
      final existingWallets = await walletRepo.getWallets(user.id);
      if (existingWallets.isEmpty) {
        await walletRepo.createWallet(
          userId: user.id,
          name: _walletController.text.trim().isEmpty
              ? 'Dompet Utama'
              : _walletController.text.trim(),
          color: _walletColor,
        );
      }

      // Seed categories if none exist
      final existingCategories = await categoryRepo.getCategoriesByType(user.id, TransactionType.expense);
      if (existingCategories.isEmpty) {
        await categoryRepo.seedDefaultCategories(user.id);
      }

      // Set current user
      ref.read(currentUserProvider.notifier).state = user;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _step == 0
              ? _WelcomeStep(onNext: () => setState(() => _step = 1))
              : _SetupForm(
                  nameController: _nameController,
                  walletController: _walletController,
                  walletColor: _walletColor,
                  formKey: _formKey,
                  isLoading: _isLoading,
                  onColorSelected: (c) => setState(() => _walletColor = c),
                  onFinish: _finish,
                ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.wallet, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Catatin',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Catat pemasukan & pengeluaran\nmu dengan mudah dan rapi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Mulai Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController walletController;
  final String walletColor;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final void Function(String) onColorSelected;
  final VoidCallback onFinish;

  const _SetupForm({
    required this.nameController,
    required this.walletController,
    required this.walletColor,
    required this.formKey,
    required this.isLoading,
    required this.onColorSelected,
    required this.onFinish,
  });

  static const _colors = [
    '#6C63FF', '#FF6B6B', '#2DD4BF', '#FFEAA7',
    '#74B9FF', '#A29BFE', '#FD79A8', '#55EFC4',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Setup Profil', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Konfigurasi awal untuk Catatin kamu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama kamu (opsional)',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: walletController,
              decoration: const InputDecoration(
                labelText: 'Nama Dompet Pertama',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            Text('Warna Dompet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((c) {
                final color =
                    Color(int.parse(c.replaceFirst('#', 'FF'), radix: 16));
                final isSelected = walletColor == c;
                return GestureDetector(
                  onTap: () => onColorSelected(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.6), blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onFinish,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Selesai & Mulai'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
