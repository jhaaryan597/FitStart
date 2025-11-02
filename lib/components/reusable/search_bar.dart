import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable search bar widget
class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;

  const CustomSearchBar({
    Key? key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.showClearButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(borderRadiusSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: ResponsiveUtils.spacing(context, 10),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: normalTextStyle.copyWith(
          fontSize: ResponsiveUtils.fontSize(context, 14),
        ),
        decoration: InputDecoration(
          hintText: hintText ?? "Search...",
          hintStyle: descTextStyle.copyWith(
            color: textSecondary,
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: primaryColor500,
            size: ResponsiveUtils.spacing(context, 24),
          ),
          suffixIcon: showClearButton
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: ResponsiveUtils.spacing(context, 20),
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: ResponsiveUtils.padding(
            context,
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
