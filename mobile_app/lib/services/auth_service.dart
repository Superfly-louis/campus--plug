import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Track the current user's profile
  UserModel? _userProfile;
  UserModel? get currentUserProfile => _userProfile;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In with Email & Password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserProfile(result.user!.uid);
      return result;
    } catch (e) {
      print('Sign In Error: $e');
      rethrow;
    }
  }

  // Register with Email & Password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String campusId,
    bool isVendor = false,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final campusMap = AppConstants.campuses.firstWhere(
        (c) => c['id'] == campusId,
        orElse: () => AppConstants.campuses[0],
      );
      final campusName = campusMap['name'] ?? AppConstants.defaultCampusName;

      // Create initial user document
      UserModel newUser = UserModel(
        id: result.user!.uid,
        fullName: fullName,
        email: email,
        phoneNumber: '',
        profileImageUrl: '',
        campusId: campusId,
        campusName: campusName,
        isVendor: isVendor,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        deviceToken: '',
      );

      await _db
          .collection(AppConstants.usersCollection)
          .doc(newUser.id)
          .set(newUser.toJson());

      _userProfile = newUser;
      return result;
    } catch (e) {
      print('Sign Up Error: $e');
      rethrow;
    }
  }

  // Helper to load profile
  Future<void> _loadUserProfile(String uid) async {
    var doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) {
      _userProfile = UserModel.fromJson(doc.data()!);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _userProfile = null;
  }
}
