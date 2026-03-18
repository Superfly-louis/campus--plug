// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorModel _$VendorModelFromJson(Map<String, dynamic> json) => VendorModel(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  businessName: json['businessName'] as String,
  description: json['description'] as String,
  logoUrl: json['logoUrl'] as String,
  bannerUrl: json['bannerUrl'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  ratingAverage: (json['ratingAverage'] as num).toDouble(),
  ratingCount: (json['ratingCount'] as num).toInt(),
  isVerified: json['isVerified'] as bool,
  whatsappNumber: json['whatsappNumber'] as String,
  location: const GeoPointConverter().fromJson(json['location']),
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$VendorModelToJson(VendorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'businessName': instance.businessName,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'bannerUrl': instance.bannerUrl,
      'categories': instance.categories,
      'ratingAverage': instance.ratingAverage,
      'ratingCount': instance.ratingCount,
      'isVerified': instance.isVerified,
      'whatsappNumber': instance.whatsappNumber,
      'location': const GeoPointConverter().toJson(instance.location),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
