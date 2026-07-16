import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReviewModel {
  final String id;
  final String vendorId;
  final String buyerId;
  final String chatId;
  final int rating; // 1 to 5
  final String? text; // optional, max 200 chars
  
  @TimestampConverter()
  final DateTime createdAt;
  
  final bool verified;

  ReviewModel({
    required this.id,
    required this.vendorId,
    required this.buyerId,
    required this.chatId,
    required this.rating,
    this.text,
    required this.createdAt,
    required this.verified,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel.fromJson({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
