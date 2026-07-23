import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/app_router.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  /// When non-null, screen operates in edit mode for this product.
  final ProductModel? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  bool get isEditing => existingProduct != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _ownershipDenied = false;
  XFile? _productImage;
  Uint8List? _productImageBytes;
  List<String> _existingImageUrls = const [];

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description;
      _priceController.text = existing.price.toStringAsFixed(
        existing.price.truncateToDouble() == existing.price ? 0 : 2,
      );
      final knownCategory = AppConstants.categories.any(
        (c) => c['id'] == existing.categoryId,
      );
      _selectedCategory = knownCategory ? existing.categoryId : null;
      _existingImageUrls = List<String>.from(existing.imageUrls);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceOwnership());
  }

  void _enforceOwnership() {
    if (!_isEditing) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final vendorId = authService.currentUserProfile?.vendorId;
    final productVendorId = widget.existingProduct!.vendorId;

    if (vendorId == null ||
        vendorId.isEmpty ||
        vendorId != productVendorId) {
      setState(() => _ownershipDenied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit products from your own shop.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
                _isEditing ? 'Edit Product' : 'Add Your Products',
                style: const TextStyle(
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
              _buildLabel('Product Price (${AppConstants.currencyCode})'),
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
                  child: _buildImagePreview(),
                ),
              ),
              if (!_isEditing) ...[
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
              ],
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
                      : Text(
                          _isEditing ? 'Save Changes' : 'Finish & Go to Shop',
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

  Widget _buildImagePreview() {
    if (_productImageBytes != null) {
      return Image.memory(
        _productImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (_existingImageUrls.isNotEmpty) {
      return Image.network(
        _existingImageUrls.first,
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
          size: 44,
          color: AppConstants.primaryColor,
        ),
        SizedBox(height: 8),
        Text(
          'Tap to upload image',
          style: TextStyle(color: AppConstants.primaryColor),
        ),
      ],
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
    if (_isLoading) return;
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

    if (_isEditing && vendorId != widget.existingProduct!.vendorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit products from your own shop.'),
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

      List<String>? imageUrls;
      if (_productImage != null) {
        final ext = _productImage!.name.split('.').last;
        final uploaded = await storageService.tryUploadImage(
          storagePath:
              'vendors/$vendorId/products/${DateTime.now().millisecondsSinceEpoch}.$ext',
          file: _productImage!,
        );
        if (uploaded != null) {
          imageUrls = [uploaded];
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Image upload skipped — keeping the existing photo.'
                    : 'Image upload skipped — product saved without photo.',
              ),
            ),
          );
        }
      }

      final name = _nameController.text.trim();
      final categoryId = _selectedCategory!;
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0;

      if (_isEditing) {
        await firestoreService.updateProduct(
          productId: widget.existingProduct!.id,
          expectedVendorId: vendorId,
          name: name,
          categoryId: categoryId,
          description: description,
          price: price,
          imageUrls: imageUrls,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      await firestoreService.addProduct(
        vendorId: vendorId,
        name: name,
        categoryId: categoryId,
        description: description,
        price: price,
        campusId: user!.campusId,
        imageUrls: imageUrls ?? const [],
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
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Could not update product: $e'
                  : 'Could not save product: $e',
            ),
          ),
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
