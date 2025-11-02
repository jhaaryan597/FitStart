import 'package:flutter/material.dart';

import '../modules/search/search_view.dart';
import '../theme.dart';
import '../utils/dummy_data.dart';
import '../utils/responsive_utils.dart';
import '../utils/animation_utils.dart';

class CategoryListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> categoryList = [];
    for (int i = 0; i < sportCategories.length; i++) {
      categoryList.add(CategoryCard(
        title: sportCategories[i].name,
        imageAsset: sportCategories[i].image,
        index: i,
      ));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: ResponsiveUtils.padding(context, horizontal: 8),
        child: Row(
          children: categoryList,
        ),
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String title;
  final String imageAsset;
  final int index;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.imageAsset,
    this.index = 0,
  }) : super(key: key);

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = ResponsiveUtils.responsive(
      context: context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );

    final iconSize = ResponsiveUtils.responsive(
      context: context,
      mobile: 50.0,
      tablet: 60.0,
      desktop: 70.0,
    );

    final radius = ResponsiveUtils.responsive(
      context: context,
      mobile: 30.0,
      tablet: 36.0,
      desktop: 42.0,
    );

    return SlideInCard(
      index: widget.index,
      delay: const Duration(milliseconds: 50),
      child: Padding(
        padding: ResponsiveUtils.padding(
          context,
          vertical: 16,
          horizontal: 8,
        ),
        child: MouseRegion(
          onEnter: (_) => _controller.forward(),
          onExit: (_) => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Material(
                  color: colorWhite,
                  shadowColor:
                      primaryColor500.withOpacity(_glowAnimation.value),
                  elevation: ResponsiveUtils.spacing(context, 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusSize)),
                  child: InkWell(
                    highlightColor: primaryColor500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                    splashColor: primaryColor500.withOpacity(0.5),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return SearchView(
                          selectedDropdownItem: widget.title,
                        );
                      }));
                    },
                    child: Container(
                      width: cardSize,
                      padding: ResponsiveUtils.padding(context, all: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadiusSize),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            primaryColor100.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseAnimation(
                            duration: Duration(
                                milliseconds: 2000 + (widget.index * 200)),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor500.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: radius,
                                backgroundColor: primaryColor100,
                                child: Image.asset(
                                  widget.imageAsset,
                                  color: primaryColor500,
                                  width: iconSize,
                                  height: iconSize,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            widget.title,
                            style: descTextStyle.copyWith(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
