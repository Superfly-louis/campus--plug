// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: json['id'] as String,
  vendorId: json['vendorId'] as String,
  buyerId: json['buyerId'] as String,
  buyerName: json['buyerName'] as String?,
  chatId: json['chatId'] as String,
  rating: (json['rating'] as num).toInt(),
  text: json['text'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  verified: json['verified'] as bool,
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'buyerId': instance.buyerId,
      'buyerName': instance.buyerName,
      'chatId': instance.chatId,
      'rating': instance.rating,
      'text': instance.text,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'verified': instance.verified,
    };
