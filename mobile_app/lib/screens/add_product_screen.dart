import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/app_router.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  XFile? _productImage;
  Uint8List? _productImageBytes;

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
                'Add Your Products',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Product Name'),
              _buildTextField(_nameController, 'Enter product name'),
              const SizedBox(height: 20),
              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _dropdownDecoration(),
                hint: const Text('Select category'),
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
              _buildLabel('Product Description'),
              _buildTextField(
                _descriptionController,
                'Describe your product',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildLabel('Product Price (GHS)'),
              _buildTextField(
                _priceController,
                'e.g. 50.00',
                type: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildLabel('Upload Image'),
              GestureDetector(
                onTap: _pickProductImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    color: AppConstants.surfaceColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _productImageBytes != null
                      ? Image.memory(
                          _productImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_rounded,
                              size: 44,
                              color: AppConstants.primaryColor,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload image',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: add more products to queue
                },
                icon: const Icon(Icons.add, color: AppConstants.primaryColor),
                label: const Text(
                  'Add More Products',
                  style: TextStyle(color: AppConstants.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppConstants.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _skipToShop,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppConstants.textSecondary),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Finish & Go to Shop',
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

  Future<void> _skipToShop() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.reloadProfile();
    if (!mounted) return;
    AppRouter.go(
      context,
      authService.currentUserProfile,
      homeTab: 2,
    );
  }

  Future<void> _pickProductImage() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final picked = await storageService.pickImageFromGallery();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _productImage = picked;
        _productImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserProfile;
    final vendorId = user?.vendorId;

    if (vendorId == null || vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop not found. Please create your shop again.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      final imageUrls = <String>[];
      if (_productImage != null) {
        final ext = _productImage!.name.split('.').last;
        final uploaded = await storageService.tryUploadImage(
          storagePath:
              'vendors/$vendorId/products/${DateTime.now().millisecondsSinceEpoch}.$ext',
          file: _productImage!,
        );
        if (uploaded != null) {
          imageUrls.add(uploaded);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image upload skipped — product saved without photo.',
              ),
            ),
          );
        }
      }

      await firestoreService.addProduct(
        vendorId: vendorId,
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!,
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        campusId: user!.campusId,
        imageUrls: imageUrls,
      );

      await authService.reloadProfile();
      if (!mounted) return;

      AppRouter.go(
        context,
        authService.currentUserProfile,
        homeTab: 2,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) => Padding(
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

  Widget _buildTextField(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
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

  InputDecoration _dropdownDecoration() => InputDecoration(
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
  );
}
