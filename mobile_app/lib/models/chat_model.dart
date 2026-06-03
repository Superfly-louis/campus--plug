import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'chat_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final String lastMessage;
  @TimestampConverter()
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCount;
  @TimestampConverter()
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantImages,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel.fromJson({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }

  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
  }

  int unreadForUser(String userId) => unreadCount[userId] ?? 0;
}
