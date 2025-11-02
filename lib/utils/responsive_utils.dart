import 'package:flutter/material.dart';

/// Responsive utility class to handle different screen sizes
/// Breakpoints: Mobile (<600), Tablet (600-1024), Desktop (>1024)
class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return width(context) < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return width(context) >= mobileBreakpoint &&
        width(context) < tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return width(context) >= tabletBreakpoint;
  }

  /// Get responsive value based on screen size
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double size) {
    if (isDesktop(context)) {
      return size * 1.2;
    }
    if (isTablet(context)) {
      return size * 1.1;
    }
    return size;
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double space) {
    if (isDesktop(context)) {
      return space * 1.5;
    }
    if (isTablet(context)) {
      return space * 1.25;
    }
    return space;
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final multiplier =
        isDesktop(context) ? 1.5 : (isTablet(context) ? 1.25 : 1.0);

    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * multiplier,
      top: (top ?? vertical ?? 0) * multiplier,
      right: (right ?? horizontal ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? 0) * multiplier,
    );
  }

  /// Get grid cross axis count based on screen size
  static int gridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int? tablet,
    int? desktop,
  }) {
    return responsive(
      context: context,
      mobile: mobile,
      tablet: tablet ?? (mobile + 1),
      desktop: desktop ?? (mobile + 2),
    );
  }

  /// Get responsive card width
  static double cardWidth(BuildContext context, {double maxWidth = 400}) {
    final screenWidth = width(context);
    if (isDesktop(context)) {
      return maxWidth;
    }
    if (isTablet(context)) {
      return screenWidth * 0.45;
    }
    return screenWidth - 32; // Mobile with padding
  }

  /// Get responsive container max width for content
  static double maxContentWidth(BuildContext context) {
    return responsive(
      context: context,
      mobile: width(context),
      tablet: 720,
      desktop: 1200,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      desktop;

  const ResponsiveBuilder({
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
          return desktop!(context, constraints);
        }
        if (constraints.maxWidth >= ResponsiveUtils.mobileBreakpoint &&
            tablet != null) {
          return tablet!(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridCrossAxisCount(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: ResponsiveUtils.spacing(context, spacing),
      mainAxisSpacing: ResponsiveUtils.spacing(context, runSpacing),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Responsive container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.maxContentWidth(context),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double size;
  final Axis axis;

  const ResponsiveSpacing({
    Key? key,
    required this.size,
    this.axis = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.spacing(context, size);
    return SizedBox(
      width: axis == Axis.horizontal ? spacing : 0,
      height: axis == Axis.vertical ? spacing : 0,
    );
  }
}
