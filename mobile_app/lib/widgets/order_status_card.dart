import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/app_constants.dart';
import '../models/order_model.dart';

class OrderStatusCard extends StatelessWidget {
  final OrderModel order;
  final bool isVendorOwner;
  final bool isBuyer;
  final bool isUpdating;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onCancel;

  const OrderStatusCard({
    super.key,
    required this.order,
    required this.isVendorOwner,
    this.isBuyer = false,
    this.isUpdating = false,
    this.onConfirm,
    this.onDecline,
    this.onMarkCompleted,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(
      name: order.currencyCode.isNotEmpty
          ? order.currencyCode
          : AppConstants.currencyCode,
    );
    final showPendingActions =
        isVendorOwner && order.status == OrderStatus.pending && !isUpdating;
    final showCompleteAction =
        isVendorOwner && order.status == OrderStatus.confirmed && !isUpdating;
    final showBuyerCancel =
        isBuyer && order.status == OrderStatus.pending && !isUpdating;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productName,
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Qty ${order.quantity} · ${currency.format(order.totalAmount)}',
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
            ),
          ),
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              order.notes!,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (order.declineReason != null &&
              order.declineReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Declined: ${order.declineReason}',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isUpdating) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: AppConstants.primaryColor,
              minHeight: 2,
            ),
          ],
          if (showPendingActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
          if (showCompleteAction) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMarkCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark Completed'),
              ),
            ),
          ],
          if (showBuyerCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.confirmed:
        return AppConstants.secondaryColor;
      case OrderStatus.completed:
        return Colors.blueGrey;
      case OrderStatus.declined:
      case OrderStatus.cancelled:
        return Colors.red.shade700;
      default:
        return AppConstants.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        OrderStatus.label(status),
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
