class Review {
  final String id;
  final String venueId;
  final String venueType; // 'sport_field' or 'gym'
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images;
  final bool isVerifiedBooking;

  Review({
    required this.id,
    required this.venueId,
    required this.venueType,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
    this.isVerifiedBooking = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      venueId: json['venueId'] ?? '',
      venueType: json['venueType'] ?? 'sport_field',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userImage: json['userImage'],
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : null,
      isVerifiedBooking: json['isVerifiedBooking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'venueId': venueId,
      'venueType': venueType,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'isVerifiedBooking': isVerifiedBooking,
    };
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewSummary.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return ReviewSummary(
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double total = 0;

    for (final review in reviews) {
      total += review.rating;
      final roundedRating = review.rating.round().clamp(1, 5);
      distribution[roundedRating] = (distribution[roundedRating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: total / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }
}
