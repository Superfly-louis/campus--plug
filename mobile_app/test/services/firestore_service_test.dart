import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/firestore_service.dart';

void main() {
  group('FirestoreService.reviewDocId', () {
    test('uses vendor and buyer ids for deterministic upsert key', () {
      expect(
        FirestoreService.reviewDocId('vendor_123', 'buyer_456'),
        'vendor_123_buyer_456',
      );
    });

    test('prevents duplicate reviews for same buyer on same vendor', () {
      final first = FirestoreService.reviewDocId('v1', 'b1');
      final second = FirestoreService.reviewDocId('v1', 'b1');
      expect(first, second);
    });
  });
}
