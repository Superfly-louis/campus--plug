import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/vendor_model.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRODUCTS ---

  // Fetch all products for a specific campus (sorted client-side to avoid composite index).
  Stream<List<ProductModel>> getProductsByCampus(String campusId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .snapshots()
        .map((snapshot) => _parseAndSortProducts(snapshot.docs));
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

  // Fetch products by category & campus (sorted client-side to avoid composite index).
  Stream<List<ProductModel>> getProductsByCategory(
    String campusId,
    String categoryId,
  ) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) => _parseAndSortProducts(snapshot.docs));
  }

  // Create a new product
  Future<void> createProduct(ProductModel product) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .set(product.toJson());
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
      'whatsappNumber': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection(AppConstants.usersCollection).doc(userId).update({
      'isVendor': true,
      'vendorId': docRef.id,
    });
    return docRef.id;
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
    final keywords = <String>{
      ...name.toLowerCase().split(RegExp(r'\s+')),
      ...description.toLowerCase().split(RegExp(r'\s+')),
      categoryId,
    }.where((w) => w.length > 2).toList();

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

  Stream<List<ProductModel>> getProductsByVendor(String vendorId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => _parseAndSortProducts(snapshot.docs));
  }
}
