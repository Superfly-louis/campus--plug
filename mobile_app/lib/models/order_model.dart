import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

/// Order lifecycle statuses (stored as string in Firestore).
class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String declined = 'declined';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    pending,
    confirmed,
    declined,
    completed,
    cancelled,
  ];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case confirmed:
        return 'Confirmed';
      case declined:
        return 'Declined';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Payment methods. v1 is COD-only; keep as string for additive v2 methods.
class OrderPaymentMethod {
  static const String cashOnDelivery = 'cash_on_delivery';
}

/// Payment status stub for v2 Paystack/Hubtel. COD defaults to not_applicable.
class OrderPaymentStatus {
  static const String notApplicable = 'not_applicable';
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String failed = 'failed';
}

@JsonSerializable(explicitToJson: true)
class OrderModel {
  /// Document id (same as Firestore `orders/{id}`). Named `id` to match
  /// ProductModel / ChatModel / ReviewModel conventions.
  final String id;
  final String chatId;

  final String productId;
  final String productName;
  final String productImage;

  final String vendorId;
  final String vendorName;

  /// Denormalized shop owner uid — needed for security rules without a get().
  final String vendorOwnerId;

  final String buyerId;
  final String buyerName;

  /// Matches products/vendors (`campusId`), not a free-form campus label.
  final String campusId;

  final int quantity;
  final double priceAtOrder;
  final double totalAmount;

  /// ISO 4217; Campus Plug is GHS-only today.
  @JsonKey(defaultValue: 'GHS')
  final String currencyCode;

  /// One of [OrderStatus.values].
  final String status;

  /// One of [OrderPaymentMethod] (v1: always cash_on_delivery).
  final String paymentMethod;

  /// One of [OrderPaymentStatus] (v1 COD: not_applicable).
  final String paymentStatus;

  /// Reserved for v2 Paystack/Hubtel reference / transaction id.
  final String? paymentReference;

  /// Buyer pickup / special instructions (COD-relevant).
  final String? notes;

  /// Optional vendor note when declining an order.
  final String? declineReason;

  @TimestampConverter()
  final DateTime createdAt;

  @TimestampConverter()
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.chatId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.vendorId,
    required this.vendorName,
    required this.vendorOwnerId,
    required this.buyerId,
    required this.buyerName,
    required this.campusId,
    required this.quantity,
    required this.priceAtOrder,
    required this.totalAmount,
    this.currencyCode = 'GHS',
    this.status = OrderStatus.pending,
    this.paymentMethod = OrderPaymentMethod.cashOnDelivery,
    this.paymentStatus = OrderPaymentStatus.notApplicable,
    this.paymentReference,
    this.notes,
    this.declineReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);

    sanitized['id'] = sanitized['id']?.toString() ?? '';
    sanitized['chatId'] = sanitized['chatId']?.toString() ?? '';
    sanitized['productId'] = sanitized['productId']?.toString() ?? '';
    sanitized['productName'] = sanitized['productName']?.toString() ?? '';
    sanitized['productImage'] = sanitized['productImage']?.toString() ?? '';
    sanitized['vendorId'] = sanitized['vendorId']?.toString() ?? '';
    sanitized['vendorName'] = sanitized['vendorName']?.toString() ?? '';
    sanitized['vendorOwnerId'] = sanitized['vendorOwnerId']?.toString() ?? '';
    sanitized['buyerId'] = sanitized['buyerId']?.toString() ?? '';
    sanitized['buyerName'] = sanitized['buyerName']?.toString() ?? '';
    sanitized['campusId'] =
        sanitized['campusId']?.toString() ??
        sanitized['campus']?.toString() ??
        '';
    sanitized['quantity'] = sanitized['quantity'] is num
        ? (sanitized['quantity'] as num).toInt()
        : int.tryParse(sanitized['quantity']?.toString() ?? '') ?? 1;
    sanitized['priceAtOrder'] = sanitized['priceAtOrder'] is num
        ? (sanitized['priceAtOrder'] as num).toDouble()
        : double.tryParse(sanitized['priceAtOrder']?.toString() ?? '') ?? 0.0;
    sanitized['totalAmount'] = sanitized['totalAmount'] is num
        ? (sanitized['totalAmount'] as num).toDouble()
        : double.tryParse(sanitized['totalAmount']?.toString() ?? '') ?? 0.0;
    sanitized['currencyCode'] =
        sanitized['currencyCode']?.toString() ?? 'GHS';
    sanitized['status'] =
        sanitized['status']?.toString() ?? OrderStatus.pending;
    sanitized['paymentMethod'] =
        sanitized['paymentMethod']?.toString() ??
        OrderPaymentMethod.cashOnDelivery;
    sanitized['paymentStatus'] =
        sanitized['paymentStatus']?.toString() ??
        OrderPaymentStatus.notApplicable;
    sanitized['createdAt'] = _asTimestamp(sanitized['createdAt']);
    sanitized['updatedAt'] = _asTimestamp(sanitized['updatedAt']);

    return _$OrderModelFromJson(sanitized);
  }

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is! Map) {
      throw StateError('Order document ${doc.id} has no data');
    }
    final data = Map<String, dynamic>.from(raw);
    data['id'] = data['id']?.toString() ?? doc.id;
    return OrderModel.fromJson(data);
  }

  static Timestamp _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return Timestamp.now();
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
