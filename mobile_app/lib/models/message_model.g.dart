// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  text: json['text'] as String,
  timestamp: const TimestampConverter().fromJson(
    json['timestamp'] as Timestamp,
  ),
  isRead: json['isRead'] as bool,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'text': instance.text,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'isRead': instance.isRead,
    };
