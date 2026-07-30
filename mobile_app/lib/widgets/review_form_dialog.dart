import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class ReviewFormDialog extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final ReviewModel? existingReview;

  const ReviewFormDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.existingReview,
  });

  @override
  State<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<ReviewFormDialog> {
  int _rating = 5;
  final TextEditingController _textController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _textController.text = widget.existingReview!.text ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _submitting = true);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final buyerName = authService.currentUserProfile?.fullName ?? 'Campus User';

      final reviewId = FirestoreService.reviewDocId(widget.vendorId, userId);
      final newReview = ReviewModel(
        id: reviewId,
        vendorId: widget.vendorId,
        buyerId: userId,
        buyerName: buyerName,
        chatId: widget.existingReview?.chatId ?? 'manual_review',
        rating: _rating,
        text: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
        createdAt: DateTime.now(),
        verified: widget.existingReview?.verified ?? false,
      );

      await firestoreService.createReview(newReview);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReview != null
                  ? 'Review updated successfully!'
                  : 'Review submitted successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existingReview != null
                      ? 'Edit Your Review'
                      : 'Rate ${widget.vendorName}',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final selected = starIndex <= _rating;
                    return GestureDetector(
                      onTap: _submitting
                          ? null
                          : () => setState(() => _rating = starIndex),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
                Text(
                  '$_rating / 5',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // Text field
                TextField(
                  controller: _textController,
                  maxLength: 200,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Share your experience (optional, max 200 chars)...',
                    hintStyle: GoogleFonts.syne(
                      color: AppConstants.textSecondary,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.syne(
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        // Theme defaults to full-width; override for Row layout.
                        minimumSize: const Size(88, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.existingReview != null
                                  ? 'Update'
                                  : 'Submit',
                              style: GoogleFonts.syne(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
