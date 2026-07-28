import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _userProfile;
  UserModel? get currentUserProfile => _userProfile;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }
    await _syncAuthToken(user);
    await _loadUserProfile(user.uid);
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
      phoneNumber: '',
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
    late final UserCredential result;
    try {
      result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Wrong password on an existing email — keep the signup-oriented message.
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: e.message,
        );
      }
      rethrow;
    }
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

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
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
    String phoneNumber = '',
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
      'isAdmin': false,
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
      isAdmin: false,
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

  /// Deletes owned Firestore data (products/vendor/orders/chats/reviews/user),
  /// then the Firebase Auth user. Requires [password] for reauthentication.
  /// Cloudinary assets are not deleted (unsigned API cannot remove them).
  Future<void> deleteAccount({
    required String password,
    required FirestoreService firestoreService,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to delete.',
      );
    }

    final uid = user.uid;
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Reauthentication required to delete this account.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    final vendorId = _userProfile?.vendorId;
    await firestoreService.deleteUserOwnedData(
      uid: uid,
      vendorId: vendorId,
    );

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        rethrow;
      }
    }

    _userProfile = null;
  }

  /// Sends a verification link to [newEmail]. Auth email updates after the user
  /// confirms; Firestore email is left unchanged until then.
  Future<void> updateAccountEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    final currentEmail = user.email;
    if (currentEmail == null || currentEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Current account has no email.',
      );
    }

    final trimmed = newEmail.trim();
    if (trimmed.isEmpty || trimmed == currentEmail) return;

    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(trimmed);
  }
}
