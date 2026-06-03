import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Incorrect email or password. Check your details or sign up first.';
      case 'email-already-in-use':
        return 'This email is already registered. Use the same password to finish setup, or log in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase. Enable it in the Firebase Console under Authentication → Sign-in method.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Could not save your profile. Firestore security rules need to be deployed — run: firebase deploy --only firestore:rules';
  }

  return error.toString();
}
