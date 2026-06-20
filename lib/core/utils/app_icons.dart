import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppIcons {
  static const Map<String, IconData> _lucideMap = {
    'food': LucideIcons.coffee,
    'transport': LucideIcons.car,
    'shopping': LucideIcons.shoppingCart,
    'health': LucideIcons.pill,
    'entertainment': LucideIcons.gamepad2,
    'bills': LucideIcons.receipt,
    'education': LucideIcons.bookOpen,
    'salary': LucideIcons.briefcase,
    'freelance': LucideIcons.laptop,
    'investment': LucideIcons.trendingUp,
    'gift': LucideIcons.gift,
    'other': LucideIcons.wallet,
    'home': LucideIcons.home,
    'plane': LucideIcons.plane,
    'smartphone': LucideIcons.smartphone,
    'music': LucideIcons.music,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,
    'zap': LucideIcons.zap,
    'camera': LucideIcons.camera,
    'headphones': LucideIcons.headphones,
    'monitor': LucideIcons.monitor,
    'smile': LucideIcons.smile,
    'sun': LucideIcons.sun,
    'tv': LucideIcons.tv,
    'wifi': LucideIcons.wifi,
  };

  static IconData getIcon(String? name) {
    if (name == null || name.isEmpty) return LucideIcons.circleDollarSign;
    return _lucideMap[name] ?? LucideIcons.circleDollarSign;
  }

  static List<String> get availableIcons => _lucideMap.keys.toList();
}
