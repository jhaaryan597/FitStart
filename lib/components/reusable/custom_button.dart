import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

/// Reusable custom button with responsive design
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveHeight = _getHeight(context);
    final responsivePadding = _getPadding(context);
    final responsiveFontSize = _getFontSize(context);

    return SizedBox(
      width: width,
      height: height ?? responsiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          elevation:
              type == ButtonType.outline || type == ButtonType.text ? 0 : 2,
          padding: responsivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSize),
            side: type == ButtonType.outline
                ? BorderSide(color: primaryColor500, width: 2)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getForegroundColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: responsiveFontSize + 2),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  ],
                  Text(
                    text,
                    style: buttonTextStyle.copyWith(
                      fontSize: responsiveFontSize,
                      color: _getForegroundColor(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _getHeight(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return ResponsiveUtils.spacing(context, 36);
      case ButtonSize.medium:
        return ResponsiveUtils.spacing(context, 48);
      case ButtonSize.large:
        return ResponsiveUtils.spacing(context, 56);
    }
  }

  EdgeInsets _getPadding(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return ResponsiveUtils.padding(context, horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return ResponsiveUtils.padding(context, horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return ResponsiveUtils.padding(context, horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return ResponsiveUtils.fontSize(context, 12);
      case ButtonSize.medium:
        return ResponsiveUtils.fontSize(context, 14);
      case ButtonSize.large:
        return ResponsiveUtils.fontSize(context, 16);
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return primaryColor500;
      case ButtonType.secondary:
        return lightGreen;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    switch (type) {
      case ButtonType.primary:
        return colorWhite;
      case ButtonType.secondary:
        return textPrimary;
      case ButtonType.outline:
        return primaryColor500;
      case ButtonType.text:
        return primaryColor500;
    }
  }
}
