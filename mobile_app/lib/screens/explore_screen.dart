import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/vendor_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_filter_chip.dart';
import 'vendor_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Top Rated'; // 'Top Rated', 'Newest', 'Most Orders'

  List<VendorModel>? _cachedVendors;
  DateTime? _lastFetchTime;
  bool _isLoading = true;
  String? _fetchError;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchVendors();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && !_isLoading) {
        _fetchVendors(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshCache();
    }
  }

  Future<void> _checkAndRefreshCache() async {
    if (_lastFetchTime == null) return;
    final now = DateTime.now();
    final diff = now.difference(_lastFetchTime!).inMinutes;
    if (diff >= 5) {
      await _fetchVendors(showLoading: false);
    }
  }

  Future<void> _fetchVendors({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _fetchError = null;
      });
    }

    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final vendors = await firestoreService.fetchVendorsByCampusFuture(
        AppConstants.defaultCampusId,
      );

      if (mounted) {
        if (showLoading) {
          // Guarantee min 1.5 seconds skeleton to avoid flash
          await Future.delayed(const Duration(milliseconds: 1500));
        }
        if (mounted) {
          setState(() {
            _cachedVendors = vendors;
            _lastFetchTime = DateTime.now();
            _isLoading = false;
            _fetchError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fetchError = e.toString();
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    });
  }

  Color _getAvatarColor(String name) {
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      const Color(0xFFF2A65A),
      const Color(0xFFE56B6F),
      const Color(0xFF355C7D),
      const Color(0xFF6C5B7B),
      const Color(0xFF99B898),
      const Color(0xFF83A4C9),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Discover Vendors',
          style: GoogleFonts.syne(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search vendors, food, services...',
                  hintStyle: GoogleFonts.syne(
                    color: AppConstants.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppConstants.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppConstants.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return _buildSkeletonLoader();
                }

                if (_cachedVendors == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load vendors. Please try again.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(color: Colors.red),
                          ),
                          if (_fetchError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _fetchError!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.syne(
                                color: AppConstants.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchVendors,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              'Retry',
                              style: GoogleFonts.syne(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allVendors = _cachedVendors!;

                // Compute counts per category from actual fetched data
                final Map<String, int> categoryCounts = {
                  'All': allVendors.length,
                };
                for (final vendor in allVendors) {
                  final cat = vendor.category ?? 'other';
                  categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
                }

                // Apply category filtering
                var filtered = allVendors;
                if (_selectedCategory != 'All') {
                  filtered = allVendors
                      .where(
                        (v) =>
                            (v.category ?? 'other').toLowerCase() ==
                            _selectedCategory.toLowerCase(),
                      )
                      .toList();
                }

                // Apply search filtering (AND logic)
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((v) {
                    final nameMatch = v.businessName.toLowerCase().contains(
                      _searchQuery,
                    );
                    final descMatch = v.description.toLowerCase().contains(
                      _searchQuery,
                    );
                    final catMatch = (v.category ?? '').toLowerCase().contains(
                      _searchQuery,
                    );
                    return nameMatch || descMatch || catMatch;
                  }).toList();
                }

                // Apply sorting
                if (_sortBy == 'Top Rated') {
                  filtered.sort((a, b) {
                    int cmp = b.ratingAverage.compareTo(a.ratingAverage);
                    if (cmp == 0) return b.ratingCount.compareTo(a.ratingCount);
                    return cmp;
                  });
                } else if (_sortBy == 'Newest') {
                  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                } else if (_sortBy == 'Most Orders') {
                  filtered.sort(
                    (a, b) => b.completedOrders.compareTo(a.completedOrders),
                  );
                }

                return Column(
                  children: [
                    // Category Chips (Horizontal list)
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildCategoryChip('All', categoryCounts['All'] ?? 0),
                          ...AppConstants.categories.map((c) {
                            final String catId = c['id'] as String;
                            final String name = c['name'] as String;
                            final int count = categoryCounts[catId] ?? 0;
                            return _buildCategoryChip(name, count, id: catId);
                          }),
                        ],
                      ),
                    ),

                    // Sort Dropdown & results count
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} vendors found',
                            style: GoogleFonts.syne(
                              color: AppConstants.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Sort: ',
                                style: GoogleFonts.syne(
                                  color: AppConstants.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _sortBy,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppConstants.primaryColor,
                                ),
                                underline: const SizedBox(),
                                style: GoogleFonts.syne(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                items:
                                    <String>[
                                      'Top Rated',
                                      'Newest',
                                      'Most Orders',
                                    ].map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _sortBy = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Vendor Grid or Empty state
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isTablet = constraints.maxWidth >= 600;
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isTablet ? 3 : 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.85,
                                      ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final vendor = filtered[index];
                                    return _buildVendorCard(vendor);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int count, {String? id}) {
    final isSelected =
        (id != null && _selectedCategory.toLowerCase() == id.toLowerCase()) ||
        (id == null && _selectedCategory == 'All');

    return GlassFilterChip(
      label: '$label ($count)',
      selected: isSelected,
      onSelected: () {
        setState(() {
          _selectedCategory = id ?? 'All';
        });
      },
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    final initials = vendor.businessName.length >= 2
        ? vendor.businessName.substring(0, 2).toUpperCase()
        : vendor.businessName.toUpperCase();

    final categoryMap = AppConstants.categories.firstWhere(
      (c) =>
          (c['id'] as String).toLowerCase() ==
          (vendor.category ?? 'other').toLowerCase(),
      orElse: () => {'name': vendor.category ?? 'Other', 'icon': '📦'},
    );
    final categoryName = categoryMap['name'] as String;
    final categoryIcon = categoryMap['icon'] as String;

    final truncatedName = vendor.businessName.length > 30
        ? '${vendor.businessName.substring(0, 27)}...'
        : vendor.businessName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorProfileScreen(vendorId: vendor.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor avatar & category badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(vendor.businessName),
                  backgroundImage: vendor.logoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(vendor.logoUrl)
                      : null,
                  child: vendor.logoUrl.isEmpty
                      ? Text(
                          initials,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$categoryIcon $categoryName',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vendor Name
            Tooltip(
              message: vendor.businessName,
              child: Text(
                truncatedName,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Expanded(
              child: Text(
                vendor.description.isNotEmpty
                    ? vendor.description
                    : 'No description provided.',
                style: GoogleFonts.syne(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
                maxLines: 1, // Truncate to 1 line per requirement
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            // Rating Stars
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  vendor.ratingAverage.toStringAsFixed(1),
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${vendor.ratingCount})',
                  style: GoogleFonts.syne(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                  ),
                ),
                if (vendor.isVerified) ...[
                  const Spacer(),
                  const Icon(Icons.verified, color: Colors.blue, size: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No vendors match "$_searchQuery"',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or browse some popular categories below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(color: AppConstants.textSecondary),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: AppConstants.categories
                    .where((c) => ['food', 'services', 'tutoring'].contains(c['id']))
                    .map((c) {
                  final catId = c['id'] as String;
                  final catName = c['name'] as String;
                  return ActionChip(
                    label: Text(catName),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = catId;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront,
                size: 64,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No vendors in this category yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try another category or check back later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(color: AppConstants.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                  });
                },
                child: Text(
                  'Browse All Categories',
                  style: GoogleFonts.syne(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        // Skeleton Categories
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Skeleton Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppConstants.surfaceColor,
                            ),
                            Container(
                              width: 60,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppConstants.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
