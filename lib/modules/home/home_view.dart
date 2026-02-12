import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/services/review_service.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/category_card.dart';
import 'package:FitStart/components/sport_field_card.dart';
import 'package:FitStart/components/reusable/reusable_widgets.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/utils/location_service.dart';
import 'package:FitStart/utils/responsive_utils.dart';
import 'package:FitStart/utils/animation_utils.dart';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/services/cache_service.dart';
import 'package:FitStart/services/enhanced_cache_service.dart';
import 'package:FitStart/services/notification_service.dart';
import 'package:FitStart/modules/notification/notification_view.dart';
import 'package:FitStart/modules/root/root_view.dart';
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
  String? _currentAddress;
  String? _username;
  String? _profileImageUrl;
  int _unreadNotificationCount = 0;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _venuesPerPage = 10;
  final CacheService _cacheService = CacheService();
  final GlobalKey _venuesSectionKey = GlobalKey();

  @override
  bool get wantKeepAlive =>
      true; // Keep state alive when switching tabs  // Filter states
  String _selectedCategory = "All";
  String _sortBy = 'Nearest';
  bool _openNowOnly = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // GenZ slang rotation
  Timer? _slangTimer;
  int _currentSlangIndex = 0;
  
  // Search debouncing
  Timer? _searchDebounceTimer;
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
    _loadUnreadNotificationCount();
    _startSlangRotation();

    // Listen for profile refresh notifications
    ProfileRefreshManager.shouldRefreshHomeProfile
        .addListener(_onProfileRefresh);

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
          _allFields = List<SportField>.from(cached);
          // Check if we have cached location and sort accordingly
          final cachedPosition = LocationService.getLastKnownPosition();
          if (cachedPosition != null) {
            // Recalculate distances with cached position and sort by distance
            _allFields.forEach((field) {
              field.distanceKm = LocationService.distanceInKm(
                cachedPosition.latitude,
                cachedPosition.longitude,
                field.latitude,
                field.longitude,
              );
            });
            _sortFieldsByDistance();
          } else {
            // No cached location, sort by rating
            _allFields.sort((a, b) => b.rating.compareTo(a.rating));
          }
          _loadMoreVenues();
        });
      }
      // Data loaded from cache, now update ratings and refresh in background
      _updateFieldRatings();
      _refreshDataInBackground();
    } else {
      // No cache, load from dummy data
      if (mounted) {
        setState(() {
          _allFields = List<SportField>.from(_originalFields);
          // Check if we have cached location and sort accordingly
          final cachedPosition = LocationService.getLastKnownPosition();
          if (cachedPosition != null) {
            // Calculate distances with cached position and sort by distance
            _allFields.forEach((field) {
              field.distanceKm = LocationService.distanceInKm(
                cachedPosition.latitude,
                cachedPosition.longitude,
                field.latitude,
                field.longitude,
              );
            });
            _sortFieldsByDistance();
          } else {
            // No cached location, sort by rating
            _allFields.sort((a, b) => b.rating.compareTo(a.rating));
          }
          _loadMoreVenues();
        });
      }
      // Update ratings and cache the data
      _updateFieldRatings();
      await EnhancedCacheService.cacheSportFields(_originalFields);
    }
  }

  /// Update all field ratings from ReviewService
  Future<void> _updateFieldRatings() async {
    for (var field in _allFields) {
      try {
        final rating = await ReviewService.getVenueRating(
          venueId: field.id,
          venueType: 'venue',
        );
        field.rating = rating;
      } catch (e) {
        // Keep existing rating if fetch fails
      }
    }

    if (mounted) {
      setState(() {
        _displayedFields = List.from(_displayedFields); // Trigger rebuild
      });
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
    ProfileRefreshManager.shouldRefreshHomeProfile
        .removeListener(_onProfileRefresh);
    _slangTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onProfileRefresh() {
    _fetchUsername();
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
              (cachedProfile['name'] as String?) ??
              'User';
          _profileImageUrl = cachedProfile['profileImage'] as String?;
        });
      }

      // Check for locally stored preset avatar (overrides server image)
      final box = await Hive.openBox('user_profile_local');
      final presetAvatar = box.get('preset_avatar') as String?;
      if (presetAvatar != null && mounted) {
        setState(() {
          _profileImageUrl = presetAvatar;
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
                (data['name'] as String?) ??
                'User';
            _profileImageUrl = data['profileImage'] as String?;
          });
        }

        // Check for locally stored preset avatar (overrides server image)
        final box = await Hive.openBox('user_profile_local');
        final presetAvatar = box.get('preset_avatar') as String?;
        if (presetAvatar != null && mounted) {
          setState(() {
            _profileImageUrl = presetAvatar;
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

  // Public method to refresh profile data - called when returning from profile screen
  void refreshProfileData() {
    _fetchUsername();
  }

  void _sortFieldsByDistance() {
    _allFields.sort((a, b) => (a.distanceKm ?? double.infinity)
        .compareTo(b.distanceKm ?? double.infinity));
  }

  Future<void> _loadSavedLocation() async {
    // First check if we have a cached position from LocationService
    final cachedPosition = LocationService.getLastKnownPosition();
    final cachedAddress = LocationService.getLastKnownAddress();

    if (cachedPosition != null && cachedAddress != null) {
      // Using cached location from LocationService
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
        _displayedFields.clear();
        _currentPage = 1;
      });
      _sortFieldsByDistance();
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
      debugPrint('Error loading saved location: $e');
    }
  }

  Future<void> _saveLocationToDatabase(String address) async {
    try {
      // Cache the location first (instant)
      await _cacheService.cacheSavedLocation(address);

      // Note: Backend endpoint for updating saved location needs to be added
      // For now, location is cached locally
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
    _scrollToVenuesSection();
  }

  void _scrollToVenuesSection() {
    // Wait for the next frame to ensure the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _venuesSectionKey.currentContext;
      if (context != null) {
        // Get the render box of the venue section
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Get the position of the venue section relative to the screen
          final position = renderBox.localToGlobal(Offset.zero);
          // Calculate offset to account for header height
          // Header typically takes about 120-150 pixels on most devices
          final headerOffset =
              240.0; // Reduced offset to show venue header below search bar
          final targetOffset =
              _scrollController.offset + position.dy - headerOffset;

          // Scroll to the calculated position
          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
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
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating: High to Low':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Nearest':
      default: // Default to nearest for backward compatibility
        filtered.sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));
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
            // Reset displayed venues and reload from sorted list
            _displayedFields.clear();
            _currentPage = 1;
          });
          _sortFieldsByDistance();
          _loadMoreVenues();

          // Save location to database
          await _saveLocationToDatabase(address);
        }
      } catch (e) {
        debugPrint('Error geocoding address: $e');
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
            // Reset displayed venues and reload from sorted list
            _displayedFields.clear();
            _currentPage = 1;
          });
          _sortFieldsByDistance();
          _loadMoreVenues();

          // Save location to database
          if (locationString != null) {
            await _saveLocationToDatabase(locationString);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to get location. Please enable location services.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
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
                    builder: (context) => NotificationView(),
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
                  _searchDebounceTimer?.cancel();
                  _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  });
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
            onLocationSubmitted: (address) =>
                _getCurrentLocation(address: address),
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
                padding: const EdgeInsets.only(
                    bottom: 120), // Space for floating nav bar
                children: [
                  // Hide these sections when user is searching
                  if (_searchQuery.isEmpty) ...[
                    _buildGreetingSection(context),
                    CategoryListView(
                      onCategorySelected: _onCategorySelected,
                    ),
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
                          showCheckmark: false,
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
                  ListView.builder(
                    key: _venuesSectionKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _displayedFields.length,
                    itemBuilder: (context, index) => SportFieldCard(
                      field: _displayedFields[index],
                    ),
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
