import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_constants.dart';
import '../models/review_model.dart';
import '../models/vendor_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/review_form_dialog.dart';
import 'chat_screen.dart';
import 'shop_create_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VendorProfileScreen extends StatefulWidget {
  final String vendorId;

  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  bool _isDescriptionExpanded = false;

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

  void _chatWithVendor(VendorModel vendor) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackbar('Please sign in to message this vendor');
      return;
    }

    if (vendor.ownerId == currentUser.uid) {
      _showSnackbar('You cannot message yourself');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final profile = authService.currentUserProfile;

    openChatScreen(
      context,
      previewName: vendor.businessName,
      previewImage: vendor.logoUrl,
      chatFuture: chatService.getOrCreateChat(
        currentUserId: currentUser.uid,
        otherUserId: vendor.ownerId,
        otherUserName: vendor.businessName,
        otherUserImage: vendor.logoUrl,
        currentUserName: profile?.fullName ?? 'Campus User',
        currentUserImage: profile?.profileImageUrl ?? '',
        vendorId: vendor.id,
        subject: 'Inquiry with ${vendor.businessName}',
      ).then(
        (chatId) => ChatLaunchResult(
          chatId: chatId,
          otherUserId: vendor.ownerId,
          otherUserName: vendor.businessName,
          otherUserImage: vendor.logoUrl,
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _leaveOrEditReview(VendorModel vendor, List<ReviewModel> reviews) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackbar('Please sign in to leave a review');
      return;
    }

    if (vendor.ownerId == currentUser.uid) {
      _showSnackbar('Vendors cannot review themselves');
      return;
    }

    // Check if user already reviewed
    final existingIndex = reviews.indexWhere((r) => r.buyerId == currentUser.uid);
    ReviewModel? existingReview;
    if (existingIndex != -1) {
      existingReview = reviews[existingIndex];
    }

    if (existingReview != null) {
      // Prompt user to edit existing review
      final editResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Already Reviewed', style: GoogleFonts.syne(fontWeight: FontWeight.bold)),
          content: Text(
            'You have already left a review for ${vendor.businessName}. Would you like to edit your review?',
            style: GoogleFonts.syne(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.syne(color: AppConstants.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Edit Review', style: GoogleFonts.syne(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (editResult == true && mounted) {
        await _showReviewDialog(vendor, existingReview: existingReview);
      }
    } else {
      await _showReviewDialog(vendor);
    }
  }

  Future<void> _showReviewDialog(VendorModel vendor, {ReviewModel? existingReview}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewFormDialog(
        vendorId: vendor.id,
        vendorName: vendor.businessName,
        existingReview: existingReview,
      ),
    );
    if (result == true) {
      setState(() {}); // Refresh state
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vendor Profile',
          style: GoogleFonts.syne(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          StreamBuilder<VendorModel?>(
            stream: firestoreService.watchVendor(widget.vendorId),
            builder: (context, snapshot) {
              final vendor = snapshot.data;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final isOwner = vendor != null &&
                  uid != null &&
                  vendor.ownerId == uid;
              if (!isOwner) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Edit shop',
                icon: const Icon(Icons.edit_outlined, color: AppConstants.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopCreateScreen(existingVendor: vendor),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<VendorModel?>(
        stream: firestoreService.watchVendor(widget.vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Vendor profile not found.',
                style: GoogleFonts.syne(color: AppConstants.textSecondary),
              ),
            );
          }

          final vendor = snapshot.data!;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final isOwner = uid != null && vendor.ownerId == uid;
          if (vendor.isSuspended && !isOwner) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: AppConstants.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This shop is currently unavailable',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check back later or browse other campus shops.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final initials = vendor.businessName.length >= 2
              ? vendor.businessName.substring(0, 2).toUpperCase()
              : vendor.businessName.toUpperCase();

          final categoryMap = AppConstants.categories.firstWhere(
            (c) => (c['id'] as String).toLowerCase() == (vendor.category ?? 'other').toLowerCase(),
            orElse: () => {'name': vendor.category ?? 'Other', 'icon': '📦'},
          );
          final categoryName = categoryMap['name'] as String;
          final categoryIcon = categoryMap['icon'] as String;

          final displayName = vendor.businessName.length > 30
              ? '${vendor.businessName.substring(0, 27)}...'
              : vendor.businessName;

          return StreamBuilder<List<ReviewModel>>(
            stream: firestoreService.getVendorReviews(vendor.id),
            builder: (context, reviewsSnapshot) {
              final reviews = reviewsSnapshot.data ?? [];
              final recentReviews = reviews.take(5).toList();
              final currentUser = FirebaseAuth.instance.currentUser;
              final existingIndex = currentUser != null ? reviews.indexWhere((r) => r.buyerId == currentUser.uid) : -1;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
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
                                      fontSize: 24,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message: vendor.businessName,
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.syne(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (vendor.isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                    Text(
                                      '⭐ ${vendor.ratingAverage.toStringAsFixed(1)} (${vendor.ratingCount} reviews)',
                                      style: GoogleFonts.syne(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.textPrimary,
                                      ),
                                    ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$categoryIcon $categoryName',
                                    style: GoogleFonts.syne(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bio/Description Section
                    if (vendor.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.description,
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                color: AppConstants.textPrimary,
                                height: 1.5,
                              ),
                              maxLines: _isDescriptionExpanded ? null : 3,
                              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                            if (vendor.description.split('\n').length > 3 || vendor.description.length > 120)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isDescriptionExpanded = !_isDescriptionExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _isDescriptionExpanded ? 'Read less' : 'Read more',
                                    style: GoogleFonts.syne(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (vendor.responseTimeMinutes != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildResponseTimeBadge(vendor.responseTimeMinutes!),
                        ),
                      ),
                      
                    // Inactive Vendor Badge
                    FutureBuilder<UserModel?>(
                      future: firestoreService.getUserProfile(vendor.ownerId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || userSnapshot.data == null) return const SizedBox.shrink();
                        final user = userSnapshot.data!;
                        final now = DateTime.now();
                        final diff = now.difference(user.lastActive).inDays;
                        if (diff >= 14) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.history, color: Colors.grey, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Last active 2 weeks ago',
                                      style: GoogleFonts.syne(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const Divider(height: 32, thickness: 1, color: AppConstants.borderColor),

                    // Reviews Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Reviews',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _leaveOrEditReview(vendor, reviews),
                            child: Text(
                              existingIndex != -1 ? 'Edit Review' : 'Leave Review',
                              style: GoogleFonts.syne(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (recentReviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          'No reviews yet - Be the first to leave one',
                          style: GoogleFonts.syne(
                            color: AppConstants.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recentReviews.length,
                        itemBuilder: (context, index) {
                          final review = recentReviews[index];
                          return ReviewTile(review: review);
                        },
                      ),
                      if (reviews.length > 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReviewsListScreen(
                                      vendorId: vendor.id,
                                      vendorName: vendor.businessName,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'View All Reviews',
                                style: GoogleFonts.syne(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomSheet: StreamBuilder<VendorModel?>(
        stream: firestoreService.watchVendor(widget.vendorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final vendor = snapshot.data!;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final isOwner = uid != null && vendor.ownerId == uid;
          if (vendor.isSuspended && !isOwner) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _chatWithVendor(vendor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Message Vendor',
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponseTimeBadge(int minutes) {
    if (minutes < 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              'Fast responder',
              style: GoogleFonts.syne(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (minutes > 15) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              'Typically responds in $minutes minutes',
              style: GoogleFonts.syne(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  int min(int a, int b) => a < b ? a : b;
}

class ReviewTile extends StatefulWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  State<ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<ReviewTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.review.buyerName ?? 'Campus User';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    String anonymizedName = fullName;
    if (parts.length > 1 && parts[1].isNotEmpty) {
      anonymizedName = '${parts[0]} ${parts[1][0]}.';
    } else if (parts.isNotEmpty) {
      anonymizedName = parts[0];
    }

    final reviewText = widget.review.text;
    final bool hasLongText = reviewText != null && reviewText.length > 100;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                anonymizedName,
                style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(widget.review.createdAt),
                style: GoogleFonts.syne(fontSize: 11, color: AppConstants.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < widget.review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          if (reviewText != null && reviewText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hasLongText && !_isExpanded 
                  ? '${reviewText.substring(0, 100)}...' 
                  : reviewText,
              style: GoogleFonts.syne(fontSize: 13, color: AppConstants.textPrimary),
            ),
            if (hasLongText)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'Read less' : 'Read more',
                    style: GoogleFonts.syne(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

// Separate Screen for viewing all reviews paginated/listed
class ReviewsListScreen extends StatelessWidget {
  final String vendorId;
  final String vendorName;

  const ReviewsListScreen({super.key, required this.vendorId, required this.vendorName});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Reviews - $vendorName',
          style: GoogleFonts.syne(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: firestoreService.getVendorReviews(vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor));
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return Center(child: Text('No reviews yet.', style: GoogleFonts.syne()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buyer ${review.buyerId.substring(0, review.buyerId.length > 4 ? 4 : review.buyerId.length).toUpperCase()}',
                          style: GoogleFonts.syne(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(review.createdAt),
                          style: GoogleFonts.syne(fontSize: 11, color: AppConstants.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                    if (review.text != null && review.text!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        review.text!,
                        style: GoogleFonts.syne(fontSize: 14, color: AppConstants.textPrimary),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
