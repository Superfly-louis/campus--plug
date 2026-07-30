import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app_constants.dart';

/// Shared client-side validators for auth forms.
class AuthValidators {
  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'E-mail is required';
    if (!_emailPattern.hasMatch(email)) return 'Invalid e-mail format';
    return null;
  }

  static String? password(String? value, {bool requiredCheck = true}) {
    if (value == null || value.isEmpty) {
      return requiredCheck ? 'Password is required' : null;
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Minimum ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}

String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password. Check your details or sign up first.';
      case 'invalid-email':
      case 'missing-email':
        return 'Please enter a valid email address.';
      case 'missing-password':
        return 'Please enter your password.';
      case 'email-already-in-use':
        return 'This email is already registered. Log in instead, or use the same password to finish setup.';
      case 'weak-password':
        return 'Password is too weak. Use at least ${AppConstants.minPasswordLength} characters.';
      case 'operation-not-allowed':
        return 'Sign-in is temporarily unavailable. Please try again later.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';
      case 'requires-recent-login':
        return 'For security, please log in again before doing this.';
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'This link has expired or was already used. Request a new one.';
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'session-expired':
        return 'Your session has expired. Please log in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      case 'user-mismatch':
        return 'These credentials do not match the signed-in user. Please try again.';
      case 'missing-google-id-token':
        return 'Google sign-in is not fully set up yet. Ask the developer to add the app SHA-1 in Firebase.';
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'Invalid verification code. Please try again.';
      case 'internal-error':
        return 'Something went wrong on our end. Please try again.';
      default:
        // Never surface raw Firebase error strings to users.
        return 'Authentication failed. Please try again.';
    }
  }

  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in was cancelled.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Could not save your profile. Please try again or contact support.';
  }

  return 'Something went wrong. Please try again.';
}
