import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/vendor_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/order_model.dart';
import '../core/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRODUCTS ---

  // Fetch all products for a specific campus (sorted client-side to avoid composite index).
  // Excludes suspended vendors' products and admin-removed listings (buyer-facing).
  Stream<List<ProductModel>> getProductsByCampus(String campusId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .snapshots()
        .asyncMap((snapshot) async {
          final products = _parseAndSortProducts(snapshot.docs);
          return _excludeBuyerHiddenProducts(products);
        });
  }

  List<ProductModel> _parseProducts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final products = <ProductModel>[];
    for (final doc in docs) {
      try {
        products.add(ProductModel.fromJson(doc.data()));
      } catch (_) {
        // Skip legacy documents with incomplete schema.
      }
    }
    return products;
  }

  List<ProductModel> _parseAndSortProducts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final products = _parseProducts(docs);
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  /// Vendor ids currently marked suspended (missing status = active).
  Future<Set<String>> _suspendedVendorIds() async {
    final snap = await _db
        .collection(AppConstants.vendorsCollection)
        .where('status', isEqualTo: VendorStatus.suspended)
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<List<ProductModel>> _excludeSuspendedVendorProducts(
    List<ProductModel> products,
  ) async {
    if (products.isEmpty) return products;
    final suspended = await _suspendedVendorIds();
    if (suspended.isEmpty) return products;
    return products.where((p) => !suspended.contains(p.vendorId)).toList();
  }

  /// Buyer-facing: hide admin-removed listings and products from suspended vendors.
  Future<List<ProductModel>> _excludeBuyerHiddenProducts(
    List<ProductModel> products,
  ) async {
    final withoutRemoved =
        products.where((p) => !p.isAdminRemoved).toList();
    return _excludeSuspendedVendorProducts(withoutRemoved);
  }

  // Fetch products by category & campus (sorted client-side to avoid composite index).
  // Excludes suspended vendors' products and admin-removed listings (buyer-facing).
  Stream<List<ProductModel>> getProductsByCategory(
    String campusId,
    String categoryId,
  ) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .asyncMap((snapshot) async {
          final products = _parseAndSortProducts(snapshot.docs);
          return _excludeBuyerHiddenProducts(products);
        });
  }

  /// Campus products stream, optionally narrowed by category in Firestore.
  /// Search and price are applied client-side via [applyProductFilters].
  Stream<List<ProductModel>> watchCampusProducts({
    required String campusId,
    String? categoryId,
  }) {
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      return getProductsByCategory(campusId, categoryId);
    }
    return getProductsByCampus(campusId);
  }

  /// Client-side AND filters (search + optional category + price), matching
  /// Explore's pattern of filtering after a campus-scoped fetch.
  List<ProductModel> applyProductFilters(
    List<ProductModel> products, {
    String? categoryId,
    String searchQuery = '',
    double? minPrice,
    double? maxPrice,
  }) {
    var filtered = List<ProductModel>.from(products);

    if (categoryId != null &&
        categoryId.isNotEmpty &&
        categoryId != 'all') {
      filtered = filtered
          .where((p) => p.categoryId.toLowerCase() == categoryId.toLowerCase())
          .toList();
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final vendorMatch = p.vendorName.toLowerCase().contains(query);
        final keywordMatch = p.searchKeywords.any(
          (k) => k.toLowerCase().contains(query),
        );
        return nameMatch || descMatch || vendorMatch || keywordMatch;
      }).toList();
    }

    if (minPrice != null) {
      filtered = filtered.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      filtered = filtered.where((p) => p.price <= maxPrice).toList();
    }

    return filtered;
  }

  // Create a new product
  Future<void> createProduct(ProductModel product) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .set(product.toJson());
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    try {
      return ProductModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // --- VENDORS ---

  // Fetch a single vendor by ID
  Future<VendorModel?> getVendor(String vendorId) async {
    var doc = await _db
        .collection(AppConstants.vendorsCollection)
        .doc(vendorId)
        .get();
    if (doc.exists) {
      return VendorModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Resolves seller user id from vendor document (supports ownerId or userId field).
  Future<String?> getVendorOwnerId(String vendorId) async {
    final doc = await _db
        .collection(AppConstants.vendorsCollection)
        .doc(vendorId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return data['ownerId'] as String? ?? data['userId'] as String?;
  }

  // --- USER PROFILES ---

  // Fetch user profile
  Future<UserModel?> getUserProfile(String userId) async {
    var doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Update user profile
  Future<void> updateProfile(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
  }

  /// Partial user update — avoids rewriting timestamps / unrelated fields.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      ...fields,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createVendor({
    required String userId,
    required String shopName,
    required String category,
    required String description,
    required String campusId,
    String logoUrl = '',
  }) async {
    final docRef = _db.collection(AppConstants.vendorsCollection).doc();
    await docRef.set({
      'id': docRef.id,
      'ownerId': userId,
      'businessName': shopName,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': '',
      'categories': [category],
      'campusId': campusId,
      'ratingAverage': 0.0,
      'ratingCount': 0,
      'isVerified': false,
      'status': VendorStatus.active,
      'whatsappNumber': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'isVendor': true,
      'vendorId': docRef.id,
    });
    return docRef.id;
  }

  /// Live vendor doc for shop/profile headers after edits.
  Stream<VendorModel?> watchVendor(String vendorId) {
    return _db
        .collection(AppConstants.vendorsCollection)
        .doc(vendorId)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          try {
            return VendorModel.fromJson(snap.data()!);
          } catch (_) {
            return null;
          }
        });
  }

  /// Updates editable shop fields. [expectedOwnerId] must match the doc's ownerId.
  /// Does not touch ratings / verification. Syncs denormalized product.vendorName.
  Future<void> updateVendor({
    required String vendorId,
    required String expectedOwnerId,
    required String shopName,
    required String category,
    required String description,
    required String campusId,
    required String whatsappNumber,
    String? logoUrl,
  }) async {
    final docRef = _db.collection(AppConstants.vendorsCollection).doc(vendorId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Shop not found');
    }
    final data = snap.data()!;
    if (data['ownerId'] != expectedOwnerId) {
      throw StateError('Not authorized to update this shop');
    }

    final updates = <String, dynamic>{
      'businessName': shopName,
      'description': description,
      'categories': [category],
      'campusId': campusId,
      'whatsappNumber': whatsappNumber,
    };
    if (logoUrl != null) {
      updates['logoUrl'] = logoUrl;
    }

    await docRef.update(updates);

    // Keep denormalized product.vendorName in sync when the shop is renamed.
    final previousName = data['businessName'] as String? ?? '';
    if (previousName != shopName) {
      final products = await _db
          .collection(AppConstants.productsCollection)
          .where('vendorId', isEqualTo: vendorId)
          .get();
      if (products.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in products.docs) {
          batch.update(doc.reference, {'vendorName': shopName});
        }
        await batch.commit();
      }
    }
  }

  Future<void> addProduct({
    required String vendorId,
    required String name,
    required String categoryId,
    required String description,
    required double price,
    required String campusId,
    List<String> imageUrls = const [],
  }) async {
    final vendor = await getVendor(vendorId);
    final vendorName = vendor?.businessName ?? 'Campus Shop';
    final keywords = _productSearchKeywords(
      name: name,
      description: description,
      categoryId: categoryId,
    );

    final docRef = _db.collection(AppConstants.productsCollection).doc();
    await docRef.set({
      'id': docRef.id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'campusId': campusId,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrls': imageUrls,
      'status': 'available',
      'condition': 'new',
      'viewCount': 0,
      'likeCount': 0,
      'searchKeywords': keywords,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates editable product fields. [expectedVendorId] must match the doc's
  /// vendorId (caller should pass the signed-in vendor's id).
  Future<void> updateProduct({
    required String productId,
    required String expectedVendorId,
    required String name,
    required String categoryId,
    required String description,
    required double price,
    List<String>? imageUrls,
  }) async {
    final docRef = _db.collection(AppConstants.productsCollection).doc(productId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Product not found');
    }
    final data = snap.data()!;
    if (data['vendorId'] != expectedVendorId) {
      throw StateError('Not authorized to update this product');
    }

    final keywords = _productSearchKeywords(
      name: name,
      description: description,
      categoryId: categoryId,
    );

    final updates = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'searchKeywords': keywords,
    };
    if (imageUrls != null) {
      updates['imageUrls'] = imageUrls;
    }

    await docRef.update(updates);
  }

  /// Deletes a product doc. [expectedVendorId] must match the doc's vendorId.
  /// Does not delete Cloudinary assets (requires signed API / Cloud Function).
  Future<void> deleteProduct({
    required String productId,
    required String expectedVendorId,
  }) async {
    final docRef = _db.collection(AppConstants.productsCollection).doc(productId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Product not found');
    }
    final data = snap.data()!;
    if (data['vendorId'] != expectedVendorId) {
      throw StateError('Not authorized to delete this product');
    }
    await docRef.delete();
  }

  List<String> _productSearchKeywords({
    required String name,
    required String description,
    required String categoryId,
  }) {
    return <String>{
      ...name.toLowerCase().split(RegExp(r'\s+')),
      ...description.toLowerCase().split(RegExp(r'\s+')),
      categoryId,
    }.where((w) => w.length > 2).toList();
  }

  Stream<List<ProductModel>> getProductsByVendor(String vendorId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => _parseAndSortProducts(snapshot.docs));
  }

  // --- NEW VENDOR & REVIEW OPERATIONS ---

  Stream<List<VendorModel>> getVendorsByCampus(String campusId) {
    return _db
        .collection(AppConstants.vendorsCollection)
        .where('campusId', isEqualTo: campusId)
        .snapshots()
        .map((snapshot) {
          final vendors = <VendorModel>[];
          for (final doc in snapshot.docs) {
            try {
              final vendor = VendorModel.fromJson(doc.data());
              if (!vendor.isSuspended) vendors.add(vendor);
            } catch (_) {
              // Skip legacy/incomplete documents
            }
          }
          return vendors;
        });
  }

  Future<List<VendorModel>> fetchVendorsByCampusFuture(String campusId) async {
    final snapshot = await _db
        .collection(AppConstants.vendorsCollection)
        .where('campusId', isEqualTo: campusId)
        .get();

    final vendors = <VendorModel>[];
    for (final doc in snapshot.docs) {
      try {
        final vendor = VendorModel.fromJson(doc.data());
        if (!vendor.isSuspended) vendors.add(vendor);
      } catch (_) {
        // Skip legacy/incomplete documents
      }
    }
    return vendors;
  }

  Stream<List<VendorModel>> getAllVendors() {
    return _db.collection(AppConstants.vendorsCollection).snapshots().map((
      snapshot,
    ) {
      final vendors = <VendorModel>[];
      for (final doc in snapshot.docs) {
        try {
          final vendor = VendorModel.fromJson(doc.data());
          if (!vendor.isSuspended) vendors.add(vendor);
        } catch (_) {
          // Skip legacy/incomplete documents
        }
      }
      return vendors;
    });
  }

  Future<void> verifyVendor(String vendorId, bool isVerified) async {
    await _db.collection(AppConstants.vendorsCollection).doc(vendorId).update({
      'isVerified': isVerified,
    });
  }

  Stream<List<ReviewModel>> getVendorReviews(String vendorId) {
    return _db
        .collection(AppConstants.reviewsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// One review per buyer per vendor; document id is deterministic for upsert.
  static String reviewDocId(String vendorId, String buyerId) =>
      '${vendorId}_$buyerId';

  Future<void> createReview(ReviewModel review) async {
    final reviewId = reviewDocId(review.vendorId, review.buyerId);
    final reviewRef = _db
        .collection(AppConstants.reviewsCollection)
        .doc(reviewId);
    final data = review.toJson();
    data['id'] = reviewId;
    await reviewRef.set(data, SetOptions(merge: true));

    await updateVendorRating(review.vendorId);
  }

  Future<void> updateVendorRating(String vendorId) async {
    final query = await _db
        .collection(AppConstants.reviewsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    final reviews = query.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();

    int count = reviews.length;
    double average = 0.0;
    if (count > 0) {
      double sum = reviews.fold(0.0, (acc, r) => acc + r.rating);
      average = double.parse((sum / count).toStringAsFixed(1));
    }

    await _db.collection(AppConstants.vendorsCollection).doc(vendorId).update({
      'ratingAverage': average,
      'ratingCount': count,
    });
  }

  // --- ORDERS ---

  List<OrderModel> _parseAndSortOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final orders = <OrderModel>[];
    for (final doc in docs) {
      try {
        orders.add(OrderModel.fromFirestore(doc));
      } catch (_) {
        // Skip legacy/incomplete documents.
      }
    }
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Creates an order doc. Generates an id when [order.id] is empty.
  /// Uses server timestamps for createdAt / updatedAt.
  Future<String> createOrder(OrderModel order) async {
    final docRef = order.id.isNotEmpty
        ? _db.collection(AppConstants.ordersCollection).doc(order.id)
        : _db.collection(AppConstants.ordersCollection).doc();

    final data = order.toJson();
    data['id'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    return docRef.id;
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    try {
      return OrderModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// Buyer order history (newest first, sorted client-side).
  Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) => _parseAndSortOrders(snapshot.docs));
  }

  /// Vendor incoming orders by shop id (newest first, sorted client-side).
  Stream<List<OrderModel>> getOrdersByVendor(String vendorId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => _parseAndSortOrders(snapshot.docs));
  }

  /// Orders linked to a chat conversation (newest first, sorted client-side).
  Stream<List<OrderModel>> getOrdersByChat(String chatId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) => _parseAndSortOrders(snapshot.docs));
  }

  /// Generic status transition. Callers validate allowed transitions in UI/logic.
  /// [declineReason] is written only when provided (typically status = declined).
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? declineReason,
  }) async {
    if (!OrderStatus.values.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported order status');
    }
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final reason = declineReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      updates['declineReason'] = reason;
    }
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update(updates);
  }

  /// Best-effort cascade before Auth account deletion.
  /// Deletes: products + vendor (if [vendorId]), reviews by buyer, orders as
  /// buyer or vendorOwner, chats (and messages) the user participates in,
  /// then the user doc.
  Future<void> deleteUserOwnedData({
    required String uid,
    String? vendorId,
  }) async {
    Future<void> deleteQuery(QuerySnapshot<Map<String, dynamic>> snap) async {
      if (snap.docs.isEmpty) return;
      var batch = _db.batch();
      var count = 0;
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }

    if (vendorId != null && vendorId.isNotEmpty) {
      final products = await _db
          .collection(AppConstants.productsCollection)
          .where('vendorId', isEqualTo: vendorId)
          .get();
      await deleteQuery(products);

      try {
        await _db.collection(AppConstants.vendorsCollection).doc(vendorId).delete();
      } catch (_) {}
    }

    final reviewsByBuyer = await _db
        .collection(AppConstants.reviewsCollection)
        .where('buyerId', isEqualTo: uid)
        .get();
    await deleteQuery(reviewsByBuyer);

    final ordersAsBuyer = await _db
        .collection(AppConstants.ordersCollection)
        .where('buyerId', isEqualTo: uid)
        .get();
    await deleteQuery(ordersAsBuyer);

    final ordersAsVendor = await _db
        .collection(AppConstants.ordersCollection)
        .where('vendorOwnerId', isEqualTo: uid)
        .get();
    await deleteQuery(ordersAsVendor);

    final chats = await _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: uid)
        .get();
    for (final chatDoc in chats.docs) {
      final messages = await chatDoc.reference
          .collection(AppConstants.messagesCollection)
          .get();
      await deleteQuery(messages);
      try {
        await chatDoc.reference.delete();
      } catch (_) {}
    }

    try {
      await _db.collection(AppConstants.usersCollection).doc(uid).delete();
    } catch (_) {}
  }
}
