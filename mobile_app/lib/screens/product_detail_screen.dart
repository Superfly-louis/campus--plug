import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _chatLoading = false;

  ProductModel get product => widget.product;

  Future<void> _chatWithSeller() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('Please sign in to message sellers');
      return;
    }

    setState(() => _chatLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);

      UserModel? currentProfile = authService.currentUserProfile;
      currentProfile ??=
          await firestoreService.getUserProfile(currentUser.uid);

      if (currentProfile == null) {
        _showError('Could not load your profile');
        return;
      }

      final sellerId =
          await firestoreService.getVendorOwnerId(product.vendorId);
      if (sellerId == null) {
        _showError('Seller not found');
        return;
      }

      if (sellerId == currentUser.uid) {
        _showError('You cannot message yourself');
        return;
      }

      UserModel? sellerProfile = await firestoreService.getUserProfile(sellerId);
      final sellerName = sellerProfile?.fullName ?? product.vendorName;
      final sellerImage = sellerProfile?.profileImageUrl ?? '';

      final chatId = await chatService.getOrCreateChat(
        currentUserId: currentUser.uid,
        otherUserId: sellerId,
        otherUserName: sellerName,
        otherUserImage: sellerImage,
        currentUserName: currentProfile.fullName,
        currentUserImage: currentProfile.profileImageUrl,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: sellerId,
            otherUserName: sellerName,
            otherUserImage: sellerImage,
          ),
        ),
      );
    } catch (e) {
      _showError('Could not start chat: $e');
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.simpleCurrency(name: 'NGN', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${product.id}',
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls[0],
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppConstants.surfaceColor),
              ),
            ),
            backgroundColor: AppConstants.primaryColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.categoryId,
                          style: const TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 16,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.viewCount} views',
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(product.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Item Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppConstants.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: AppConstants.primaryColor,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.vendorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Verified Campus Seller',
                                style: TextStyle(
                                  color: AppConstants.secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppConstants.primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Visit Store'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
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
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _chatLoading ? null : _chatWithSeller,
                icon: _chatLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.textPrimary,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat with Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.surfaceColor,
                  foregroundColor: AppConstants.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
