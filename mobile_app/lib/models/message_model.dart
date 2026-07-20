import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  
  @SafeTimestampConverter()
  final DateTime timestamp;
  final bool isRead;
  final String chatId;
  final String senderType; // 'vendor' or 'buyer'
  
  @TimestampConverterNullable()
  final DateTime? readAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isPending;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.chatId,
    required this.senderType,
    this.readAt,
    this.isPending = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    if (json['chatId'] == null) {
      json['chatId'] = '';
    }
    if (json['senderType'] == null) {
      json['senderType'] = 'buyer'; // default fallback
    }
    return _$MessageModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final isPending = doc.metadata.hasPendingWrites;
    return MessageModel.fromJson({
      ...data,
      'id': data['id'] ?? doc.id,
    }).copyWith(isPending: isPending);
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? chatId,
    String? senderType,
    DateTime? readAt,
    bool? isPending,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      chatId: chatId ?? this.chatId,
      senderType: senderType ?? this.senderType,
      readAt: readAt ?? this.readAt,
      isPending: isPending ?? this.isPending,
    );
  }
}

class TimestampConverterNullable implements JsonConverter<DateTime?, Timestamp?> {
  const TimestampConverterNullable();

  @override
  DateTime? fromJson(Timestamp? timestamp) => timestamp?.toDate();

  @override
  Timestamp? toJson(DateTime? date) => date != null ? Timestamp.fromDate(date) : null;
}

class SafeTimestampConverter implements JsonConverter<DateTime, dynamic> {
  const SafeTimestampConverter();

  @override
  DateTime fromJson(dynamic val) {
    if (val is Timestamp) {
      return val.toDate();
    }
    return DateTime.now();
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}


