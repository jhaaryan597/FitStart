import 'dart:async';
import 'package:flutter/material.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/category_card.dart';
import 'package:FitStart/components/sport_field_card.dart';
import 'package:FitStart/components/reusable/reusable_widgets.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/utils/location_service.dart';
import 'package:FitStart/utils/responsive_utils.dart';
import 'package:FitStart/utils/animation_utils.dart';
import 'package:FitStart/services/ml_recommendation_service.dart';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/services/cache_service.dart';
import 'package:FitStart/services/enhanced_cache_service.dart';
import 'package:FitStart/services/notification_service.dart';
import 'package:FitStart/modules/notification/notification_view.dart';
import 'package:geocoding/geocoding.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin {
  final List<SportField> _originalFields =
      List<SportField>.from(sportFieldList);
  List<SportField> _allFields = [];
  List<SportField> _displayedFields = [];
  List<SportField> _recommendedVenues = [];
  bool _loadingRecommendations = true;
  String? _currentAddress;
  String? _username;
  String? _profileImageUrl;
  int _unreadNotificationCount = 0;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _venuesPerPage = 10;
  final CacheService _cacheService = CacheService();

  @override
  bool get wantKeepAlive =>
      true; // Keep state alive when switching tabs  // Filter states
  String _selectedCategory = "All";
  String _sortBy = 'Default';
  bool _openNowOnly = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // GenZ slang rotation
  Timer? _slangTimer;
  int _currentSlangIndex = 0;
  final List<String> _genZSlangs = [
    "Let's Get This Bread! 🍞",
    "Time to Hit Different! 💪",
    "No Cap, Let's Train! 🧢",
    "Slay Your Workout! ⚡",
    "Catch These Gains! 💯",
    "It's Giving Fitness! ✨",
    "Periodt, Let's Go! 🔥",
    "Main Character Energy! 👑",
    "Living My Best Life! 🌟",
    "That's Bussin'! 🚀",
    "On My Grind Mode! ⚙️",
    "Vibing & Thriving! 🎯",
    "Built Different! 💎",
    "Stay Locked In! 🔒",
    "Crushing Goals Daily! 🏆",
    "Savage Mode Activated! 😤",
    "Big Energy Only! ⚡",
    "No Days Off Gang! 💪",
    "Beast Mode Unlocked! 🦁",
    "Gym is My Therapy! 🧘"
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedDataFirst(); // Load cache instantly
    _fetchUsername();
    _loadSavedLocation();
    _loadMLRecommendations();
    _loadUnreadNotificationCount();
    _startSlangRotation();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreVenues();
      }
    });
  }
  
  /// Load cached data first for instant display
  Future<void> _loadCachedDataFirst() async {
    // Try to load from cache
    final cached = await EnhancedCacheService.getSportFields();
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allFields = List<SportField>.from(cached)..shuffle();
          _loadMoreVenues();
        });
      }
      // Data loaded from cache, now refresh in background
      _refreshDataInBackground();
    } else {
      // No cache, load from dummy data
      _allFields = List<SportField>.from(_originalFields)..shuffle();
      _loadMoreVenues();
      // Cache the dummy data
      await EnhancedCacheService.cacheSportFields(_originalFields);
    }
  }
  
  /// Refresh data in background without blocking UI
  Future<void> _refreshDataInBackground() async {
    // Fetch fresh data from API if available
    // For now, we use dummy data but in production this would call your API
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      // Update cache with fresh data
      await EnhancedCacheService.cacheSportFields(_originalFields);
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  void _startSlangRotation() {
    _slangTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentSlangIndex = (_currentSlangIndex + 1) % _genZSlangs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _slangTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsername() async {
    // Try to load from cache first (valid for 5 minutes, same as profile)
    final cachedProfile = await CacheManager.get<Map<String, dynamic>>(
      'user_profile',
      maxAge: const Duration(minutes: 5),
    );

    if (cachedProfile != null) {
      if (mounted) {
        setState(() {
          _username = (cachedProfile['username'] as String?) ??
                     (cachedProfile['name'] as String?) ?? 'User';
          _profileImageUrl = cachedProfile['profileImage'] as String?;
        });
      }
      return; // Data loaded from cache
    }

    // Fetch from server if cache is empty or expired
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        
        // Cache the data using CacheManager
        await CacheManager.set('user_profile', data);

        if (mounted) {
          setState(() {
            _username = (data['username'] as String?) ??
                       (data['name'] as String?) ?? 'User';
            _profileImageUrl = data['profileImage'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _username = 'User';
        });
      }
    }
  }

  Future<void> _loadMLRecommendations() async {
    // Try to load from cache first
    final cachedRecommendations = _cacheService.getCachedRecommendations();
    if (cachedRecommendations != null && cachedRecommendations.isNotEmpty) {
      // Convert cached data back to SportField objects
      final List<SportField> recommendations =
          cachedRecommendations.map((data) {
        // Find matching field from original fields
        return _originalFields.firstWhere(
          (field) => field.name == data['name'],
          orElse: () => _originalFields.first,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _recommendedVenues = recommendations;
          _loadingRecommendations = false;
        });
      }
      // Data loaded from cache, no need to fetch from server
      return;
    }

    setState(() {
      _loadingRecommendations = true;
    });

    try {
      // Get current user to fetch user ID
      final result = await ApiService.getCurrentUser();
      final userId = result['success'] ? result['data']['_id'] as String? : null;

      // Load from cache first
      final cachedRecommendations = await EnhancedCacheService.getRecommendedVenues();
      if (cachedRecommendations != null && cachedRecommendations.isNotEmpty && mounted) {
        setState(() {
          _recommendedVenues = cachedRecommendations;
          _loadingRecommendations = false;
        });
      }
      
      // Then fetch fresh recommendations
      final recommendations =
          await MLRecommendationService.getRecommendedVenues(
        userId: userId,
        limit: 10,
      );

      // Cache the recommendations
      await EnhancedCacheService.cacheRecommendedVenues(recommendations);
      final cacheData = recommendations
          .map((field) => {
                'name': field.name,
                'address': field.address,
              })
          .toList();
      await _cacheService.cacheRecommendations(cacheData);

      if (mounted) {
        setState(() {
          _recommendedVenues = recommendations;
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Error loading ML recommendations: $e');
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadSavedLocation() async {
    // First check if we have a cached position from LocationService
    final cachedPosition = LocationService.getLastKnownPosition();
    final cachedAddress = LocationService.getLastKnownAddress();
    
    if (cachedPosition != null && cachedAddress != null) {
      print('✅ Using cached location from LocationService');
      setState(() {
        _currentAddress = cachedAddress;
        _allFields.forEach((field) {
          field.distanceKm = LocationService.distanceInKm(
            cachedPosition.latitude,
            cachedPosition.longitude,
            field.latitude,
            field.longitude,
          );
        });
        _allFields.sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));
        _displayedFields.clear();
        _currentPage = 1;
      });
      _loadMoreVenues();
      return;
    }
    
    // Try to load from legacy cache
    final cachedLocation = _cacheService.getCachedLocation();
    if (cachedLocation != null && cachedLocation.isNotEmpty) {
      await _getCurrentLocation(address: cachedLocation);
      return;
    }

    // Fetch from API as last resort
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        final savedLocation = data['savedLocation'] as String?;
        if (savedLocation != null && savedLocation.isNotEmpty) {
          // Cache the location
          await _cacheService.cacheSavedLocation(savedLocation);
          await LocationService.setLocationFromAddress(savedLocation);
          await _getCurrentLocation(address: savedLocation);
        }
      }
    } catch (e) {
      print('Error loading saved location: $e');
    }
  }

  Future<void> _saveLocationToDatabase(String address) async {
    try {
      // Cache the location first (instant)
      await _cacheService.cacheSavedLocation(address);

      // Note: Backend endpoint for updating saved location needs to be added
      // For now, location is cached locally
      print('Location cached successfully: $address');
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  void _applyFilters() {
    // Start with original fields
    List<SportField> filtered = List.from(_originalFields);

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((field) {
        final nameLower = field.name.toLowerCase();
        final addressLower = field.address.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return nameLower.contains(queryLower) ||
            addressLower.contains(queryLower);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != "All") {
      filtered = filtered
          .where((field) => field.category.name == _selectedCategory)
          .toList();
    }

    // Open now filter
    if (_openNowOnly) {
      filtered = filtered.where((field) => field.isOpenNow()).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Default':
        filtered.shuffle(); // Random order for default
        break;
      case 'Nearest':
        filtered.sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating: High to Low':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() {
      _allFields = filtered;
      _displayedFields.clear();
      _currentPage = 1;
    });

    _loadMoreVenues();
  }

  void _loadMoreVenues() {
    final int startIndex = (_currentPage - 1) * _venuesPerPage;
    int endIndex = startIndex + _venuesPerPage;
    if (endIndex > _allFields.length) {
      endIndex = _allFields.length;
    }

    if (startIndex < _allFields.length) {
      setState(() {
        _displayedFields.addAll(_allFields.getRange(startIndex, endIndex));
        _currentPage++;
      });
    }
  }

  Future<void> _getCurrentLocation({String? address}) async {
    if (address != null && address.isNotEmpty) {
      try {
        // Cache this address in LocationService
        await LocationService.setLocationFromAddress(address);
        
        final locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final location = locations.first;
          setState(() {
            _currentAddress = address;
            _allFields.forEach((field) {
              field.distanceKm = LocationService.distanceInKm(
                location.latitude,
                location.longitude,
                field.latitude,
                field.longitude,
              );
            });
            // Sort by distance (nearest to farthest)
            _allFields.sort((a, b) => (a.distanceKm ?? double.infinity)
                .compareTo(b.distanceKm ?? double.infinity));

            // Reset displayed venues and reload from sorted list
            _displayedFields.clear();
            _currentPage = 1;
            _loadMoreVenues();
          });

          // Save location to database
          await _saveLocationToDatabase(address);
        }
      } catch (e) {
        print('Error geocoding address: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find location. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Get current GPS position (uses cached if available and recent)
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        // Try to get address if not already cached
        String? locationString = LocationService.getLastKnownAddress();
        
        if (locationString == null) {
          final placemark = await LocationService.getCurrentPlacemark();
          if (placemark != null) {
            locationString =
                "${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.postalCode ?? ''}";
            // Clean up formatting
            locationString = locationString.replaceAll(RegExp(r'^,\s*'), '');
            locationString = locationString.replaceAll(RegExp(r',\s*,'), ',');
          }
        }
        
        if (mounted) {
          setState(() {
            _currentAddress = locationString ?? 'Current Location';
            _allFields.forEach((field) {
              field.distanceKm = LocationService.distanceInKm(
                position.latitude,
                position.longitude,
                field.latitude,
                field.longitude,
              );
            });
            // Sort by distance (nearest to farthest)
            _allFields.sort((a, b) => (a.distanceKm ?? double.infinity)
                .compareTo(b.distanceKm ?? double.infinity));

            // Reset displayed venues and reload from sorted list
            _displayedFields.clear();
            _currentPage = 1;
            _loadMoreVenues();
          });

          // Save location to database
          if (locationString != null) {
            await _saveLocationToDatabase(locationString);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showLocationDialog() {
    final TextEditingController addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Your Location"),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(
              hintText: "Enter your address",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
              child: const Text("Use Current Location"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getCurrentLocation(address: addressController.text);
              },
              child: const Text("Set Location"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: ResponsiveUtils.padding(context, all: 16),
      child: SafeArea(
        child: Column(
          children: [
            UserHeader(
              username: _username,
              profileImageUrl: _profileImageUrl,
              unreadCount: _unreadNotificationCount,
              onNotificationTap: () async {
                // Navigate to notification screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationView(),
                  ),
                );
                // Reload unread count when returning from notification screen
                _loadUnreadNotificationCount();
              },
              getProfileImageProvider: _getProfileImageProvider,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            SlideInCard(
              index: 0,
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search venues...",
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                  });
                  _applyFilters();
                },
                showClearButton: _searchQuery.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.padding(
        context,
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _genZSlangs[_currentSlangIndex],
              key: ValueKey<int>(_currentSlangIndex),
              style: greetingTextStyle.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          LocationDisplay(
            address: _currentAddress,
            onTap: _showLocationDialog,
            showSetLocationPrompt: _currentAddress == null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ResponsiveContainer(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Hide these sections when user is searching
                  if (_searchQuery.isEmpty) ...[
                    _buildGreetingSection(context),
                    CategoryListView(),
                    // ML Recommendations Section
                    if (_recommendedVenues.isNotEmpty) ...[
                      SectionHeader(
                        title: "Recommended for You",
                        icon: Icons.auto_awesome,
                        badge: "ML Powered",
                        padding: ResponsiveUtils.padding(
                          context,
                          horizontal: 16,
                          top: 16,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      SizedBox(
                        height: ResponsiveUtils.responsive(
                          context: context,
                          mobile: 300.0,
                          tablet: 340.0,
                          desktop: 380.0,
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding:
                              ResponsiveUtils.padding(context, horizontal: 12),
                          itemCount: _recommendedVenues.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: ResponsiveUtils.responsive(
                                context: context,
                                mobile: 220.0,
                                tablet: 260.0,
                                desktop: 300.0,
                              ),
                              margin: ResponsiveUtils.padding(context,
                                  horizontal: 4),
                              child: SportFieldCard(
                                field: _recommendedVenues[index],
                                index: index,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_loadingRecommendations) ...[
                      Padding(
                        padding: ResponsiveUtils.padding(context, all: 16),
                        child: LoadingIndicator(
                          message: "Loading recommendations...",
                        ),
                      ),
                    ],
                  ],
                  SectionHeader(
                    title: "All Venues",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                          selected: _openNowOnly,
                          label: Text(
                            'Open Now',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                            ),
                          ),
                          padding:
                              ResponsiveUtils.padding(context, horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          selectedColor: primaryColor500.withOpacity(0.3),
                          checkmarkColor: primaryColor500,
                          onSelected: (v) {
                            setState(() {
                              _openNowOnly = v;
                              _applyFilters();
                            });
                          },
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        _buildCategoryDropdown(),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        _buildSortMenu(),
                      ],
                    ),
                  ),
                  Column(
                    children: _displayedFields
                        .map((fieldEntity) => SportFieldCard(
                              field: fieldEntity,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImageProvider() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('assets/')) {
        return AssetImage(_profileImageUrl!);
      } else {
        return NetworkImage(_profileImageUrl!);
      }
    }
    return const AssetImage("assets/images/profile_male.jpg");
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: ResponsiveUtils.padding(context, horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isDense: true,
        underline: const SizedBox(),
        style: descTextStyle.copyWith(
          fontSize: ResponsiveUtils.fontSize(context, 12),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          size: ResponsiveUtils.spacing(context, 20),
        ),
        items: [
          "All",
          "Basketball",
          "Football",
          "Table Tennis",
          "Tennis",
          "Volleyball",
          "Cricket"
        ]
            .map<DropdownMenuItem<String>>((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.sort,
        color: primaryColor500,
        size: ResponsiveUtils.spacing(context, 24),
      ),
      onSelected: (value) {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Default', child: Text('Default')),
        const PopupMenuItem(value: 'Nearest', child: Text('Nearest')),
        const PopupMenuItem(
            value: 'Price: Low to High', child: Text('Price: Low to High')),
        const PopupMenuItem(
            value: 'Price: High to Low', child: Text('Price: High to Low')),
        const PopupMenuItem(
            value: 'Rating: High to Low', child: Text('Rating: High to Low')),
      ],
    );
  }
}
