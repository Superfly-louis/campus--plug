// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  profileImageUrl: json['profileImageUrl'] as String,
  campusId: json['campusId'] as String,
  campusName: json['campusName'] as String,
  isVendor: json['isVendor'] as bool,
  vendorId: json['vendorId'] as String?,
  hasSelectedRole: json['hasSelectedRole'] as bool? ?? false,
  isAdmin: json['isAdmin'] as bool? ?? false,
  likedProductIds: (json['likedProductIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  lastActive: const TimestampConverter().fromJson(json['lastActive']),
  deviceToken: json['deviceToken'] as String,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'profileImageUrl': instance.profileImageUrl,
  'campusId': instance.campusId,
  'campusName': instance.campusName,
  'isVendor': instance.isVendor,
  'vendorId': instance.vendorId,
  'hasSelectedRole': instance.hasSelectedRole,
  'isAdmin': instance.isAdmin,
  'likedProductIds': instance.likedProductIds,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'lastActive': const TimestampConverter().toJson(instance.lastActive),
  'deviceToken': instance.deviceToken,
};
