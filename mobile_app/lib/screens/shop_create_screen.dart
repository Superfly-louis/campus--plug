import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'add_product_screen.dart';

class ShopCreateScreen extends StatefulWidget {
  const ShopCreateScreen({super.key});

  @override
  State<ShopCreateScreen> createState() => _ShopCreateScreenState();
}

class _ShopCreateScreenState extends State<ShopCreateScreen> {
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _selectedCampusId = AppConstants.campuses[0]['id']!;
  bool _isLoading = false;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Your Shop',
                style: TextStyle(
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
                  child: _profileImageBytes != null
                      ? Image.memory(
                          _profileImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : const Column(
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
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
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
                      : const Text(
                          'Next',
                          style: TextStyle(
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
    if (_shopNameController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
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
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in again')),
          );
        }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create shop: $e')),
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
