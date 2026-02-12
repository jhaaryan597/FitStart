import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/components/gym_card.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/gym_data.dart';
import 'package:FitStart/services/enhanced_cache_service.dart';
import 'package:FitStart/utils/location_service.dart';
import 'package:FitStart/services/api_service.dart';

class GymsView extends StatefulWidget {
  const GymsView({Key? key}) : super(key: key);

  @override
  State<GymsView> createState() => _GymsViewState();
}

class _GymsViewState extends State<GymsView> with AutomaticKeepAliveClientMixin {
  List<Gym> _allGyms = [];
  List<Gym> _displayedGyms = [];
  String _selectedType = 'All';
  String _sortBy = 'Nearest'; // Default to nearest
  Position? _position;

  final List<String> _gymTypes = [
    'All',
    'Mixed',
    'Bodybuilding',
    'CrossFit',
    'Yoga',
    'Functional',
  ];
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _loadGymsWithCache();
    _initLocation();
  }
  
  /// Load gyms with cache-first strategy
  Future<void> _loadGymsWithCache() async {
    // Try to load from cache first (instant)
    final cached = await EnhancedCacheService.getGyms();
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allGyms = cached;
          // Check for cached location and calculate distances if available
          final cachedPosition = LocationService.getLastKnownPosition();
          if (cachedPosition != null) {
            _position = cachedPosition;
            _calculateDistances();
          }
          _applyFilters();
        });
      }
      // Refresh in background
      _refreshGymsInBackground();
    } else {
      // No cache, load from local data
      if (mounted) {
        setState(() {
          _allGyms = List<Gym>.from(gymList);
          // Check for cached location and calculate distances if available
          final cachedPosition = LocationService.getLastKnownPosition();
          if (cachedPosition != null) {
            _position = cachedPosition;
            _calculateDistances();
          }
          _applyFilters();
        });
      }
      // Cache the data
      await EnhancedCacheService.cacheGyms(gymList);
    }
  }
  
  /// Refresh gyms in background
  Future<void> _refreshGymsInBackground() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In production, fetch from API here
    await EnhancedCacheService.cacheGyms(gymList);
  }

  Future<void> _initLocation() async {
    // First try cached position from LocationService
    final cachedPos = LocationService.getLastKnownPosition();

    if (cachedPos != null) {
      // Using cached location from LocationService
      if (!mounted) return;
      setState(() {
        _position = cachedPos;
        _calculateDistances();
        _applyFilters();
      });
      return;
    }

    // Try to load saved location from database
    Position? pos;
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        final savedLocation = data['savedLocation'] as String?;
        if (savedLocation != null && savedLocation.isNotEmpty) {
          // Get coordinates from saved address
          try {
            await LocationService.setLocationFromAddress(savedLocation);
            pos = LocationService.getLastKnownPosition();
          } catch (e) {
            debugPrint('Error getting coordinates from saved location: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved location: $e');
    }

    // If no saved location, try current GPS location (with cache)
    pos ??= await LocationService.getCurrentPosition();

    if (!mounted) return;
    setState(() {
      _position = pos;
      _calculateDistances();
      _applyFilters();
    });
  }

  void _calculateDistances() {
    if (_position != null) {
      for (final gym in _allGyms) {
        gym.distanceKm = LocationService.distanceInKm(
          _position!.latitude,
          _position!.longitude,
          gym.latitude,
          gym.longitude,
        );
      }
    }
  }

  void _applyFilters() {
    List<Gym> filtered = List<Gym>.from(_allGyms);

    // Filter by type
    if (_selectedType != 'All') {
      filtered = filtered.where((gym) => gym.type == _selectedType).toList();
    }

    // Sort
    _sortGyms(filtered);

    setState(() {
      _displayedGyms = filtered;
    });
  }

  void _sortGyms(List<Gym> gyms) {
    switch (_sortBy) {
      case 'Price: Low to High':
        gyms.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
        break;
      case 'Price: High to Low':
        gyms.sort((a, b) => b.monthlyPrice.compareTo(a.monthlyPrice));
        break;
      case 'Rating':
        gyms.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Nearest':
      default: // Default to nearest for backward compatibility
        if (_position != null) {
          gyms.sort((a, b) => (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
        } else {
          // Sort by rating when location is not available
          gyms.sort((a, b) => b.rating.compareTo(a.rating));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          'Gyms',
          style: titleTextStyle.copyWith(fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: darkBlue500),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Type Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _gymTypes.length,
              itemBuilder: (context, index) {
                final type = _gymTypes[index];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                      _applyFilters();
                    },
                    backgroundColor: colorWhite,
                    selectedColor: primaryColor100,
                    checkmarkColor: primaryColor500,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor500 : neutral700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gyms List
          Expanded(
            child: _displayedGyms.isEmpty
                ? Center(
                    child: Text(
                      'No gyms found',
                      style: normalTextStyle,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 120), // Space for floating nav bar
                    itemCount: _displayedGyms.length,
                    itemBuilder: (context, index) {
                      return GymCard(gym: _displayedGyms[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Sort By', style: titleTextStyle),
                  const SizedBox(height: 16),
                  ...[
                    'Nearest',
                    'Price: Low to High',
                    'Price: High to Low',
                    'Rating'
                  ]
                      .map((sort) => RadioListTile<String>(
                            title: Text(sort),
                            value: sort,
                            groupValue: _sortBy,
                            onChanged: (value) {
                              setModalState(() {
                                _sortBy = value!;
                              });
                              setState(() {
                                _sortBy = value!;
                              });
                              _applyFilters();
                            },
                            activeColor: primaryColor500,
                          ))
                      .toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
