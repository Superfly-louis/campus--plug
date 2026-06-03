import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/vendor_model.dart';
import '../services/firestore_service.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class VendorShopScreen extends StatelessWidget {
  const VendorShopScreen({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return SafeArea(
      child: FutureBuilder<VendorModel?>(
        future: firestoreService.getVendor(vendorId),
        builder: (context, vendorSnapshot) {
          final vendor = vendorSnapshot.data;
          final shopName = vendor?.businessName ?? 'My Shop';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppConstants.surfaceColor,
                      backgroundImage: vendor?.logoUrl.isNotEmpty == true
                          ? NetworkImage(vendor!.logoUrl)
                          : null,
                      child: vendor?.logoUrl.isNotEmpty == true
                          ? null
                          : const Icon(
                              Icons.storefront,
                              color: AppConstants.primaryColor,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: GoogleFonts.syne(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Your shop',
                            style: GoogleFonts.syne(
                              fontSize: 14,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddProductScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppConstants.primaryColor,
                      iconSize: 30,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: firestoreService.getProductsByVendor(vendorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: AppConstants.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products yet',
                                style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first product to start selling.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.syne(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddProductScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Add Product'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
