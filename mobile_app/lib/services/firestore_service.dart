import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/vendor_model.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRODUCTS ---

  // Fetch all products for a specific campus
  Stream<List<ProductModel>> getProductsByCampus(String campusId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromJson(doc.data()))
            .toList());
  }

  // Fetch products by category & campus
  Stream<List<ProductModel>> getProductsByCategory(String campusId, String categoryId) {
    return _db
        .collection(AppConstants.productsCollection)
        .where('campusId', isEqualTo: campusId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromJson(doc.data()))
            .toList());
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
    var doc = await _db.collection(AppConstants.vendorsCollection).doc(vendorId).get();
    if (doc.exists) {
      return VendorModel.fromJson(doc.data()!);
    }
    return null;
  }

  // --- USER PROFILES ---

  // Fetch user profile
  Future<UserModel?> getUserProfile(String userId) async {
    var doc = await _db.collection(AppConstants.usersCollection).doc(userId).get();
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
}
