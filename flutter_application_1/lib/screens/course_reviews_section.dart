import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../providers/auth_provider.dart';
import '../services/feedback_service.dart';

class CourseReviewsSection extends StatefulWidget {
  final int courseId;
  final bool isEnrolled;

  const CourseReviewsSection({
    super.key,
    required this.courseId,
    required this.isEnrolled,
  });

  @override
  State<CourseReviewsSection> createState() => _CourseReviewsSectionState();
}

class _CourseReviewsSectionState extends State<CourseReviewsSection> {
  List<FeedbackModel> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  bool _hasUserReview = false;

  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _bgLight = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final reviews = await FeedbackService.getCourseFeedbacks(widget.courseId);
    final rating = await FeedbackService.getAverageRating(widget.courseId);
    
    bool hasReview = false;
    if (authProvider.currentUser != null) {
      hasReview = await FeedbackService.hasUserFeedback(
        authProvider.currentUser!.id!,
        widget.courseId,
      );
    }

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _averageRating = rating;
        _hasUserReview = hasReview;
        _isLoading = false;
      });
    }
  }

  void _showAddReviewDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    final commentController = TextEditingController();
    double selectedRating = 5.0;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Оставить отзыв', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedRating = index + 1.0),
                        icon: Icon(
                          index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFEAB308),
                          size: 36,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Комментарий', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: GoogleFonts.roboto(fontSize: 14, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Поделитесь впечатлениями о курсе...',
                    hintStyle: GoogleFonts.roboto(color: _textGrey, fontSize: 14),
                    filled: true,
                    fillColor: _bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(context),
              child: Text('Отмена', style: GoogleFonts.roboto(color: _textGrey)),
            ),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: isSending ? null : () async {
                  setDialogState(() => isSending = true);
                  final rating = selectedRating;
                  final description = commentController.text.trim();
                  final success = await FeedbackService.addFeedback(
                    userId: authProvider.currentUser!.id!,
                    courseId: widget.courseId,
                    rating: rating,
                    description: description,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      final currentCount = _reviews.length;
                      final newReview = FeedbackModel(
                        id: 0,
                        userId: authProvider.currentUser!.id!,
                        courseId: widget.courseId,
                        estimation: rating,
                        description: description,
                        status: true,
                        userName: authProvider.currentUser?.name,
                        userEmail: authProvider.currentUser?.email,
                      );
                      setState(() {
                        _reviews.insert(0, newReview);
                        _hasUserReview = true;
                        _averageRating = currentCount == 0
                            ? rating
                            : ((_averageRating * currentCount) + rating) / (currentCount + 1);
                      });
                      _loadReviews();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Спасибо за отзыв!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Отправить', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) return 'Сегодня';
      if (diff.inDays == 1) return 'Вчера';
      if (diff.inDays < 7) return '${diff.inDays} дн. назад';
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: _primaryPurple)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Отзывы', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
              if (widget.isEnrolled && !_hasUserReview)
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.edit_rounded, size: 18, color: _primaryPurple),
                  label: Text('Оставить отзыв', style: GoogleFonts.roboto(color: _primaryPurple, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_reviews.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.bold, color: _primaryPurple),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _averageRating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFEAB308),
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text('${_reviews.length} отзывов', style: GoogleFonts.roboto(color: _textGrey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: _textGrey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('Пока нет отзывов', style: GoogleFonts.roboto(color: _textGrey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Будьте первым!', style: GoogleFonts.roboto(color: _primaryPurple, fontSize: 13)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final rating = review.estimation ?? 0.0;
                final description = review.description ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _bgLight, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryPurple, Color(0xFFF2C9D4)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                review.initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.displayName, style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 14, color: _textDark)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: const Color(0xFFEAB308),
                                        size: 14,
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(description, style: GoogleFonts.roboto(fontSize: 14, color: _textDark, height: 1.4)),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}