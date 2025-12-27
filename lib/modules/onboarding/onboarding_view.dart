import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FitStart/modules/auth/auth_view.dart';

class OnboardingView extends StatefulWidget {
  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _dragAccumX = 0; // accumulates horizontal drag on the bottom sheet

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

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Top: 70% height image carousel with overlay
            SizedBox(
              height: screenHeight * 0.7,
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
                ],
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

            // Bottom: 40% height white sheet overlapping the image by 10% of screen height
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.35,
                    maxHeight: screenHeight * 0.45,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo.png', height: 50),
                          const SizedBox(height: 20),
                          Text(
                            onboardingData[_currentPage]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            onboardingData[_currentPage]['subtitle']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
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
                          const SizedBox(height: 30),
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
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const AuthView(),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF92C848),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                _currentPage < onboardingData.length - 1
                                    ? 'Next'
                                    : 'Get Started',
                                style: const TextStyle(
                                  fontSize: 18,
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
      ),
    );
  }
}
