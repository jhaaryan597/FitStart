import 'dart:math';
import 'package:flutter/material.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/modules/gym/gym_detail_view.dart';
import 'package:FitStart/theme.dart';

class GymCard extends StatefulWidget {
  final Gym gym;

  const GymCard({Key? key, required this.gym}) : super(key: key);

  @override
  State<GymCard> createState() => _GymCardState();
}

class _GymCardState extends State<GymCard> {
  late List<String> _gymImages;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateRandomGymImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _generateRandomGymImages() {
    final random = Random();
    final availableNumbers = List.generate(12, (index) => index + 1);
    availableNumbers.shuffle(random);

    _gymImages = availableNumbers
        .take(3)
        .map((num) => 'assets/images/gym$num.jpg')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(right: 16, left: 16, top: 4.0, bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GymDetailView(gym: widget.gym),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: colorWhite,
            boxShadow: [
              BoxShadow(
                color: primaryColor500.withOpacity(0.1),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  // Gym Image Gallery
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _gymImages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            image: DecorationImage(
                              image: AssetImage(_gymImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Page Indicator
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _gymImages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? primaryColor500
                                : Colors.white.withOpacity(0.5),
                            border: Border.all(
                              color: Colors.white,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gym Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.gym.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Open/Closed Status
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.gym.isOpenNow()
                            ? Colors.green
                            : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.gym.isOpenNow() ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gym Name and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.gym.name,
                            style: titleTextStyle.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.gym.rating.toString(),
                              style: normalTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Address with Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: primaryColor500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.gym.address,
                            style: descTextStyle.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (widget.gym.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.gym.distanceKm!.toStringAsFixed(1)} km',
                              style: descTextStyle.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pricing
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly',
                                  style: descTextStyle.copyWith(fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${widget.gym.monthlyPrice}',
                                  style: priceTextStyle.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily',
                                  style: descTextStyle.copyWith(fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${widget.gym.dailyPrice}',
                                  style: priceTextStyle.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Features
                    Row(
                      children: [
                        if (widget.gym.hasPersonalTrainer)
                          _buildFeatureBadge(
                            Icons.fitness_center,
                            'Trainer',
                          ),
                        if (widget.gym.hasPersonalTrainer &&
                            widget.gym.hasGroupClasses)
                          const SizedBox(width: 6),
                        if (widget.gym.hasGroupClasses)
                          _buildFeatureBadge(
                            Icons.groups,
                            'Classes',
                          ),
                        if (widget.gym.hasPersonalTrainer ||
                            widget.gym.hasGroupClasses)
                          const SizedBox(width: 6),
                        _buildFeatureBadge(
                          Icons.access_time,
                          widget.gym.openDay == 'Open 24/7' ? '24/7' : 'Daily',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: primaryColor500,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primaryColor500,
            ),
          ),
        ],
      ),
    );
  }
}
