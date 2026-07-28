// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  chatId: json['chatId'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  productImage: json['productImage'] as String,
  vendorId: json['vendorId'] as String,
  vendorName: json['vendorName'] as String,
  vendorOwnerId: json['vendorOwnerId'] as String,
  buyerId: json['buyerId'] as String,
  buyerName: json['buyerName'] as String,
  campusId: json['campusId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  priceAtOrder: (json['priceAtOrder'] as num).toDouble(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  currencyCode: json['currencyCode'] as String? ?? 'GHS',
  status: json['status'] as String? ?? OrderStatus.pending,
  paymentMethod:
      json['paymentMethod'] as String? ?? OrderPaymentMethod.cashOnDelivery,
  paymentStatus:
      json['paymentStatus'] as String? ?? OrderPaymentStatus.notApplicable,
  paymentReference: json['paymentReference'] as String?,
  notes: json['notes'] as String?,
  declineReason: json['declineReason'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  updatedAt: const TimestampConverter().fromJson(
    json['updatedAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'productId': instance.productId,
      'productName': instance.productName,
      'productImage': instance.productImage,
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'vendorOwnerId': instance.vendorOwnerId,
      'buyerId': instance.buyerId,
      'buyerName': instance.buyerName,
      'campusId': instance.campusId,
      'quantity': instance.quantity,
      'priceAtOrder': instance.priceAtOrder,
      'totalAmount': instance.totalAmount,
      'currencyCode': instance.currencyCode,
      'status': instance.status,
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'paymentReference': instance.paymentReference,
      'notes': instance.notes,
      'declineReason': instance.declineReason,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
