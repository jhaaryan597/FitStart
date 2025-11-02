import 'dart:math';
import 'package:flutter/material.dart';

import '../model/sport_field.dart';
import '../modules/detail/detail_venue_view.dart';
import '../theme.dart';
import '../utils/responsive_utils.dart';

class SportFieldCard extends StatefulWidget {
  final SportField field;
  final int index;

  SportFieldCard({required this.field, this.index = 0});

  @override
  State<SportFieldCard> createState() => _SportFieldCardState();
}

class _SportFieldCardState extends State<SportFieldCard> {
  late List<String> _sportImages;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateSportImages();
  }

  void _generateSportImages() {
    final category = widget.field.category.name;
    final random = Random();

    // Map categories to their specific image prefixes
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
        // Fallback to original image
        availableImages = [widget.field.imageAsset];
    }

    // Shuffle and take 3 images (or all if less than 3)
    availableImages.shuffle(random);
    _sportImages = availableImages
        .take(3)
        .map((img) => img.startsWith('assets/') ? img : 'assets/images/$img')
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.padding(
        context,
        horizontal: 16,
        vertical: 4,
      ),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusSize),
            color: colorWhite,
            boxShadow: [
              BoxShadow(
                color: primaryColor500.withOpacity(0.1),
                blurRadius: ResponsiveUtils.spacing(context, 20),
                spreadRadius: 2,
              )
            ]),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: ResponsiveUtils.responsive(
                    context: context,
                    mobile: 190.0,
                    tablet: 220.0,
                    desktop: 250.0,
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _sportImages.length,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(borderRadiusSize)),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.darken,
                          child: Image.asset(
                            _sportImages[index],
                            width: ResponsiveUtils.width(context),
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
                      _sportImages.length,
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
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DetailView(field: widget.field);
                }));
              },
              child: Container(
                padding: ResponsiveUtils.padding(
                  context,
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.field.name,
                            maxLines: 2,
                            style: subTitleTextStyle.copyWith(
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: ResponsiveUtils.spacing(context, 18),
                                color: Colors.amber),
                            SizedBox(
                                width: ResponsiveUtils.spacing(context, 4)),
                            Text(
                              widget.field.rating.toStringAsFixed(1),
                              style: subTitleTextStyle.copyWith(
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/pin.png",
                          width: ResponsiveUtils.spacing(context, 20),
                          height: ResponsiveUtils.spacing(context, 20),
                          color: primaryColor500,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        Expanded(
                          child: Text(
                            widget.field.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: addressTextStyle.copyWith(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                            ),
                          ),
                        ),
                        if (widget.field.distanceKm != null) ...[
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Icon(Icons.near_me,
                              size: ResponsiveUtils.spacing(context, 16),
                              color: darkBlue300),
                          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            "${widget.field.distanceKm!.toStringAsFixed(1)} km",
                            style: addressTextStyle.copyWith(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
