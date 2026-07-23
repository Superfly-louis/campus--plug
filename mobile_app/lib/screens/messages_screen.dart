import 'package:cached_network_image/cached_network_image.dart';
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
      body: SafeArea(
        child: StreamBuilder<List<ChatModel>>(
          stream: chatService.getUserChats(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildLoadingSkeleton();
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
                try {
                  return _ChatListTile(
                    chat: chats[index],
                    currentUserId: userId,
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Could not load conversations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error details: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        indent: 76,
        color: AppConstants.borderColor,
      ),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
          ),
          title: Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
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
    final otherName = chat.participantNames[otherId] ?? 'Campus User';
    final otherImage = chat.participantImages[otherId] ?? '';
    final unread = chat.unreadForUser(currentUserId);
    final timeLabel = _formatTime(chat.lastMessageTime);
    final initial =
        otherName.trim().isNotEmpty ? otherName.trim()[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppConstants.primaryColor,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: AppConstants.surfaceColor,
          backgroundImage: otherImage.isNotEmpty
              ? CachedNetworkImageProvider(otherImage)
              : null,
          child: otherImage.isEmpty
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        otherName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
      trailing: Text(
        timeLabel,
        style: const TextStyle(
          fontSize: 12,
          color: AppConstants.textSecondary,
        ),
      ),
      onTap: () {
        openExistingChatScreen(
          context,
          chatId: chat.id,
          otherUserId: otherId,
          otherUserName: otherName,
          otherUserImage: otherImage,
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
