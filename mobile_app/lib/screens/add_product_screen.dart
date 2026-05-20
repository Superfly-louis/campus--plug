import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

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
                onTap: () {
                  // TODO: implement image picker
                },
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
                  child: const Column(
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
              const SizedBox(height: 16),
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

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _priceController.text.trim().isEmpty) {
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
      final user = authService.currentUserProfile;
      if (user == null) return;

      await firestoreService.addProduct(
        vendorId: user.vendorId ?? user.id,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        campusId: user.campusId,
        imageUrl: '',
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
