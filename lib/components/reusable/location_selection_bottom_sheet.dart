import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';
import 'package:FitStart/utils/location_service.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectionBottomSheet extends StatefulWidget {
  final String? currentAddress;
  final Function(String) onLocationSelected;

  const LocationSelectionBottomSheet({
    Key? key,
    this.currentAddress,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelectionBottomSheet> createState() => _LocationSelectionBottomSheetState();
}

class _LocationSelectionBottomSheetState extends State<LocationSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Placemark> _suggestions = [];
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to get current position');
      }
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = LocationService.formatAddress(placemark);
        widget.onLocationSelected(address);
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get current location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGettingCurrentLocation = false;
      });
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use geocoding to find locations
      final locations = await locationFromAddress(query);
      final placemarks = await Future.wait(
        locations.map((location) => placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        )),
      );

      setState(() {
        _suggestions = placemarks.expand((list) => list).toList();
      });
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _suggestions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectLocation(Placemark placemark) {
    final address = LocationService.formatAddress(placemark);
    widget.onLocationSelected(address);
    Navigator.of(context).pop();
  }

  void _submitManualLocation() {
    final location = _searchController.text.trim();
    if (location.isNotEmpty) {
      widget.onLocationSelected(location);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, // Start at 90% of screen height (near full screen)
      minChildSize: 0.4, // Minimum 40% when dragged down
      maxChildSize: 0.95, // Maximum 95% of screen height
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
        children: [
          // Header
          Container(
            padding: ResponsiveUtils.padding(context, all: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Select Location',
                  style: titleTextStyle.copyWith(
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: textSecondary,
                    size: ResponsiveUtils.spacing(context, 24),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: ResponsiveUtils.padding(context, all: 16),
              children: [
                  // Current Location Button
                  Container(
                    margin: ResponsiveUtils.padding(context, bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: _isGettingCurrentLocation ? null : _getCurrentLocation,
                      icon: _isGettingCurrentLocation
                          ? SizedBox(
                              width: ResponsiveUtils.spacing(context, 20),
                              height: ResponsiveUtils.spacing(context, 20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              size: ResponsiveUtils.spacing(context, 20),
                            ),
                      label: Text(
                        _isGettingCurrentLocation ? 'Getting location...' : 'Use current location',
                        style: buttonTextStyle.copyWith(
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor500,
                        foregroundColor: Colors.white,
                        padding: ResponsiveUtils.padding(context, horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                  // Search Section
                  Text(
                    'Search for a location',
                    style: descTextStyle.copyWith(
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                  // Search TextField
                  TextField(
                    controller: _searchController,
                    style: descTextStyle.copyWith(
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter city, address, or landmark',
                      hintStyle: descTextStyle.copyWith(
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: textSecondary.withOpacity(0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textSecondary,
                        size: ResponsiveUtils.spacing(context, 20),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = [];
                                });
                              },
                              icon: Icon(
                                Icons.clear,
                                color: textSecondary,
                                size: ResponsiveUtils.spacing(context, 20),
                              ),
                            )
                          : null,
                      contentPadding: ResponsiveUtils.padding(context, horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor500),
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                    ),
                    onChanged: _searchLocations,
                    onSubmitted: (_) => _submitManualLocation(),
                  ),

                  // Loading indicator
                  if (_isLoading)
                    Container(
                      padding: ResponsiveUtils.padding(context, vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor500),
                        ),
                      ),
                    ),

                  // Suggestions List
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: ResponsiveUtils.padding(context, top: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: textSecondary.withOpacity(0.1)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final placemark = _suggestions[index];
                          final address = LocationService.formatAddress(placemark);

                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: primaryColor500,
                              size: ResponsiveUtils.spacing(context, 20),
                            ),
                            title: Text(
                              address,
                              style: descTextStyle.copyWith(
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: textPrimary,
                              ),
                            ),
                            subtitle: placemark.locality != null && placemark.locality!.isNotEmpty
                                ? Text(
                                    placemark.locality!,
                                    style: descTextStyle.copyWith(
                                      fontSize: ResponsiveUtils.fontSize(context, 12),
                                      color: textSecondary,
                                    ),
                                  )
                                : null,
                            onTap: () => _selectLocation(placemark),
                            contentPadding: ResponsiveUtils.padding(context, horizontal: 16, vertical: 4),
                            dense: true,
                          );
                        },
                      ),
                    ),

                  // Manual entry option
                  if (_searchController.text.isNotEmpty && _suggestions.isEmpty && !_isLoading)
                    Container(
                      margin: ResponsiveUtils.padding(context, top: 16),
                      padding: ResponsiveUtils.padding(context, all: 16),
                      decoration: BoxDecoration(
                        color: primaryColor500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor500.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_location,
                            color: primaryColor500,
                            size: ResponsiveUtils.spacing(context, 20),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                          Expanded(
                            child: Text(
                              'Use "${_searchController.text}" as location',
                              style: descTextStyle.copyWith(
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _submitManualLocation,
                            child: Text(
                              'Select',
                              style: buttonTextStyle.copyWith(
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: primaryColor500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Current location display
                  if (widget.currentAddress != null)
                    Container(
                      margin: ResponsiveUtils.padding(context, top: 16),
                      padding: ResponsiveUtils.padding(context, all: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: ResponsiveUtils.spacing(context, 20),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current location',
                                  style: descTextStyle.copyWith(
                                    fontSize: ResponsiveUtils.fontSize(context, 12),
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.currentAddress!,
                                  style: descTextStyle.copyWith(
                                    fontSize: ResponsiveUtils.fontSize(context, 14),
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
            ),
          ),
        ],
          ),
        );
      },
    );
  }
}