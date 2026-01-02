import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/modules/auth/google_auth_view.dart';
import 'package:FitStart/utils/responsive_utils.dart';

class OnboardingView extends StatefulWidget {
  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _dragAccumX = 0; // accumulates horizontal drag on the bottom sheet
  bool _imagesPreloaded = false;

  List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/images/onb1.jpg',
      'title': 'Train Anytime, Anywhere',
      'subtitle':
          'Visit top-rated gyms, join group classes, or access exclusive zones—whenever it fits your schedule.',
    },
    {
      'image': 'assets/images/onb2.jpg',
      'title': 'Choose Your FitCard',
      'subtitle':
          'Unlock access to hundreds of gyms and fitness services with a single, flexible membership plan.',
    },
    {
      'image': 'assets/images/onb3.jpg',
      'title': 'Wellness at Your Fingertips',
      'subtitle':
          'Book specialists, redeem rewards, and manage your fitness journey—all in one app.',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPreloaded) {
      _precacheImages();
      _imagesPreloaded = true;
    }
  }

  Future<void> _precacheImages() async {
    for (var data in onboardingData) {
      await precacheImage(AssetImage(data['image']!), context);
    }
  }

  Future<void> _completeOnboarding() async {
    final box = await Hive.openBox('settings');
    await box.put('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        children: [
          // Top: 55% height image carousel with overlay (matching welcome screen)
          SizedBox(
            height: screenHeight * 0.55,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return Image.asset(
                      onboardingData[index]['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
                // Dark overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Back arrow to go to previous onboarding page
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Visibility(
                        visible: _currentPage > 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.ease,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom white sheet overlapping the image (matching welcome screen)
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  _dragAccumX += details.delta.dx;
                },
                onHorizontalDragEnd: (details) {
                  if (_dragAccumX < -40 &&
                      _currentPage < onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.ease,
                    );
                  } else if (_dragAccumX > 40 && _currentPage > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.ease,
                    );
                  }
                  _dragAccumX = 0;
                },
                child: Container(
                  width: double.infinity,
                  padding: ResponsiveUtils.padding(context, horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo (responsive size)
                        Image.asset(
                          'assets/images/logo.png',
                          height: ResponsiveUtils.responsive(
                            context: context,
                            mobile: 70.0,
                            tablet: 85.0,
                            desktop: 100.0,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),

                        // Title
                        Text(
                          onboardingData[_currentPage]['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),

                        // Subtitle (responsive style)
                        Text(
                          onboardingData[_currentPage]['subtitle']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(onboardingData.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: 10,
                              width: _currentPage == index ? 20 : 10,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? const Color(0xFF92C848)
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                        // Button (responsive style)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_currentPage < onboardingData.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.ease,
                                );
                              } else {
                                await _completeOnboarding();
                                if (!mounted) return;
                                // Smooth transition to Google auth
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                      const GoogleAuthView(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 500),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF92C848),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: ResponsiveUtils.padding(context, vertical: 16),
                              minimumSize: Size(
                                double.infinity,
                                ResponsiveUtils.responsive(
                                  context: context,
                                  mobile: 56.0,
                                  tablet: 64.0,
                                  desktop: 72.0,
                                ),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _currentPage < onboardingData.length - 1
                                  ? 'Next'
                                  : 'Continue',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 17),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
