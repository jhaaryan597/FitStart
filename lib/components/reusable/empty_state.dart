import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable empty state widget with responsive design
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.padding(context, all: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.spacing(context, 80),
              color: textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              title,
              style: subTitleTextStyle.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 18),
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                message!,
                style: descTextStyle.copyWith(
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onActionPressed != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor500,
                  foregroundColor: colorWhite,
                  padding: ResponsiveUtils.padding(
                    context,
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: buttonTextStyle.copyWith(
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
