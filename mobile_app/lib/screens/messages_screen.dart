import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final userId = _userId;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Text(
            'Sign in to view your messages',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatService.getUserChats(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load conversations',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            );
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 76,
              color: AppConstants.borderColor,
            ),
            itemBuilder: (context, index) {
              return _ChatListTile(
                chat: chats[index],
                currentUserId: userId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: AppConstants.primaryColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Message a seller from a product page to start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatListTile({
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = chat.otherParticipantId(currentUserId);
    final otherName =
        chat.participantNames[otherId] ?? 'Campus User';
    final otherImage = chat.participantImages[otherId] ?? '';
    final unread = chat.unreadForUser(currentUserId);
    final timeLabel = _formatTime(chat.lastMessageTime);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppConstants.surfaceColor,
        backgroundImage:
            otherImage.isNotEmpty ? NetworkImage(otherImage) : null,
        child: otherImage.isEmpty
            ? Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              )
            : null,
      ),
      title: Text(
        otherName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'Start a conversation' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppConstants.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Center(
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              otherUserId: otherId,
              otherUserName: otherName,
              otherUserImage: otherImage,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    }
    if (now.difference(time).inDays < 7) {
      return DateFormat('EEE').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}
