import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(date);
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,##0', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text;
    int selectionEnd = newValue.selection.end;

    if (oldValue.text.length - newValue.text.length == 1) {
      final int deletedIdx = newValue.selection.end;
      if (deletedIdx >= 0 && deletedIdx < oldValue.text.length && oldValue.text[deletedIdx] == '.') {
        if (deletedIdx > 0) {
          final String prefix = oldValue.text.substring(0, deletedIdx - 1);
          final String suffix = oldValue.text.substring(deletedIdx + 1);
          newText = prefix + suffix;
          selectionEnd = deletedIdx - 1;
        }
      }
    }

    final String cleanText = newText.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final double? value = double.tryParse(cleanText);
    if (value == null) {
      return oldValue;
    }

    final String formattedText = _formatter.format(value);

    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionEnd; i++) {
      if (i < newText.length && RegExp(r'\d').hasMatch(newText[i])) {
        digitsBeforeCursor++;
      }
    }

    int newSelectionEnd = 0;
    int digitsSeen = 0;
    while (digitsSeen < digitsBeforeCursor && newSelectionEnd < formattedText.length) {
      if (RegExp(r'\d').hasMatch(formattedText[newSelectionEnd])) {
        digitsSeen++;
      }
      newSelectionEnd++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newSelectionEnd),
    );
  }
}

