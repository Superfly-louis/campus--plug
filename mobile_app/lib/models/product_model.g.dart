// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['id'] as String,
  vendorId: json['vendorId'] as String,
  vendorName: json['vendorName'] as String,
  campusId: json['campusId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  categoryId: json['categoryId'] as String,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  status: json['status'] as String,
  condition: json['condition'] as String,
  viewCount: (json['viewCount'] as num).toInt(),
  likeCount: (json['likeCount'] as num).toInt(),
  searchKeywords: (json['searchKeywords'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'campusId': instance.campusId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'categoryId': instance.categoryId,
      'imageUrls': instance.imageUrls,
      'status': instance.status,
      'condition': instance.condition,
      'viewCount': instance.viewCount,
      'likeCount': instance.likeCount,
      'searchKeywords': instance.searchKeywords,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
