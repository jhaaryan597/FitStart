import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';
import 'package:FitStart/components/reusable/location_selection_bottom_sheet.dart';

/// Reusable location display widget
class LocationDisplay extends StatefulWidget {
  final String? address;
  final Function(String)? onLocationSubmitted;
  final bool showSetLocationPrompt;

  const LocationDisplay({
    Key? key,
    this.address,
    this.onLocationSubmitted,
    this.showSetLocationPrompt = false,
  }) : super(key: key);

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionBottomSheet(
        currentAddress: widget.address,
        onLocationSelected: (address) {
          if (widget.onLocationSubmitted != null) {
            widget.onLocationSubmitted!(address);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.address != null && widget.address!.isNotEmpty) {
      return GestureDetector(
        onTap: _showLocationBottomSheet,
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
            Icon(
              Icons.keyboard_arrow_down,
              size: ResponsiveUtils.spacing(context, 16),
              color: primaryColor500,
            ),
          ],
        ),
      );
    }

    if (widget.showSetLocationPrompt) {
      return GestureDetector(
        onTap: _showLocationBottomSheet,
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
