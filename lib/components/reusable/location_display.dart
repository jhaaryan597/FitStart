import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable location display widget
class LocationDisplay extends StatelessWidget {
  final String? address;
  final VoidCallback onTap;
  final bool showSetLocationPrompt;

  const LocationDisplay({
    Key? key,
    this.address,
    required this.onTap,
    this.showSetLocationPrompt = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (address != null && address!.isNotEmpty) {
      return GestureDetector(
        onTap: onTap,
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
                address!,
                style: descTextStyle.copyWith(
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (showSetLocationPrompt) {
      return GestureDetector(
        onTap: onTap,
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
