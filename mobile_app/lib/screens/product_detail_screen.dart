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
import 'add_product_screen.dart';
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
  late ProductModel _product;
  bool _isDeleting = false;

  ProductModel get product => _product;

  bool get _isOwner {
    final vendorId =
        Provider.of<AuthService>(context, listen: false).currentUserProfile?.vendorId;
    return vendorId != null &&
        vendorId.isNotEmpty &&
        vendorId == _product.vendorId;
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<ChatLaunchResult> _resolveChat(String currentUserId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    UserModel? currentProfile = authService.currentUserProfile;
    currentProfile ??= await firestoreService.getUserProfile(currentUserId);

    if (currentProfile == null) {
      throw StateError('Could not load your profile');
    }

    final sellerId = await firestoreService.getVendorOwnerId(product.vendorId);
    if (sellerId == null) {
      throw StateError('Seller not found');
    }

    if (sellerId == currentUserId) {
      throw StateError('You cannot message yourself');
    }

    final sellerProfile = await firestoreService.getUserProfile(sellerId);
    final sellerName = sellerProfile?.fullName ?? product.vendorName;
    final sellerImage = sellerProfile?.profileImageUrl ?? '';

    final chatId = await chatService.getOrCreateChat(
      currentUserId: currentUserId,
      otherUserId: sellerId,
      otherUserName: sellerName,
      otherUserImage: sellerImage,
      currentUserName: currentProfile.fullName,
      currentUserImage: currentProfile.profileImageUrl,
      vendorId: product.vendorId,
      subject: '${product.name} Order',
    );

    return ChatLaunchResult(
      chatId: chatId,
      otherUserId: sellerId,
      otherUserName: sellerName,
      otherUserImage: sellerImage,
    );
  }

  void _chatWithSeller() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('Please sign in to message sellers');
      return;
    }

    openChatScreen(
      context,
      previewName: product.vendorName,
      chatFuture: _resolveChat(currentUser.uid).catchError((error) {
        _showError(
          error is StateError ? error.message : 'Could not start chat: $error',
        );
        throw error;
      }),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openEdit() async {
    if (!_isOwner) {
      _showError('You can only edit products from your own shop.');
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(existingProduct: _product),
      ),
    );

    if (updated == true && mounted) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final fresh = await firestoreService.getProduct(_product.id);
      if (fresh != null && mounted) {
        setState(() => _product = fresh);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isOwner || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '“${_product.name}” will be removed from your shop. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteProduct();
  }

  Future<void> _deleteProduct() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final vendorId = authService.currentUserProfile?.vendorId;
    if (vendorId == null || vendorId != _product.vendorId) {
      _showError('You can only delete products from your own shop.');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.deleteProduct(
        productId: _product.id,
        expectedVendorId: vendorId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not delete product: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      name: AppConstants.currencyCode,
      decimalDigits: 0,
    );
    final isOwner = _isOwner;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  enabled: !_isDeleting,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEdit();
                    } else if (value == 'delete') {
                      _confirmDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit product'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete product',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
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
      bottomSheet: isOwner
          ? null
          : Container(
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
                      onPressed: _chatWithSeller,
                      icon: const Icon(Icons.chat_bubble_outline),
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
