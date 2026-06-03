import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final String campusId;
  final String campusName;
  final bool isVendor;
  final String? vendorId;
  @JsonKey(defaultValue: false)
  final bool hasSelectedRole;
  
  @TimestampConverter()
  final DateTime createdAt;
  
  @TimestampConverter()
  final DateTime lastActive;
  
  final String deviceToken;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.campusId,
    required this.campusName,
    required this.isVendor,
    this.vendorId,
    this.hasSelectedRole = false,
    required this.createdAt,
    required this.lastActive,
    required this.deviceToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? campusId,
    String? campusName,
    bool? isVendor,
    String? vendorId,
    bool? hasSelectedRole,
    DateTime? lastActive,
    String? deviceToken,
  }) {
    return UserModel(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      campusId: campusId ?? this.campusId,
      campusName: campusName ?? this.campusName,
      isVendor: isVendor ?? this.isVendor,
      vendorId: vendorId ?? this.vendorId,
      hasSelectedRole: hasSelectedRole ?? this.hasSelectedRole,
      createdAt: this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }

  // Helper for Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
