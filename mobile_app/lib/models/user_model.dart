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
    required this.createdAt,
    required this.lastActive,
    required this.deviceToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

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
