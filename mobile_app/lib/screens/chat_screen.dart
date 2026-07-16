import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await Provider.of<ChatService>(context, listen: false)
          .markAsRead(widget.chatId, userId);
    } catch (_) {
      // Non-blocking; list will still show unread until retry
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final userId = _userId;
    if (userId == null || _sending) return;

    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    setState(() => _sending = true);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderName =
        authService.currentUserProfile?.fullName ?? 'Campus User';

    try {
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: userId,
        senderName: senderName,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final userId = _userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to chat')),
      );
    }

    return StreamBuilder<ChatModel>(
      stream: chatService.watchChat(widget.chatId),
      builder: (context, chatSnapshot) {
        final chat = chatSnapshot.data;
        final isClosed = chat?.status == 'closed';
        final isIBlocked = chat?.blocked != null && chat!.blocked![userId] == true;
        final isOtherBlocked = chat?.blocked != null && chat!.blocked![widget.otherUserId] == true;
        final isDisabled = isClosed || isIBlocked || isOtherBlocked;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppConstants.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppConstants.surfaceColor,
                      backgroundImage: widget.otherUserImage.isNotEmpty
                          ? NetworkImage(widget.otherUserImage)
                          : null,
                      child: widget.otherUserImage.isEmpty
                          ? Text(
                              widget.otherUserName.isNotEmpty
                                  ? widget.otherUserName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isClosed ? Colors.grey : AppConstants.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.backgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isClosed ? 'Closed' : 'Active',
                        style: TextStyle(
                          color: isClosed ? Colors.grey : AppConstants.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (chat != null)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppConstants.textPrimary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_block',
                      child: Text(isOtherBlocked ? 'Unblock User' : 'Block User'),
                    ),
                    if (chat.vendorId.isNotEmpty && !isClosed)
                      const PopupMenuItem(
                        value: 'close_chat',
                        child: Text('Close Chat'),
                      ),
                  ],
                  onSelected: (value) async {
                    if (value == 'toggle_block') {
                      await chatService.toggleBlock(widget.chatId, widget.otherUserId, !isOtherBlocked);
                      _showSnackbar(isOtherBlocked ? 'User unblocked' : 'User blocked');
                    } else if (value == 'close_chat') {
                      await chatService.closeChat(widget.chatId);
                      _showSnackbar('Chat closed');
                    }
                  },
                ),
            ],
          ),
          body: StreamBuilder<List<MessageModel>>(
            stream: chatService.getMessages(widget.chatId),
            builder: (context, snapshot) {
              final isOffline = false; // snapshot.metadata.isFromCache not available on AsyncSnapshot
              final messages = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting && messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                );
              }

              if (messages.isNotEmpty) {
                _scrollToBottom();
              }

              return Column(
                children: [
                  // Connection Offline Banner
                  if (isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Center(
                        child: Text(
                          'Offline — displaying cached messages',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  
                  // Messages list
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Say hello to start the conversation',
                              style: TextStyle(color: AppConstants.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMyMessage = message.senderId == userId;
                              // Determine if message is pending sync (local queue)
                              final isPending = isMyMessage && !message.isRead && isOffline;
                              return ChatBubble(
                                message: message,
                                isMe: isMyMessage,
                                isPending: isPending,
                              );
                            },
                          ),
                  ),

                  // Closed or Blocked Banners or Input Bar
                  if (isClosed)
                    _buildDisabledBanner('Vendor closed this chat')
                  else if (isIBlocked)
                    _buildDisabledBanner('You are blocked from sending messages')
                  else if (isOtherBlocked)
                    _buildDisabledBanner('You blocked this user')
                  else
                    _buildInputBar(isDisabled),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDisabledBanner(String text) {
    return Container(
      width: double.infinity,
      color: AppConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.syne(
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildInputBar(bool isDisabled) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
          color: AppConstants.backgroundColor,
          border: Border(
            top: BorderSide(color: AppConstants.borderColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isDisabled,
                decoration: InputDecoration(
                  hintText: isDisabled ? 'Chat is disabled' : 'Type a message...',
                  filled: true,
                  fillColor: AppConstants.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => isDisabled ? null : _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: isDisabled ? Colors.grey : AppConstants.primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: (isDisabled || _sending) ? null : _sendMessage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
