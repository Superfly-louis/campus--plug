import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_constants.dart';
import '../core/auth_errors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'vendor_shop_screen.dart';

class ProfileScreen extends StatefulWidget {
  /// When set, "Manage My Shop" switches to the Shop tab instead of pushing.
  final VoidCallback? onOpenShopTab;

  const ProfileScreen({super.key, this.onOpenShopTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  bool _loggingOut = false;
  bool _deleting = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _campusId = AppConstants.defaultCampusId;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startEditing(UserModel profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber;
    _emailController.text = profile.email;
    _passwordController.clear();
    _pickedImage = null;
    _pickedImageBytes = null;
    final known = AppConstants.campuses.any((c) => c['id'] == profile.campusId);
    _campusId = known ? profile.campusId : AppConstants.defaultCampusId;
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _pickedImage = null;
      _pickedImageBytes = null;
      _passwordController.clear();
    });
  }

  Future<void> _pickPhoto() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final picked = await storage.pickImageFromGallery();
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _save(UserModel profile) async {
    if (!_formKey.currentState!.validate() || _saving) return;

    final newEmail = _emailController.text.trim();
    final emailChanged = newEmail.isNotEmpty && newEmail != profile.email;
    if (emailChanged && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password to change email')),
      );
      return;
    }

    setState(() => _saving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);

    final campus = AppConstants.campuses.firstWhere(
      (c) => c['id'] == _campusId,
      orElse: () => AppConstants.campuses.first,
    );
    final campusName = campus['name'] ?? AppConstants.defaultCampusName;
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    var imageUrl = profile.profileImageUrl;

    try {
      if (_pickedImage != null) {
        final ext = _pickedImage!.name.split('.').last;
        final uploaded = await storage.tryUploadImage(
          storagePath:
              'users/${profile.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
          file: _pickedImage!,
        );
        if (uploaded != null) {
          imageUrl = uploaded;
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload skipped — other changes saved.'),
            ),
          );
        }
      }

      if (emailChanged) {
        await authService.updateAccountEmail(
          newEmail: newEmail,
          password: _passwordController.text,
        );
      }

      await firestore.updateUserFields(profile.id, {
        'fullName': fullName,
        'phoneNumber': phone,
        'campusId': _campusId,
        'campusName': campusName,
        if (imageUrl != profile.profileImageUrl) 'profileImageUrl': imageUrl,
      });

      authService.updateLocalProfile(
        profile.copyWith(
          fullName: fullName,
          phoneNumber: phone,
          campusId: _campusId,
          campusName: campusName,
          profileImageUrl: imageUrl,
          lastActive: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
        _pickedImage = null;
        _pickedImageBytes = null;
        _passwordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailChanged
                ? 'Profile updated. Check $newEmail to verify the new address.'
                : 'Profile updated',
          ),
        ),
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to update profile',
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleting) return;

    final confirmController = TextEditingController();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'This permanently deletes your account, shop, products, '
                  'orders, chats, and profile. '
                  'Type ${AppConstants.deleteAccountConfirmPhrase} to confirm.',
                  style: const TextStyle(height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    hintText: AppConstants.deleteAccountConfirmPhrase,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password (required)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (confirmController.text.trim() !=
                    AppConstants.deleteAccountConfirmPhrase) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Type ${AppConstants.deleteAccountConfirmPhrase} exactly to confirm',
                      ),
                    ),
                  );
                  return;
                }
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password is required')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    final password = passwordController.text;
    confirmController.dispose();
    passwordController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    try {
      await authService.deleteAccount(
        password: password,
        firestoreService: firestore,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to delete account',
      );
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    }
  }

  bool _isVendor(UserModel? profile) {
    return profile?.isVendor == true &&
        profile!.vendorId != null &&
        profile.vendorId!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profile = authService.currentUserProfile;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Sign in to view your profile'));
    }

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }

    final isVendor = _isVendor(profile);

    return SafeArea(
      child: _editing
          ? _buildEditForm(profile)
          : _buildView(profile, isVendor: isVendor),
    );
  }

  Widget _buildView(UserModel profile, {required bool isVendor}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Text(
              'Profile',
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _startEditing(profile),
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppConstants.surfaceColor,
            backgroundImage: profile.profileImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(profile.profileImageUrl)
                : null,
            child: profile.profileImageUrl.isEmpty
                ? Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isVendor ? 'Vendor' : 'Buyer',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
        ),
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phoneNumber.isEmpty ? 'Not set' : profile.phoneNumber,
        ),
        _InfoTile(
          icon: Icons.school_outlined,
          label: 'Campus',
          value: profile.campusName.isEmpty
              ? profile.campusId
              : profile.campusName,
        ),
        const SizedBox(height: 20),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: AppConstants.primaryColor,
          ),
          title: const Text('Order History'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
          },
        ),
        if (isVendor)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.storefront_outlined,
              color: AppConstants.primaryColor,
            ),
            title: const Text('Manage My Shop'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (widget.onOpenShopTab != null) {
                widget.onOpenShopTab!();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorShopScreen(vendorId: profile.vendorId!),
                ),
              );
            },
          ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _loggingOut
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout, color: AppConstants.textPrimary),
          title: const Text('Log Out'),
          onTap: _loggingOut ? null : _logout,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _deleting
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red.shade700,
                  ),
                )
              : Icon(Icons.delete_outline, color: Colors.red.shade700),
          title: Text(
            'Delete Account',
            style: TextStyle(color: Colors.red.shade700),
          ),
          onTap: _deleting ? null : _deleteAccount,
        ),
      ],
    );
  }

  Widget _buildEditForm(UserModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppConstants.surfaceColor,
                      backgroundImage: _pickedImageBytes != null
                          ? MemoryImage(_pickedImageBytes!)
                          : (profile.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  profile.profileImageUrl,
                                )
                              : null),
                      child: _pickedImageBytes == null &&
                              profile.profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.person_outline,
                              size: 40,
                              color: AppConstants.primaryColor,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to change photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Full Name'),
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (value.trim().length < 2) return 'Minimum 2 characters';
                return null;
              },
              decoration: _fieldDecoration('Your name'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Email'),
            TextFormField(
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
              decoration: _fieldDecoration('you@example.com'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Password (only if changing email)'),
            TextFormField(
              controller: _passwordController,
              enabled: !_saving,
              obscureText: true,
              decoration: _fieldDecoration('Current password'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Phone'),
            TextFormField(
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
              decoration: _fieldDecoration('e.g. 0241234567'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Campus'),
            DropdownButtonFormField<String>(
              key: ValueKey(_campusId),
              initialValue: _campusId,
              items: AppConstants.campuses
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['id'],
                      child: Text(c['name']!),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (val) => setState(() {
                        _campusId = val ?? _campusId;
                      }),
              decoration: _fieldDecoration('Select campus'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: AppConstants.authButtonHeight,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.authPillRadius),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppConstants.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
