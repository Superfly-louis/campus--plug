// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  id: json['id'] as String,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  participantNames: Map<String, String>.from(json['participantNames'] as Map),
  participantImages: Map<String, String>.from(json['participantImages'] as Map),
  lastMessage: json['lastMessage'] as String,
  lastMessageTime: const TimestampConverter().fromJson(
    json['lastMessageTime'] as Timestamp?,
  ),
  lastMessageSenderId: json['lastMessageSenderId'] as String,
  unreadCount: Map<String, int>.from(json['unreadCount'] as Map),
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp?,
  ),
  vendorId: json['vendorId'] as String,
  buyerId: json['buyerId'] as String,
  subject: json['subject'] as String,
  status: json['status'] as String,
  blocked: (json['blocked'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'id': instance.id,
  'participants': instance.participants,
  'participantNames': instance.participantNames,
  'participantImages': instance.participantImages,
  'lastMessage': instance.lastMessage,
  'lastMessageTime': const TimestampConverter().toJson(
    instance.lastMessageTime,
  ),
  'lastMessageSenderId': instance.lastMessageSenderId,
  'unreadCount': instance.unreadCount,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'vendorId': instance.vendorId,
  'buyerId': instance.buyerId,
  'subject': instance.subject,
  'status': instance.status,
  'blocked': instance.blocked,
};
