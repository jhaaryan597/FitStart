import 'package:flutter/material.dart';
import 'package:FitStart/model/review.dart';
import 'package:FitStart/services/review_service.dart';
import 'package:FitStart/theme.dart';
import 'package:intl/intl.dart';

class ReviewsSection extends StatefulWidget {
  final String venueId;
  final String venueType;
  final String venueName;

  const ReviewsSection({
    Key? key,
    required this.venueId,
    required this.venueType,
    required this.venueName,
  }) : super(key: key);

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  List<Review> _reviews = [];
  ReviewSummary? _summary;
  bool _isLoading = true;
  bool _showAllReviews = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final result = await ReviewService.getReviews(
      venueId: widget.venueId,
      venueType: widget.venueType,
    );

    if (result['success'] && mounted) {
      setState(() {
        _reviews = List<Review>.from(result['data']);
        _summary = result['summary'] as ReviewSummary;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddReviewDialog() {
    double rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Write a Review',
                      style: titleTextStyle,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your experience at ${widget.venueName}',
                  style: descTextStyle,
                ),
                const SizedBox(height: 24),
                // Star rating
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            rating = index + 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 40,
                            color: index < rating ? warmAmber : borderColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingLabel(rating),
                    style: subTitleTextStyle.copyWith(
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Comment field
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: surfaceColor.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please write a comment'),
                          ),
                        );
                        return;
                      }

                      final result = await ReviewService.submitReview(
                        venueId: widget.venueId,
                        venueType: widget.venueType,
                        rating: rating,
                        comment: commentController.text.trim(),
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: successColor,
                            ),
                          );
                          _loadReviews(); // Refresh reviews
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['error']),
                              backgroundColor: errorColor,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit Review',
                      style: buttonTextStyle.copyWith(color: colorWhite),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5) return 'Excellent!';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews', style: titleTextStyle),
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Write Review'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Summary Card
        if (_summary != null) _buildSummaryCard(),
        
        const SizedBox(height: 24),
        
        // Reviews List
        if (_reviews.isEmpty)
          _buildEmptyState()
        else
          _buildReviewsList(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glassStart, glassEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            children: [
              Text(
                _summary!.averageRating.toStringAsFixed(1),
                style: greetingTextStyle.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final filled = index < _summary!.averageRating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: filled ? warmAmber : borderColor,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_summary!.totalReviews} reviews',
                style: descTextStyle,
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Rating Distribution
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = _summary!.ratingDistribution[star] ?? 0;
                final percentage = _summary!.totalReviews > 0
                    ? count / _summary!.totalReviews
                    : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: descTextStyle.copyWith(fontSize: 12),
                      ),
                      const Icon(Icons.star, size: 12, color: warmAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: borderColor.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getBarColor(star),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: descTextStyle.copyWith(fontSize: 12),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int stars) {
    switch (stars) {
      case 5:
        return successColor;
      case 4:
        return mintGreen;
      case 3:
        return oliveGold;
      case 2:
        return warmAmber;
      case 1:
        return softCoral;
      default:
        return borderColor;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: borderColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: subTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your experience!',
              style: descTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    final displayReviews = _showAllReviews ? _reviews : _reviews.take(3).toList();

    return Column(
      children: [
        ...displayReviews.map((review) => _buildReviewCard(review)),
        if (_reviews.length > 3 && !_showAllReviews)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllReviews = true;
                });
              },
              child: Text(
                'Show all ${_reviews.length} reviews',
                style: subTitleTextStyle.copyWith(color: primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: review.userImage != null
                    ? NetworkImage(review.userImage!)
                    : null,
                child: review.userImage == null
                    ? Text(
                        review.userName[0].toUpperCase(),
                        style: subTitleTextStyle.copyWith(color: primaryColor),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: subTitleTextStyle.copyWith(fontSize: 14),
                        ),
                        if (review.isVerifiedBooking) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: successColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: descTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRatingColor(review.rating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: _getRatingColor(review.rating),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(0),
                      style: subTitleTextStyle.copyWith(
                        fontSize: 14,
                        color: _getRatingColor(review.rating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
            review.comment,
            style: normalTextStyle,
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return successColor;
    if (rating >= 3) return oliveGold;
    if (rating >= 2) return warmAmber;
    return softCoral;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
