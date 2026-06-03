import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'message_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  @TimestampConverter()
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }
}
