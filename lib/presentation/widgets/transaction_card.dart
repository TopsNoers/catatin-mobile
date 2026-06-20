import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';

class TransactionCard extends StatelessWidget {
  final TransactionWithDetails data;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.data,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tx = data.transaction;
    final category = data.category;
    final wallet = data.wallet;
    final isIncome = tx.type == TransactionType.income;

    final categoryColor = category.color != null
        ? Color(int.parse(category.color!.replaceFirst('#', 'FF'), radix: 16))
        : AppColors.primary;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        if (onDelete != null) {
          onDelete!();
          return false; // Let caller handle dismissal
        }
        return true;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              // Category icon bubble
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.getIcon(category.icon),
                    size: 24,
                    color: categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          wallet.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (tx.note != null && tx.note!.isNotEmpty) ...[
                          Text(
                            ' • ${tx.note}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCompact(tx.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isIncome ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormatter.formatRelative(tx.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
