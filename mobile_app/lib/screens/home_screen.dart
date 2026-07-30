import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/glass_filter_chip.dart';
import '../widgets/liquid_glass_bottom_nav.dart';
import '../core/app_constants.dart';
import '../models/vendor_model.dart';
import 'messages_screen.dart';
import 'product_detail_screen.dart';
import 'vendor_shop_screen.dart';
import 'explore_screen.dart';
import 'vendor_profile_screen.dart';
import 'profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      extendBody: true,
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
          ProfileScreen(
            onOpenShopTab: () => setState(() => _currentIndex = 2),
          ),
        ],
      ),
      bottomNavigationBar: userId == null
          ? LiquidGlassBottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              items: _navItems(),
            )
          : StreamBuilder<int>(
              stream: chatService.watchTotalUnreadCount(userId),
              builder: (context, snapshot) {
                return LiquidGlassBottomNav(
                  currentIndex: _currentIndex,
                  onTap: _onNavTap,
                  items: _navItems(messagesBadge: snapshot.data ?? 0),
                );
              },
            ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 3) _messagesTabVisited = true;
    });
  }

  List<LiquidGlassNavItem> _navItems({int messagesBadge = 0}) {
    return [
      const LiquidGlassNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      const LiquidGlassNavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Explore',
      ),
      const LiquidGlassNavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Shop',
      ),
      LiquidGlassNavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        badgeCount: messagesBadge,
      ),
      const LiquidGlassNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
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
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Text(
                          'Marketplace for students',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
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
                      ],
                      onSelected: (value) {
                        if (value == 'profile') {
                          setState(() => _currentIndex = 4);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar — single field with icon + thin orange border
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for anything...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppConstants.primaryColor,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryColor,
                        width: 1.5,
                      ),
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

              _buildSectionTitle(
                'Trending on Campus',
                onSeeAll: () => _openAllProducts(firestoreService),
              ),
              _buildHorizontalProducts(firestoreService),

              const SizedBox(height: 32),

              _buildSectionTitle(
                'Top Student Vendors',
                onSeeAll: () => setState(() => _currentIndex = 1),
              ),
              _buildHorizontalVendors(firestoreService),

              const SizedBox(height: 32),

              _buildSectionTitle(
                'Newly Added',
                onSeeAll: () => _openAllProducts(firestoreService),
              ),
              _buildProductGrid(firestoreService),
          ],
        ),
      ),
    );
  }

  void _openAllProducts(FirestoreService firestoreService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllAvailableProductsScreen(
          categoryId: _selectedCategoryId,
          searchQuery: _searchQuery,
          minPrice: _selectedPriceBand['min'] as double?,
          maxPrice: _selectedPriceBand['max'] as double?,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
    return GlassFilterChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
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

/// Full list of available (buyer-visible) campus products.
class _AllAvailableProductsScreen extends StatelessWidget {
  const _AllAvailableProductsScreen({
    required this.categoryId,
    required this.searchQuery,
    this.minPrice,
    this.maxPrice,
  });

  final String categoryId;
  final String searchQuery;
  final double? minPrice;
  final double? maxPrice;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'All products',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: firestoreService.watchCampusProducts(
          campusId: AppConstants.defaultCampusId,
          categoryId: categoryId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = firestoreService
              .applyProductFilters(
                snapshot.data!,
                categoryId: null,
                searchQuery: searchQuery,
                minPrice: minPrice,
                maxPrice: maxPrice,
              )
              .where((p) => p.status == ProductStatus.available)
              .toList();

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No available products right now.',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
