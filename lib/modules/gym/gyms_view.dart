import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/components/gym_card.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/gym_data.dart';

class GymsView extends StatefulWidget {
  const GymsView({Key? key}) : super(key: key);

  @override
  State<GymsView> createState() => _GymsViewState();
}

class _GymsViewState extends State<GymsView> {
  List<Gym> _displayedGyms = [];
  String _selectedType = 'All';
  String _sortBy = 'Default';

  final List<String> _gymTypes = [
    'All',
    'Mixed',
    'Bodybuilding',
    'CrossFit',
    'Yoga',
    'Functional',
  ];

  @override
  void initState() {
    super.initState();
    _displayedGyms = List<Gym>.from(gymList);
  }

  void _applyFilters() {
    List<Gym> filtered = List<Gym>.from(gymList);

    // Filter by type
    if (_selectedType != 'All') {
      filtered = filtered.where((gym) => gym.type == _selectedType).toList();
    }

    // Sort
    if (_sortBy == 'Price: Low to High') {
      filtered.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
    } else if (_sortBy == 'Price: High to Low') {
      filtered.sort((a, b) => b.monthlyPrice.compareTo(a.monthlyPrice));
    } else if (_sortBy == 'Rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    setState(() {
      _displayedGyms = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
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
                    'Default',
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
