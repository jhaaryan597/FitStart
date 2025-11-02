import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/modules/gym/gym_membership_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/services/favorites_service.dart';

class GymDetailView extends StatefulWidget {
  final Gym gym;

  const GymDetailView({Key? key, required this.gym}) : super(key: key);

  @override
  State<GymDetailView> createState() => _GymDetailViewState();
}

class _GymDetailViewState extends State<GymDetailView> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  late List<String> _gymImages;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _generateRandomGymImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _generateRandomGymImages() {
    // Generate 3 random unique numbers between 1 and 12
    final random = Random();
    final availableNumbers = List.generate(12, (index) => index + 1);
    availableNumbers.shuffle(random);

    _gymImages = availableNumbers
        .take(3)
        .map((num) => 'assets/images/gym$num.jpg')
        .toList();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite('GYM_${widget.gym.id}');
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final success =
        await FavoritesService.toggleFavorite('GYM_${widget.gym.id}');
    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
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
          _buildSliverAppBar(context),
          SliverPadding(
            padding:
                const EdgeInsets.only(right: 24, left: 24, bottom: 24, top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/icons/pin.png",
                      width: 24,
                      height: 24,
                      color: primaryColor500,
                    ),
                    const SizedBox(width: 16.0),
                    Flexible(
                      child: Text(
                        widget.gym.address,
                        overflow: TextOverflow.visible,
                        style: addressTextStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: primaryColor500,
                    ),
                    const SizedBox(width: 16.0),
                    Flexible(
                      child: Text(
                        "₹${widget.gym.monthlyPrice}/month • ₹${widget.gym.dailyPrice}/day",
                        overflow: TextOverflow.visible,
                        style: addressTextStyle,
                      ),
                    ),
                  ],
                ),

                if (widget.gym.hasPersonalTrainer &&
                    widget.gym.trainerPrice > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: primaryColor500,
                      ),
                      const SizedBox(width: 16.0),
                      Flexible(
                        child: Text(
                          "Personal Trainer: ₹${widget.gym.trainerPrice}/session",
                          overflow: TextOverflow.visible,
                          style: addressTextStyle,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Contact
                Text(
                  "Contact:",
                  style: subTitleTextStyle,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone,
                      color: primaryColor500,
                    ),
                    const SizedBox(width: 16.0),
                    Flexible(
                      child: Text(
                        widget.gym.phoneNumber,
                        overflow: TextOverflow.visible,
                        style: addressTextStyle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Availability
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Operating Hours:",
                      style: subTitleTextStyle,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.gym.isOpenNow()
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.gym.isOpenNow()
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.gym.isOpenNow()
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.gym.isOpenNow() ? 'Open Now' : 'Closed',
                            style: TextStyle(
                              color: widget.gym.isOpenNow()
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      color: primaryColor500,
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      widget.gym.openDay,
                      style: descTextStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: primaryColor500,
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      "${widget.gym.openTime} - ${widget.gym.closeTime}",
                      style: descTextStyle,
                    ),
                  ],
                ),

                if (widget.gym.description != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    "About:",
                    style: subTitleTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.gym.description!,
                    style: normalTextStyle.copyWith(
                      color: neutral700,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Amenities
                Text(
                  "Amenities:",
                  style: subTitleTextStyle,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.gym.amenities
                      .map((amenity) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: primaryColor100,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  amenity.imageAsset,
                                  width: 18,
                                  height: 18,
                                  color: primaryColor500,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: primaryColor500,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  amenity.name,
                                  style: normalTextStyle.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),

                if (widget.gym.hasGroupClasses) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBlue100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor100, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.groups,
                          color: primaryColor500,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Group Classes Available",
                                style: subTitleTextStyle.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Join our energetic group workout sessions",
                                style: descTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: lightBlue300,
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSize),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GymMembershipView(gym: widget.gym),
              ),
            );
          },
          child: const Text("Get Membership"),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
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
              top: Radius.circular(borderRadiusSize),
            ),
          ),
          child: Center(
            child: Text(
              widget.gym.name,
              style: titleTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _gymImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _gymImages[index],
                  fit: BoxFit.cover,
                );
              },
            ),
            // Page indicator
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _gymImages.length,
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
        child: Container(
          decoration: const BoxDecoration(
            color: colorWhite,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            iconSize: 26,
            icon: const Icon(
              Icons.arrow_back,
              color: darkBlue500,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: colorWhite,
              shape: BoxShape.circle,
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
                : IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : darkBlue500,
                    ),
                    tooltip: _isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
          ),
        )
      ],
      expandedHeight: 300,
    );
  }
}
