import 'package:flutter/material.dart';

class AppConstants {
  // Brand Colors
  static const Color primaryColor = Color(0xFFFF8200);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String vendorsCollection = 'vendors';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';

  // Central University Ghana Campuses
  static const List<Map<String, String>> campuses = [
    {'id': 'cu_miotso', 'name': 'Miotso Campus'},
    {'id': 'cu_accra', 'name': 'Accra Campus'},
    {'id': 'cu_tema', 'name': 'Tema Campus'},
  ];

  static const String defaultCampusId = 'cu_miotso';
  static const String defaultCampusName = 'Central University - Miotso';

  // Product Categories
  static const List<Map<String, dynamic>> categories = [
    {'id': 'food', 'name': 'Food', 'icon': '🍔'},
    {'id': 'fashion', 'name': 'Fashion', 'icon': '👗'},
    {'id': 'beauty', 'name': 'Beauty', 'icon': '💄'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': '💻'},
    {'id': 'services', 'name': 'Services', 'icon': '🛠️'},
    {'id': 'books', 'name': 'Books', 'icon': '📚'},
    {'id': 'other', 'name': 'Other', 'icon': '📦'},
  ];
}