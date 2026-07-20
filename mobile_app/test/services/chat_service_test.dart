import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/chat_service.dart';

void main() {
  group('ChatService.buildChatDocId', () {
    test('returns stable id regardless of argument order', () {
      expect(
        ChatService.buildChatDocId('user_a', 'user_b'),
        ChatService.buildChatDocId('user_b', 'user_a'),
      );
    });

    test('sorts participant ids lexicographically', () {
      expect(ChatService.buildChatDocId('zzz', 'aaa'), 'aaa_zzz');
    });

    test('handles identical ordering for same user pair', () {
      expect(ChatService.buildChatDocId('u1', 'u2'), 'u1_u2');
    });
  });
}
