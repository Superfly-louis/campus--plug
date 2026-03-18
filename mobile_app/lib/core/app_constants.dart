import 'package:flutter/material.dart';

class AppConstants {
  // Brand Colors
  static const Color primaryColor = Color(0xFFFF8200); // Figma Orange
  static const Color secondaryColor = Color(0xFF000000);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);

  // Collection Names
  static const String usersCollection = 'users';
  static const String vendorsCollection = 'vendors';
  static const String productsCollection = 'products';
  static const String reviewsCollection = 'reviews';
  static const String ordersCollection = 'orders';

  // Categories (From Figma Design)
  static const List<String> categories = [
    'Food',
    'Fashion',
    'Beauty',
    'Electronics',
    'Services',
    'Books',
    'Other'
  ];

  // Default Campus (During development)
  static const String defaultCampusId = 'unilag_001';
  static const String defaultCampusName = 'University of Lagos';
}
