import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<int> watchTotalUnreadCount(String userId) {
    return getUserChats(userId).map(
      (chats) => chats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadForUser(userId),
      ),
    );
  }

  Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    required String otherUserImage,
    required String currentUserName,
    required String currentUserImage,
  }) async {
    final existing = await _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    final docRef = _db.collection(AppConstants.chatsCollection).doc();
    await docRef.set({
      'id': docRef.id,
      'participants': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      'participantImages': {
        currentUserId: currentUserImage,
        otherUserId: otherUserImage,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'unreadCount': {
        currentUserId: 0,
        otherUserId: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);
    final messagesRef = chatRef.collection(AppConstants.messagesCollection);
    final messageRef = messagesRef.doc();

    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      throw StateError('Chat not found');
    }

    final participants = List<String>.from(chatSnap['participants'] ?? []);
    final recipientId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );

    final unreadRaw = chatSnap.data()?['unreadCount'];
    final unreadCount = <String, int>{};
    if (unreadRaw is Map) {
      unreadRaw.forEach((key, value) {
        unreadCount[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }
    if (recipientId.isNotEmpty) {
      unreadCount[recipientId] = (unreadCount[recipientId] ?? 0) + 1;
    }

    final batch = _db.batch();

    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.update(chatRef, {
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount': unreadCount,
    });

    await batch.commit();
    // TODO: Send push notification to recipient via FCM deviceToken
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }
}
