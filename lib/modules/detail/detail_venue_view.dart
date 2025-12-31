import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/modules/booking/booking_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/facility_card.dart';
import 'package:FitStart/components/reviews_section.dart';
import 'package:FitStart/services/favorites_service.dart';
import 'package:FitStart/services/ml/interaction_tracker.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/services/communication_service.dart';
import 'package:FitStart/utils/animation_utils.dart';

class DetailView extends StatefulWidget {
  final SportField field;

  const DetailView({Key? key, required this.field}) : super(key: key);

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  late List<String> _sportImages;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateSportImages();
    _checkFavoriteStatus();
    _trackVenueView(); // Track venue view for ML recommendations
  }

  /// Track venue view for ML learning
  Future<void> _trackVenueView() async {
    try {
      final userResult = await ApiService.getCurrentUser();
      if (userResult['success']) {
        final userId = userResult['data']['_id'] as String?;
        if (userId != null) {
          await InteractionTracker.trackView(
            userId: userId,
            venueId: widget.field.id,
            venueType: 'sport_field',
          );
        }
      }
    } catch (e) {
      print('Error tracking venue view: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _generateSportImages() {
    final category = widget.field.category.name;
    final random = Random();

    List<String> availableImages = [];

    switch (category) {
      case 'Basketball':
        availableImages = ['bb1.jpg', 'bb2.jpg', 'bb3.jpg'];
        break;
      case 'Football':
        availableImages = ['fb1.jpg', 'fb2.jpg', 'fb3.jpg'];
        break;
      case 'Volleyball':
        availableImages = ['vb1.jpg', 'vb2.jpg', 'vb3.jpg'];
        break;
      case 'Table Tennis':
        availableImages = ['tt1.jpg', 'tt2.jpg', 'tt3.jpg'];
        break;
      case 'Tennis':
        availableImages = ['ten1.jpg', 'ten2.jpg', 'ten3.jpg'];
        break;
      case 'Cricket':
        availableImages = [
          'cric1.jpg',
          'cric2.jpg',
          'cric3.jpg',
          'cric4.jpg',
          'cric5.jpg',
          'cric6.jpg'
        ];
        break;
      default:
        availableImages = [widget.field.imageAsset];
    }

    availableImages.shuffle(random);
    _sportImages = availableImages
        .take(3)
        .map((img) => img.startsWith('assets/') ? img : 'assets/images/$img')
        .toList();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(widget.field.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final success = await FavoritesService.toggleFavorite(widget.field.id);
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      // Track favorite/unfavorite for ML recommendations
      try {
        final userResult = await ApiService.getCurrentUser();
        if (userResult['success']) {
          final userId = userResult['data']['_id'] as String?;
          if (userId != null) {
            await InteractionTracker.trackFavorite(
              userId: userId,
              venueId: widget.field.id,
              venueType: 'sport_field',
            );
          }
        }
      } catch (e) {
        print('Error tracking favorite: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          customSliverAppBar(context, widget.field),
          SliverPadding(
            padding:
                const EdgeInsets.only(right: 24, left: 24, bottom: 24, top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideInCard(
                  index: 0,
                  child: FuturisticContainer(
                    padding: const EdgeInsets.all(16),
                    gradientColors: [
                      primaryColor100.withOpacity(0.3),
                      Colors.white,
                    ],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PulseAnimation(
                          child: Image.asset(
                            "assets/icons/pin.png",
                            width: 24,
                            height: 24,
                            color: primaryColor500,
                          ),
                        ),
                        const SizedBox(
                          width: 16.0,
                        ),
                        Flexible(
                          child: Text(
                            widget.field.address,
                            overflow: TextOverflow.visible,
                            style: addressTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                SlideInCard(
                  index: 1,
                  child: FuturisticContainer(
                    padding: const EdgeInsets.all(16),
                    gradientColors: [
                      primaryColor100.withOpacity(0.3),
                      Colors.white,
                    ],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PulseAnimation(
                          child: const Icon(
                            CupertinoIcons.money_dollar_circle_fill,
                            color: primaryColor500,
                          ),
                        ),
                        const SizedBox(
                          width: 16.0,
                        ),
                        Flexible(
                          child: Text(
                            "₹ ${widget.field.price} / hour",
                            overflow: TextOverflow.visible,
                            style: addressTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Text(
                  "Contact:",
                  style: subTitleTextStyle,
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone,
                      color: primaryColor500,
                    ),
                    const SizedBox(
                      width: 16.0,
                    ),
                    Flexible(
                      child: Text(
                        widget.field.phoneNumber,
                        overflow: TextOverflow.visible,
                        style: addressTextStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                
                // Communication Buttons
                CommunicationService.buildCommunicationButtons(
                  context: context,
                  phoneNumber: widget.field.phoneNumber,
                  venueName: widget.field.name,
                  venueId: widget.field.id,
                  venueType: 'sports_venue',
                  initialMessage: 'Hi! I\'m interested in booking ${widget.field.name} for ${widget.field.category.name}. Could you please provide availability and pricing details?',
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_circle_rounded,
                      color: primaryColor500,
                    ),
                    const SizedBox(
                      width: 16.0,
                    ),
                    Flexible(
                      child: Text(
                        widget.field.author,
                        overflow: TextOverflow.visible,
                        style: addressTextStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Availability:",
                      style: subTitleTextStyle,
                    ),
                    TextButton(
                        onPressed: () {}, child: const Text("See Availability"))
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: primaryColor500,
                    ),
                    const SizedBox(
                      width: 16.0,
                    ),
                    Text(
                      widget.field.openDay,
                      style: descTextStyle,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: primaryColor500,
                    ),
                    const SizedBox(
                      width: 16.0,
                    ),
                    Text(
                      "${widget.field.openTime} - ${widget.field.closeTime}",
                      style: descTextStyle,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 32,
                ),
                Text(
                  "Facilities:",
                  style: subTitleTextStyle,
                ),
                const SizedBox(
                  height: 16,
                ),
                FacilityCardList(facilities: widget.field.facilities),
                const SizedBox(
                  height: 32,
                ),
                // Reviews Section
                ReviewsSection(
                  venueId: widget.field.id,
                  venueType: 'sport_field',
                  venueName: widget.field.name,
                ),
                const SizedBox(
                  height: 32,
                ),
              ]),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
              color: lightBlue300,
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
          ]),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusSize))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return BookingView(
                    field: widget.field,
                  );
                }));
              },
              child: const Text("Book Now")),
        ),
      ),
    );
  }

  Widget customSliverAppBar(context, field) {
    return SliverAppBar(
      shadowColor: primaryColor500.withOpacity(.2),
      backgroundColor: colorWhite,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.black.withOpacity(0.4),
        statusBarIconBrightness: Brightness.light,
      ),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        expandedTitleScale: 1,
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: MediaQuery.of(context).size.width,
          height: kToolbarHeight,
          decoration: const BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadiusSize))),
          child: Center(
            child: Text(
              widget.field.name,
              style: titleTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _sportImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.darken,
                  child: Image.asset(
                    _sportImages[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            // Page Indicator
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _sportImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? primaryColor500
                          : Colors.white.withOpacity(0.5),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScaleOnTap(
          child: Container(
            decoration: BoxDecoration(
              color: colorWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor500.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                iconSize: 26,
                icon: const Icon(
                  Icons.arrow_back,
                  color: darkBlue500,
                )),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ScaleOnTap(
            child: Container(
              decoration: BoxDecoration(
                color: colorWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor500.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _isLoadingFavorite
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: darkBlue500,
                        ),
                      ),
                    )
                  : (_isFavorite
                      ? PulseAnimation(
                          child: IconButton(
                            onPressed: _toggleFavorite,
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            tooltip: 'Remove from favorites',
                          ),
                        )
                      : IconButton(
                          onPressed: _toggleFavorite,
                          icon: const Icon(
                            Icons.favorite_border,
                            color: darkBlue500,
                          ),
                          tooltip: 'Add to favorites',
                        )),
            ),
          ),
        )
      ],
      expandedHeight: 300,
    );
  }
}
