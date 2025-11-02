import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable section header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? badge;
  final Widget? trailing;
  final EdgeInsets? padding;

  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.badge,
    this.trailing,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          ResponsiveUtils.padding(
            context,
            horizontal: 16,
            vertical: 8,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: primaryColor500,
                  size: ResponsiveUtils.spacing(context, 20),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              ],
              Text(
                title,
                style: subTitleTextStyle.copyWith(
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                ),
              ),
              if (badge != null) ...[
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Container(
                  padding: ResponsiveUtils.padding(
                    context,
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: descTextStyle.copyWith(
                      fontSize: ResponsiveUtils.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                      color: primaryColor500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
