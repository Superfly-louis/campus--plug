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
  final String vendorId;
  final String buyerId;
  final String subject;
  final String status; // 'active' or 'closed'
  final Map<String, bool>? blocked;

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
    required this.vendorId,
    required this.buyerId,
    required this.subject,
    required this.status,
    this.blocked,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);

    sanitized['id'] = sanitized['id']?.toString() ?? '';
    sanitized['participants'] = _stringList(sanitized['participants']);
    sanitized['participantNames'] = _stringMap(sanitized['participantNames']);
    sanitized['participantImages'] = _stringMap(sanitized['participantImages']);
    sanitized['lastMessage'] = sanitized['lastMessage']?.toString() ?? '';
    sanitized['lastMessageSenderId'] =
        sanitized['lastMessageSenderId']?.toString() ?? '';
    sanitized['unreadCount'] = _intMap(sanitized['unreadCount']);
    sanitized['vendorId'] = sanitized['vendorId']?.toString() ?? '';
    sanitized['buyerId'] = sanitized['buyerId']?.toString() ?? '';
    sanitized['subject'] = sanitized['subject']?.toString() ?? 'Order Chat';
    sanitized['status'] = sanitized['status']?.toString() ?? 'active';

    // Generated converter casts to Timestamp? — null server timestamps
    // (pending writes) must become a real Timestamp before decode.
    sanitized['lastMessageTime'] = _asTimestamp(sanitized['lastMessageTime']);
    sanitized['createdAt'] = _asTimestamp(sanitized['createdAt']);

    if (sanitized['blocked'] != null) {
      sanitized['blocked'] = _boolMap(sanitized['blocked']);
    }

    return _$ChatModelFromJson(sanitized);
  }

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is! Map) {
      throw StateError('Chat document ${doc.id} has no data');
    }
    final data = Map<String, dynamic>.from(raw);
    data['id'] = data['id']?.toString() ?? doc.id;
    return ChatModel.fromJson(data);
  }

  String otherParticipantId(String currentUserId) {
    if (participants.isEmpty) return '';
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
  }

  int unreadForUser(String userId) => unreadCount[userId] ?? 0;

  static List<String> _stringList(dynamic value) {
    if (value is! List) return <String>[];
    return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return <String, String>{};
    return value.map(
      (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is! Map) return <String, int>{};
    return value.map((key, val) {
      final n = val is num ? val.toInt() : int.tryParse(val?.toString() ?? '') ?? 0;
      return MapEntry(key.toString(), n);
    });
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return <String, bool>{};
    return value.map(
      (key, val) => MapEntry(key.toString(), val == true),
    );
  }

  static Timestamp _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return Timestamp.now();
  }
}
