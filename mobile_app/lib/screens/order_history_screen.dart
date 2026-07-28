import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_constants.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../widgets/order_status_card.dart';

/// Buyer (and vendor-as-buyer) order history.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order History',
          style: GoogleFonts.syne(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to view orders'))
          : StreamBuilder<List<OrderModel>>(
              stream: firestore.getOrdersByBuyer(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No orders yet.\nCreate one from a chat with a seller.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderStatusCard(
                      order: order,
                      isVendorOwner: false,
                      isBuyer: false,
                    );
                  },
                );
              },
            ),
    );
  }
}
