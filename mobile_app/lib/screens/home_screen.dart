import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../core/app_constants.dart';
import 'messages_screen.dart';
import 'product_detail_screen.dart';
import 'vendor_shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Food';
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final chatService = Provider.of<ChatService>(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final profile = authService.currentUserProfile;
    final vendorId = profile?.vendorId;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(authService, firestoreService),
          _buildPlaceholderTab('Explore', Icons.explore_outlined),
          profile?.isVendor == true && vendorId != null && vendorId.isNotEmpty
              ? VendorShopScreen(vendorId: vendorId)
              : _buildPlaceholderTab('Shop', Icons.storefront),
          const MessagesScreen(),
          _buildPlaceholderTab('Profile', Icons.person_outline),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: userId == null
                ? const Icon(Icons.chat_bubble_outline)
                : StreamBuilder<int>(
                    stream: chatService.watchTotalUnreadCount(userId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Badge(
                        isLabelVisible: count > 0,
                        backgroundColor: AppConstants.primaryColor,
                        label: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        child: const Icon(Icons.chat_bubble_outline),
                      );
                    },
                  ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppConstants.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            '$title — coming soon',
            style: const TextStyle(color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(AuthService authService, FirestoreService firestoreService) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Plug',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Text(
                          'Marketplace for students',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    PopupMenuButton(
                      icon: const CircleAvatar(
                        backgroundColor: AppConstants.surfaceColor,
                        child: Icon(Icons.person_outline, color: Colors.black),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Text('Profile'),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Logout'),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await authService.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for anything...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Categories
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: _buildCategoryChips(),
                ),
              ),

              const SizedBox(height: 32),

              // Trending on Campus Section
              _buildSectionTitle('Trending on Campus'),
              _buildHorizontalProducts(firestoreService),

              const SizedBox(height: 32),

              // Top Student Vendors Section
              _buildSectionTitle('Top Student Vendors'),
              _buildHorizontalVendors(firestoreService),

              const SizedBox(height: 32),

              // Newly Added Section
              _buildSectionTitle('Newly Added'),
              _buildProductGrid(firestoreService),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'See All',
            style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProducts(FirestoreService firestoreService) {
    return SizedBox(
      height: 240,
      child: StreamBuilder<List<ProductModel>>(
        stream: firestoreService.getProductsByCampus(AppConstants.defaultCampusId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) return _buildEmptyState();
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SizedBox(
                  width: 170,
                  child: ProductCard(
                    product: products[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: products[index])),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalVendors(FirestoreService firestoreService) {
    // Placeholder for vendors as we don't have a listVendors stream yet
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstants.surfaceColor,
                  backgroundImage: NetworkImage('https://via.placeholder.com/150/FF8200/FFFFFF?text=Vendor+${index + 1}'),
                ),
                const SizedBox(height: 8),
                Text('Vendor ${index + 1}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(FirestoreService firestoreService) {
    return StreamBuilder<List<ProductModel>>(
      stream: firestoreService.getProductsByCampus(AppConstants.defaultCampusId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final products = snapshot.data!;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetailScreen(product: products[index])),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCategoryChips() {
    return AppConstants.categories.map((category) {
      final String categoryName = category['name'] as String;
      final String categoryIcon = category['icon'] as String;
      bool isSelected = _selectedCategory == categoryName;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$categoryIcon $categoryName'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = categoryName);
            }
          },
          selectedColor: AppConstants.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No products yet. Be the first to sell!', style: TextStyle(color: Colors.grey)),
    );
  }
}
