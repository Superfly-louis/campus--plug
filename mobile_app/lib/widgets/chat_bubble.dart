import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_constants.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isPending;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? AppConstants.primaryColor
                  : AppConstants.surfaceColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppConstants.textPrimary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (isPending) {
      return const Icon(
        Icons.access_time_rounded,
        size: 12,
        color: AppConstants.textSecondary,
      );
    }
    if (message.isRead) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Colors.blue,
      );
    }
    return const Icon(
      Icons.done_rounded,
      size: 14,
      color: AppConstants.textSecondary,
    );
  }
}

