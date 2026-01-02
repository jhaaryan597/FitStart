import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable location display widget
class LocationDisplay extends StatefulWidget {
  final String? address;
  final VoidCallback onTap;
  final Function(String)? onLocationSubmitted;
  final bool showSetLocationPrompt;

  const LocationDisplay({
    Key? key,
    this.address,
    required this.onTap,
    this.onLocationSubmitted,
    this.showSetLocationPrompt = false,
  }) : super(key: key);

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  bool _isEditing = false;
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _locationController.text = widget.address ?? '';
      }
    });
  }

  void _submitLocation() {
    final location = _locationController.text.trim();
    if (location.isNotEmpty && widget.onLocationSubmitted != null) {
      widget.onLocationSubmitted!(location);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        padding: ResponsiveUtils.padding(context, all: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor500.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: ResponsiveUtils.spacing(context, 16),
                  color: primaryColor500,
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'Enter Location',
                  style: descTextStyle.copyWith(
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: descTextStyle.copyWith(
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter city, address, or landmark',
                      hintStyle: descTextStyle.copyWith(
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: textSecondary.withOpacity(0.6),
                      ),
                      contentPadding: ResponsiveUtils.padding(context, horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: primaryColor500.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: primaryColor500),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submitLocation(),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                IconButton(
                  onPressed: _submitLocation,
                  icon: Icon(
                    Icons.check,
                    size: ResponsiveUtils.spacing(context, 20),
                    color: primaryColor500,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: ResponsiveUtils.spacing(context, 32),
                    minHeight: ResponsiveUtils.spacing(context, 32),
                  ),
                ),
                IconButton(
                  onPressed: _toggleEditing,
                  icon: Icon(
                    Icons.close,
                    size: ResponsiveUtils.spacing(context, 20),
                    color: textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: ResponsiveUtils.spacing(context, 32),
                    minHeight: ResponsiveUtils.spacing(context, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (widget.address != null && widget.address!.isNotEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: ResponsiveUtils.spacing(context, 16),
              color: primaryColor500,
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
            Expanded(
              child: Text(
                widget.address!,
                style: descTextStyle.copyWith(
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            IconButton(
              onPressed: _toggleEditing,
              icon: Icon(
                Icons.edit_location,
                size: ResponsiveUtils.spacing(context, 16),
                color: primaryColor500,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: ResponsiveUtils.spacing(context, 24),
                minHeight: ResponsiveUtils.spacing(context, 24),
              ),
              tooltip: 'Enter location manually',
            ),
          ],
        ),
      );
    }

    if (widget.showSetLocationPrompt) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Row(
          children: [
            Icon(
              Icons.add_location_alt,
              size: ResponsiveUtils.spacing(context, 16),
              color: primaryColor500,
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
            Text(
              'Tap to set location',
              style: descTextStyle.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: primaryColor500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
