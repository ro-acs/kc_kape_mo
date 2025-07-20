import 'package:flutter/material.dart';

class CoffeeItem {
  final String id;
  final String name;
  final double price;
  final IconData icon;

  const CoffeeItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });

  factory CoffeeItem.fromMap(String id, Map<String, dynamic> data) {
    return CoffeeItem(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      icon: Icons.coffee, // you can make this dynamic later
    );
  }
}
