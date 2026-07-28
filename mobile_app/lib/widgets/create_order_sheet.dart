import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';

/// Buyer-facing sheet to confirm quantity/notes and create a COD order.
Future<bool> showCreateOrderSheet(
  BuildContext context, {
  required String chatId,
  required String buyerId,
  required String buyerName,
  required String vendorId,
  String? initialProductId,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppConstants.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateOrderSheet(
          chatId: chatId,
          buyerId: buyerId,
          buyerName: buyerName,
          vendorId: vendorId,
          initialProductId: initialProductId,
        ),
      );
    },
  );
  return created == true;
}

class _CreateOrderSheet extends StatefulWidget {
  final String chatId;
  final String buyerId;
  final String buyerName;
  final String vendorId;
  final String? initialProductId;

  const _CreateOrderSheet({
    required this.chatId,
    required this.buyerId,
    required this.buyerName,
    required this.vendorId,
    this.initialProductId,
  });

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final _notesController = TextEditingController();
  final _currency = NumberFormat.simpleCurrency(
    name: AppConstants.currencyCode,
  );

  List<ProductModel> _products = [];
  ProductModel? _selected;
  int _quantity = 1;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    try {
      if (widget.initialProductId != null &&
          widget.initialProductId!.isNotEmpty) {
        final product = await firestore.getProduct(widget.initialProductId!);
        if (!mounted) return;
        setState(() {
          _products = product != null ? [product] : [];
          _selected = product;
          _loading = false;
          if (product == null) {
            _error = 'Product is no longer available';
          }
        });
        return;
      }

      final products = await firestore
          .getProductsByVendor(widget.vendorId)
          .first;
      if (!mounted) return;
      final available = products
          .where((p) => p.status == 'available')
          .toList();
      setState(() {
        _products = available;
        _selected = available.isNotEmpty ? available.first : null;
        _loading = false;
        if (available.isEmpty) {
          _error = 'No available products for this shop';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load products: $e';
      });
    }
  }

  double get _total {
    final price = _selected?.price ?? 0;
    return price * _quantity;
  }

  Future<void> _submit() async {
    final product = _selected;
    if (product == null || _submitting) return;
    if (_quantity < 1) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    try {
      final vendor = await firestore.getVendor(widget.vendorId);
      final vendorOwnerId = vendor?.ownerId ??
          await firestore.getVendorOwnerId(widget.vendorId) ??
          '';
      if (vendorOwnerId.isEmpty) {
        throw StateError('Seller account not found');
      }

      final image = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';
      final now = DateTime.now();
      final notes = _notesController.text.trim();

      await firestore.createOrder(
        OrderModel(
          id: '',
          chatId: widget.chatId,
          productId: product.id,
          productName: product.name,
          productImage: image,
          vendorId: widget.vendorId,
          vendorName: vendor?.businessName ?? product.vendorName,
          vendorOwnerId: vendorOwnerId,
          buyerId: widget.buyerId,
          buyerName: widget.buyerName,
          campusId: product.campusId,
          quantity: _quantity,
          priceAtOrder: product.price,
          totalAmount: _total,
          currencyCode: AppConstants.currencyCode,
          status: OrderStatus.pending,
          paymentMethod: OrderPaymentMethod.cashOnDelivery,
          paymentStatus: OrderPaymentStatus.notApplicable,
          notes: notes.isEmpty ? null : notes,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final totalLabel = _currency.format(_total);
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.buyerId,
        senderName: widget.buyerName,
        text:
            'Order placed: ${product.name} × $_quantity · $totalLabel (${OrderStatus.label(OrderStatus.pending)})',
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create order: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Order',
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cash on delivery · ${AppConstants.currencyCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                ),
              )
            else ...[
              if (_products.length > 1) ...[
                Text(
                  'Product',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductModel>(
                  key: ValueKey(_selected?.id ?? 'none'),
                  initialValue: _selected,
                  items: _products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} · ${_currency.format(p.price)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() {
                            _selected = value;
                            _quantity = 1;
                          }),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_selected != null) ...[
                Text(
                  _selected!.name,
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currency.format(_selected!.price),
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Quantity',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _submitting || _quantity <= 1
                        ? null
                        : () => setState(() => _quantity--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Notes / pickup details (optional)',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g. Meet at gate B after 5pm',
                  filled: true,
                  fillColor: AppConstants.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _currency.format(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: AppConstants.authButtonHeight,
                child: ElevatedButton(
                  onPressed: (_selected == null || _submitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.authPillRadius,
                      ),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
