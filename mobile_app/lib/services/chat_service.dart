import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String buildChatDocId(String userIdA, String userIdB) {
    final ids = [userIdA, userIdB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        // Sorting is done locally to avoid needing a Firestore composite index
        .snapshots()
        .map((snapshot) {
      final chats = <ChatModel>[];
      for (final doc in snapshot.docs) {
        try {
          chats.add(ChatModel.fromFirestore(doc));
        } catch (_) {
          // Skip malformed / partially-written chat docs.
        }
      }
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
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
    required String vendorId,
    required String subject,
  }) async {
    final chatDocId = ChatService.buildChatDocId(currentUserId, otherUserId);
    final docRef = _db.collection(AppConstants.chatsCollection).doc(chatDocId);
    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      final data = existingDoc.data() ?? {};
      if (data['vendorId'] == null || data['status'] == null) {
        await docRef.update({
          'vendorId': vendorId,
          'buyerId': currentUserId,
          'subject': subject,
          'status': data['status'] ?? 'active',
        });
      }
      return chatDocId;
    }

    final legacyChatId = await _findLegacyChatId(currentUserId, otherUserId);
    if (legacyChatId != null) {
      return legacyChatId;
    }

    await docRef.set({
      'id': chatDocId,
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
      'vendorId': vendorId,
      'buyerId': currentUserId,
      'subject': subject,
      'status': 'active',
      'blocked': <String, bool>{},
    });

    return chatDocId;
  }

  Future<String?> _findLegacyChatId(
    String currentUserId,
    String otherUserId,
  ) async {
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
    return null;
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MessageModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<MessageModel>()
          .toList();
    });
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

    final buyerId = chatSnap.data()?['buyerId'] as String? ?? '';
    final senderType = senderId == buyerId ? 'buyer' : 'vendor';

    final batch = _db.batch();

    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'chatId': chatId,
      'senderType': senderType,
      'readAt': null,
    });

    final lastMessagePreview = trimmed.length > 50 ? '${trimmed.substring(0, 47)}...' : trimmed;

    batch.update(chatRef, {
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount': unreadCount,
    });

    // Await commit so callers can surface failures; Firestore offline persistence
    // still queues writes locally when the device has no connectivity.
    await batch.commit();
    // TODO: Send push notification to recipient via FCM deviceToken
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'unreadCount.$userId': 0,
    });

    // Also mark messages in the subcollection as read
    final messagesQuery = await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    if (messagesQuery.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<void> closeChat(String chatId) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'status': 'closed',
    });
  }

  Future<void> toggleBlock(String chatId, String userId, bool block) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'blocked.$userId': block,
    });
  }

  Stream<ChatModel?> watchChat(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          try {
            return ChatModel.fromFirestore(doc);
          } catch (e) {
            return null;
          }
        });
  }
}
