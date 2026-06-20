import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'core/theme/app_theme.dart';
import 'domain/providers/user_provider.dart';
import 'presentation/screens/auth/setup_screen.dart';
import 'presentation/screens/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: CatatinApp(),
    ),
  );
}

class CatatinApp extends ConsumerWidget {
  const CatatinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Catatin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default dark mode, can be changed from settings
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitProvider);
    final currentUser = ref.watch(currentUserProvider);

    return initAsync.when(
      data: (_) {
        if (currentUser == null) {
          return const SetupScreen();
        }
        return const MainShell();
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wallet, color: AppColors.primary, size: 64),
              SizedBox(height: 16),
              Text(
                'Catatin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
