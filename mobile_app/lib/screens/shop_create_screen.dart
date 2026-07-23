import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../core/auth_errors.dart';
import '../models/vendor_model.dart';
import 'add_product_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ShopCreateScreen extends StatefulWidget {
  /// When non-null, screen operates in edit mode for this vendor.
  final VendorModel? existingVendor;

  const ShopCreateScreen({super.key, this.existingVendor});

  bool get isEditing => existingVendor != null;

  @override
  State<ShopCreateScreen> createState() => _ShopCreateScreenState();
}

class _ShopCreateScreenState extends State<ShopCreateScreen> {
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();
  String? _selectedCategory;
  String _selectedCampusId = AppConstants.campuses[0]['id']!;
  bool _isLoading = false;
  bool _ownershipDenied = false;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  String _existingLogoUrl = '';

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingVendor;
    if (existing != null) {
      _shopNameController.text = existing.businessName;
      _descriptionController.text = existing.description;
      _whatsappController.text = existing.whatsappNumber;
      _existingLogoUrl = existing.logoUrl;

      final categoryId = existing.category ??
          (existing.categories.isNotEmpty ? existing.categories.first : null);
      final knownCategory = categoryId != null &&
          AppConstants.categories.any((c) => c['id'] == categoryId);
      _selectedCategory = knownCategory ? categoryId : null;

      final knownCampus = AppConstants.campuses.any(
        (c) => c['id'] == existing.campusId,
      );
      _selectedCampusId =
          knownCampus ? existing.campusId : AppConstants.defaultCampusId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceOwnership());
  }

  void _enforceOwnership() {
    if (!_isEditing) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = widget.existingVendor!.ownerId;
    final profileVendorId =
        Provider.of<AuthService>(context, listen: false).currentUserProfile?.vendorId;

    if (uid == null ||
        uid != ownerId ||
        profileVendorId != widget.existingVendor!.id) {
      setState(() => _ownershipDenied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own shop.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ownershipDenied) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Your Shop' : 'Create Your Shop',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Shop Name'),
              _buildTextField(_shopNameController, 'Enter your shop name'),
              const SizedBox(height: 20),
              _buildLabel('Category'),
              _buildDropdown(
                value: _selectedCategory,
                hint: 'Select category',
                items: AppConstants.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text('${c['icon']} ${c['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 20),
              _buildLabel('Shop Description'),
              _buildTextField(
                _descriptionController,
                'Describe your shop',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildLabel('Campus'),
              _buildDropdown(
                value: _selectedCampusId,
                hint: 'Select campus',
                items: AppConstants.campuses
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'],
                        child: Text(c['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(
                  () => _selectedCampusId = val ?? _selectedCampusId,
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                _buildLabel('WhatsApp Number'),
                _buildTextField(
                  _whatsappController,
                  'e.g. 0241234567',
                  type: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 20),
              _buildLabel('Profile Photo'),
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.primaryColor),
                    borderRadius: BorderRadius.circular(15),
                    color: AppConstants.surfaceColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildLogoPreview(),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'Save Changes' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    if (_profileImageBytes != null) {
      return Image.memory(
        _profileImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (_existingLogoUrl.isNotEmpty) {
      return Image.network(
        _existingLogoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _uploadPlaceholder(),
      );
    }
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.upload_rounded,
          size: 40,
          color: AppConstants.primaryColor,
        ),
        SizedBox(height: 8),
        Text(
          'Upload Photo',
          style: TextStyle(color: AppConstants.primaryColor),
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final picked = await storageService.pickImageFromGallery();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _profileImage = picked;
        _profileImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _handleNext() async {
    if (_isLoading) return;

    final needsPhoto = !_isEditing && _profileImage == null;
    if (_shopNameController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _descriptionController.text.trim().isEmpty ||
        needsPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Please provide a shop name, category, and description'
                : 'Please provide a shop name, category, description, and profile photo',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final user = authService.currentUserProfile;
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (user == null || uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in again')),
          );
        }
        return;
      }

      if (_isEditing) {
        final existing = widget.existingVendor!;
        if (existing.ownerId != uid || user.vendorId != existing.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only edit your own shop.')),
          );
          return;
        }

        String? logoUrl;
        if (_profileImage != null) {
          final ext = _profileImage!.name.split('.').last;
          final uploaded = await storageService.tryUploadImage(
            storagePath:
                'users/${user.id}/shop_logo_${DateTime.now().millisecondsSinceEpoch}.$ext',
            file: _profileImage!,
          );
          if (uploaded != null) {
            logoUrl = uploaded;
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Photo upload skipped — keeping the existing shop image.',
                ),
              ),
            );
          }
        }

        await firestoreService.updateVendor(
          vendorId: existing.id,
          expectedOwnerId: uid,
          shopName: _shopNameController.text.trim(),
          category: _selectedCategory!,
          description: _descriptionController.text.trim(),
          campusId: _selectedCampusId,
          whatsappNumber: _whatsappController.text.trim(),
          logoUrl: logoUrl,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      var logoUrl = '';
      if (_profileImage != null) {
        final ext = _profileImage!.name.split('.').last;
        final uploaded = await storageService.tryUploadImage(
          storagePath:
              'users/${user.id}/shop_logo_${DateTime.now().millisecondsSinceEpoch}.$ext',
          file: _profileImage!,
        );
        if (uploaded != null) {
          logoUrl = uploaded;
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo upload skipped — continuing without shop image.',
              ),
            ),
          );
        }
      }

      final vendorId = await firestoreService.createVendor(
        userId: user.id,
        shopName: _shopNameController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        campusId: _selectedCampusId,
        logoUrl: logoUrl,
      );

      authService.updateLocalProfile(
        user.copyWith(isVendor: true, vendorId: vendorId),
      );
      await authService.reloadProfile();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        );
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: _isEditing ? 'Failed to update shop' : 'Failed to create shop',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAuthError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.primaryColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppConstants.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppConstants.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
      ),
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
    );
  }
}
