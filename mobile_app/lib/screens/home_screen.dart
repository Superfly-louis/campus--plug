import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../core/app_constants.dart';
import '../models/vendor_model.dart';
import 'login_screen.dart';
import 'messages_screen.dart';
import 'product_detail_screen.dart';
import 'vendor_shop_screen.dart';
import 'explore_screen.dart';
import 'vendor_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/auth_errors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _searchQuery = '';
  /// Category id from [AppConstants.categories], or `'all'`.
  String _selectedCategoryId = 'all';
  /// Price band id from [AppConstants.productPriceBands].
  String _selectedPriceBandId = 'all';

  late int _currentIndex;
  bool _messagesTabVisited = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    if (_currentIndex == 3) _messagesTabVisited = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Rebuild immediately so the clear icon appears; debounce the filter query.
    setState(() {});
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    });
  }

  Map<String, dynamic> get _selectedPriceBand {
    return AppConstants.productPriceBands.firstWhere(
      (b) => b['id'] == _selectedPriceBandId,
      orElse: () => AppConstants.productPriceBands.first,
    );
  }

  List<ProductModel> _filterProducts(
    FirestoreService firestoreService,
    List<ProductModel> products,
  ) {
    final band = _selectedPriceBand;
    return firestoreService.applyProductFilters(
      products,
      // Category already applied in the stream when not "all".
      categoryId: null,
      searchQuery: _searchQuery,
      minPrice: band['min'] as double?,
      maxPrice: band['max'] as double?,
    );
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategoryId != 'all' ||
      _selectedPriceBandId != 'all';

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
          const ExploreScreen(),
          profile?.isVendor == true && vendorId != null && vendorId.isNotEmpty
              ? VendorShopScreen(vendorId: vendorId)
              : _buildPlaceholderTab('Shop', Icons.storefront),
          _messagesTabVisited
              ? const MessagesScreen()
              : const SizedBox.shrink(),
          _buildPlaceholderTab('Profile', Icons.person_outline),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          if (index == 3) _messagesTabVisited = true;
        }),
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
                        if (value != 'logout') return;
                        try {
                          await authService.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyAuthError(e))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar (Explore-style: live debounce + clear)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for anything...',
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppConstants.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
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

              const SizedBox(height: 12),

              // Price bands (chip style, same as categories)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: _buildPriceChips(),
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionTitle('Trending on Campus'),
              _buildHorizontalProducts(firestoreService),

              const SizedBox(height: 32),

              _buildSectionTitle('Top Student Vendors'),
              _buildHorizontalVendors(firestoreService),

              const SizedBox(height: 32),

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

  Stream<List<ProductModel>> _productStream(FirestoreService firestoreService) {
    return firestoreService.watchCampusProducts(
      campusId: AppConstants.defaultCampusId,
      categoryId: _selectedCategoryId,
    );
  }

  Widget _buildHorizontalProducts(FirestoreService firestoreService) {
    return SizedBox(
      height: 240,
      child: StreamBuilder<List<ProductModel>>(
        stream: _productStream(firestoreService),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = _filterProducts(firestoreService, snapshot.data!);
          if (products.isEmpty) {
            return _buildEmptyState(isHorizontal: true);
          }

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
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(product: products[index]),
                      ),
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
    return SizedBox(
      height: 100,
      child: StreamBuilder<List<VendorModel>>(
        stream: firestoreService.getAllVendors(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vendors = snapshot.data!;
          if (vendors.isEmpty) {
            return const Center(
              child: Text('No vendors yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: vendors.length > 5 ? 5 : vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorProfileScreen(vendorId: vendor.id),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppConstants.surfaceColor,
                        backgroundImage: vendor.logoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(vendor.logoUrl)
                            : null,
                        child: vendor.logoUrl.isEmpty
                            ? Text(vendor.businessName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          vendor.businessName,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(FirestoreService firestoreService) {
    return StreamBuilder<List<ProductModel>>(
      stream: _productStream(firestoreService),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final products = _filterProducts(firestoreService, snapshot.data!);
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _buildEmptyState(isHorizontal: false),
          );
        }

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
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(product: products[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCategoryChips() {
    return [
      _buildFilterChip(
        label: 'All',
        selected: _selectedCategoryId == 'all',
        onSelected: () => setState(() => _selectedCategoryId = 'all'),
      ),
      ...AppConstants.categories.map((category) {
        final String categoryId = category['id'] as String;
        final String categoryName = category['name'] as String;
        final String categoryIcon = category['icon'] as String;
        final selected = _selectedCategoryId == categoryId;
        return _buildFilterChip(
          label: '$categoryIcon $categoryName',
          selected: selected,
          onSelected: () => setState(() => _selectedCategoryId = categoryId),
        );
      }),
    ];
  }

  List<Widget> _buildPriceChips() {
    return AppConstants.productPriceBands.map((band) {
      final id = band['id'] as String;
      final label = band['label'] as String;
      final selected = _selectedPriceBandId == id;
      return _buildFilterChip(
        label: label,
        selected: selected,
        onSelected: () => setState(() => _selectedPriceBandId = id),
      );
    }).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildEmptyState({required bool isHorizontal}) {
    void clearFilters() {
      _searchController.clear();
      setState(() {
        _searchQuery = '';
        _selectedCategoryId = 'all';
        _selectedPriceBandId = 'all';
      });
    }

    if (_hasActiveFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: isHorizontal ? 40 : 56,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No products match "$_searchQuery"'
                    : 'No products match these filters',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try another category, price range, or clear filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConstants.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: clearFilters,
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'No products yet. Be the first to sell!',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
