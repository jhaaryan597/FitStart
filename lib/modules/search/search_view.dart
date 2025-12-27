import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:geocoding/geocoding.dart';

import '../../model/sport_field.dart';
import '../../theme.dart';
import '../../utils/dummy_data.dart';
import '../../components/sport_field_list.dart';
import '../../utils/location_service.dart';
import '../../utils/animation_utils.dart';

class SearchView extends StatefulWidget {
  final String selectedDropdownItem;
  final List<SportField> fieldList;

  SearchView({required this.selectedDropdownItem}) : fieldList = sportFieldList;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String _query = "";
  String _selectedDropdownItem = "All";
  List<SportField> _fieldList = [];
  List<SportField> _selectedListByCategory = [];
  final TextEditingController _controller = TextEditingController();
  Position? _position;
  bool _openNowOnly = false;
  String _sortBy = 'Nearest';

  @override
  void initState() {
    super.initState();
    _query = widget.selectedDropdownItem;
    _controller.text = _query;
    _fieldList = widget.fieldList;
    _selectedDropdownItem =
        _query.isNotEmpty ? widget.selectedDropdownItem : 'All';
    // initial populate
    _applyAllFilters();
    // try to get user location
    _initLocation();
  }

  Future<void> _initLocation() async {
    // First try to load saved location from database
    Position? pos;

    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        final savedLocation = data['savedLocation'] as String?;
        if (savedLocation != null && savedLocation.isNotEmpty) {
          // Get coordinates from saved address
          try {
            final locations = await locationFromAddress(savedLocation);
            if (locations.isNotEmpty) {
              pos = Position(
                latitude: locations.first.latitude,
                longitude: locations.first.longitude,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            }
          } catch (e) {
            print('Error getting coordinates from saved location: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading saved location: $e');
    }

    // If no saved location, try current GPS location
    if (pos == null) {
      pos = await LocationService.getCurrentPosition();
    }

    if (!mounted) return;
    setState(() {
      _position = pos;
      if (_position != null) {
        for (final f in _fieldList) {
          f.distanceKm = LocationService.distanceInKm(
            _position!.latitude,
            _position!.longitude,
            f.latitude,
            f.longitude,
          );
        }
        _applyAllFilters();
      }
    });
  }

  void _applyAllFilters() {
    // category
    List<SportField> current = [];
    if (_selectedDropdownItem == 'All') {
      current = List.from(_fieldList);
    } else {
      for (final f in _fieldList) {
        if (f.category.name == _selectedDropdownItem) current.add(f);
      }
    }
    // search query filter
    if (_query.isNotEmpty) {
      current = current.where((field) {
        final nameLower = field.name.toLowerCase();
        final addressLower = field.address.toLowerCase();
        final queryLower = _query.toLowerCase();
        return nameLower.contains(queryLower) ||
            addressLower.contains(queryLower);
      }).toList();
    }

    // open now filter
    if (_openNowOnly) {
      current = current.where((f) => f.isOpenNow()).toList();
    }
    // sorting
    switch (_sortBy) {
      case 'Nearest':
        if (_position != null) {
          current.sort((a, b) => (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
        }
        break;
      case 'Price: Low to High':
        current.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        current.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating: High to Low':
        current.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    setState(() {
      _selectedListByCategory = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue100,
      appBar: AppBar(
        elevation: 0.0,
        systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: primaryColor500,
            statusBarIconBrightness: Brightness.light),
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          FuturisticContainer(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            gradientColors: [
              primaryColor500,
              primaryColor500.withOpacity(0.9),
            ],
            enableGlow: true,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(borderRadiusSize),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ScaleOnTap(
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(CupertinoIcons.arrow_left),
                          color: colorWhite,
                        ),
                      ),
                      const Spacer(),
                      SlideInCard(
                        index: 0,
                        child: FilterChip(
                          selected: _openNowOnly,
                          label: const Text('Open now',
                              style: TextStyle(fontSize: 13)),
                          selectedColor: primaryColor100,
                          backgroundColor: colorWhite.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _openNowOnly ? darkBlue500 : colorWhite,
                            fontSize: 13,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onSelected: (v) {
                            setState(() {
                              _openNowOnly = v;
                              _applyAllFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SlideInCard(index: 1, child: showDropdown()),
                      const SizedBox(width: 8),
                      SlideInCard(index: 2, child: _sortMenu()),
                    ],
                  ),
                  // Show search bar only if user didn't select a specific category
                  if (_selectedDropdownItem == 'All')
                    SlideInCard(
                      index: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: searchBar(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(
                  height: 16,
                ),
                Column(
                    children: _selectedListByCategory
                        .map((fieldEntity) => SportFieldList(
                              field: fieldEntity,
                            ))
                        .toList())
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget noMatchDataView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Image.asset(
            "assets/images/no_match_data_illustration.png",
            width: 200,
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            "No Match Data.",
            style: titleTextStyle.copyWith(color: darkBlue300),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            "Sorry we couldn't find what you were looking for, \nplease try another keyword.",
            style: descTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget showDropdown() {
    return DropdownButton<String>(
        value: _selectedDropdownItem,
        iconEnabledColor: colorWhite,
        iconDisabledColor: darkBlue500,
        dropdownColor: darkBlue500,
        style: normalTextStyle.copyWith(color: colorWhite),
        icon: const Icon(Icons.filter_alt),
        isDense: false,
        isExpanded: false,
        underline: const SizedBox(),
        alignment: Alignment.centerRight,
        items: <String>[
          "All",
          "Basketball",
          "Football",
          "Table Tennis",
          "Tennis",
          "Volleyball",
          "Cricket"
        ]
            .map<DropdownMenuItem<String>>((value) => DropdownMenuItem(
                  child: Text(value),
                  value: value,
                ))
            .toList(),
        onChanged: (value) {
          _selectedDropdownItem = value.toString();
          _applyAllFilters();
        });
  }

  Widget _sortMenu() {
    return PopupMenuButton<String>(
      color: darkBlue500,
      icon: const Icon(Icons.sort, color: colorWhite),
      onSelected: (value) {
        setState(() {
          _sortBy = value;
          _applyAllFilters();
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

  Widget searchBar() {
    return Container(
      decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(borderRadiusSize)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: TextField(
          onChanged: (String value) {
            setState(() {
              _query = value;
            });
            _applyAllFilters();
          },
          onSubmitted: (String value) {
            _applyAllFilters();
          },
          controller: _controller,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Search venues...",
              prefixIcon: const Icon(Icons.search, color: primaryColor500),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: primaryColor500),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = "";
                        });
                        _applyAllFilters();
                      },
                    )),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
