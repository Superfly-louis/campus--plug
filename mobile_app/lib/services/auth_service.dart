import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _userProfile;
  UserModel? get currentUserProfile => _userProfile;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncAuthToken(result.user!);
    await _loadUserProfile(result.user!.uid);
    return result;
  }

  /// Creates a minimal profile if auth exists but Firestore doc is missing.
  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String fullName = 'Campus User',
    String campusId = AppConstants.defaultCampusId,
    bool isVendor = false,
  }) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) {
      _userProfile = UserModel.fromJson(doc.data()!);
      return;
    }

    await _saveUserProfile(
      uid: uid,
      fullName: fullName,
      email: email,
      campusId: campusId,
    );
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String campusId,
    bool isVendor = false,
  }) async {
    UserCredential? result;

    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _syncAuthToken(result.user!);
      await _saveUserProfile(
        uid: result.user!.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        campusId: campusId,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return _recoverPartialSignup(
          email: email,
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
          campusId: campusId,
          isVendor: isVendor,
        );
      }
      rethrow;
    } catch (e) {
      if (result?.user != null) {
        try {
          await result!.user!.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Handles accounts where Auth was created but Firestore profile write failed.
  Future<UserCredential?> _recoverPartialSignup({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String campusId,
    required bool isVendor,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncAuthToken(result.user!);

    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(result.user!.uid)
        .get();

    if (!doc.exists) {
      await _saveUserProfile(
        uid: result.user!.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        campusId: campusId,
      );
    } else {
      _userProfile = UserModel.fromJson(doc.data()!);
    }

    return result;
  }

  /// Web needs a fresh ID token before Firestore rules see request.auth.
  Future<void> _syncAuthToken(User user) async {
    await user.getIdToken(true);
    await user.reload();
  }

  Future<void> _saveUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String campusId,
  }) async {
    final campusMap = AppConstants.campuses.firstWhere(
      (c) => c['id'] == campusId,
      orElse: () => AppConstants.campuses[0],
    );
    final campusName = campusMap['name'] ?? AppConstants.defaultCampusName;

    final data = {
      'id': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': '',
      'campusId': campusId,
      'campusName': campusName,
      'isVendor': false,
      'hasSelectedRole': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'deviceToken': '',
    };

    // Retry once on web if auth token hasn't propagated to Firestore yet.
    try {
      await _db.collection(AppConstants.usersCollection).doc(uid).set(data);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final user = _auth.currentUser;
      if (user != null) await _syncAuthToken(user);
      await _db.collection(AppConstants.usersCollection).doc(uid).set(data);
    }

    _userProfile = UserModel(
      id: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      profileImageUrl: '',
      campusId: campusId,
      campusName: campusName,
      isVendor: false,
      hasSelectedRole: false,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      deviceToken: '',
    );
  }

  Future<void> _loadUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) {
      _userProfile = UserModel.fromJson(doc.data()!);
    } else {
      _userProfile = null;
    }
  }

  Future<void> reloadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _loadUserProfile(uid);
    }
  }

  void updateLocalProfile(UserModel profile) {
    _userProfile = profile;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userProfile = null;
  }
}
