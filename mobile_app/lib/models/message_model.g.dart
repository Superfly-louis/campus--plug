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
  timestamp: const SafeTimestampConverter().fromJson(json['timestamp']),
  isRead: json['isRead'] as bool,
  chatId: json['chatId'] as String,
  senderType: json['senderType'] as String,
  readAt: const TimestampConverterNullable().fromJson(
    json['readAt'] as Timestamp?,
  ),
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'text': instance.text,
      'timestamp': const SafeTimestampConverter().toJson(instance.timestamp),
      'isRead': instance.isRead,
      'chatId': instance.chatId,
      'senderType': instance.senderType,
      'readAt': const TimestampConverterNullable().toJson(instance.readAt),
    };
