import 'package:flutter/material.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Global responsive wrapper for the entire app
/// This ensures all screens are properly responsive and handle SafeArea correctly
class AppResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final bool handleOrientation;

  const AppResponsiveWrapper({
    Key? key,
    required this.child,
    this.useSafeArea = true,
    this.handleOrientation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;

    // Handle orientation changes if enabled
    if (handleOrientation) {
      wrappedChild = OrientationBuilder(
        builder: (context, orientation) {
          return wrappedChild;
        },
      );
    }

    // Apply SafeArea if enabled
    if (useSafeArea) {
      wrappedChild = ResponsiveSafeArea(
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }
}

/// Responsive text widget that automatically adjusts font size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = style?.copyWith(
      fontSize: style?.fontSize != null
          ? ResponsiveUtils.fontSize(context, style!.fontSize!)
          : null,
    );

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ResponsivePadding({
    Key? key,
    required this.child,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.padding(
        context,
        all: padding.top == padding.bottom && padding.left == padding.right
            ? padding.top
            : null,
        horizontal: padding.left == padding.right ? padding.left : null,
        vertical: padding.top == padding.bottom ? padding.top : null,
        left: padding.left,
        top: padding.top,
        right: padding.right,
        bottom: padding.bottom,
      ),
      child: child,
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({
    Key? key,
    this.width,
    this.height,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width != null ? ResponsiveUtils.spacing(context, width!) : null,
      height: height != null ? ResponsiveUtils.spacing(context, height!) : null,
      child: child,
    );
  }
}

/// Responsive elevated button
class ResponsiveElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final double? borderRadius;

  const ResponsiveElevatedButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.style,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = ElevatedButton.styleFrom(
      padding: ResponsiveUtils.padding(context, horizontal: 16, vertical: 12),
      shape: borderRadius != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius!),
            )
          : null,
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style?.merge(defaultStyle) ?? defaultStyle,
      child: child,
    );
  }
}

/// Responsive layout builder that provides different layouts for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveUtils.tabletBreakpoint &&
            desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= ResponsiveUtils.mobileBreakpoint &&
            tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}