import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable custom card with responsive design
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        ResponsiveUtils.padding(
          context,
          all: 16,
        );

    final responsiveMargin = margin ??
        ResponsiveUtils.padding(
          context,
          horizontal: 16,
          vertical: 8,
        );

    final card = Container(
      margin: responsiveMargin,
      decoration: BoxDecoration(
        color: color ?? colorWhite,
        borderRadius: borderRadius ?? BorderRadius.circular(borderRadiusSize),
        boxShadow: [
          BoxShadow(
            color: primaryColor500.withOpacity(0.1),
            blurRadius: elevation ?? 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(borderRadiusSize),
        child: card,
      );
    }

    return card;
  }
}
