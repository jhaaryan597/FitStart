import 'package:flutter/material.dart';

/// Responsive utility class to handle different screen sizes and orientations
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

  /// Get screen size
  static Size size(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
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

  /// Get responsive value based on orientation
  static T orientation<T>({
    required BuildContext context,
    required T portrait,
    T? landscape,
  }) {
    if (isLandscape(context) && landscape != null) {
      return landscape;
    }
    return portrait;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double size) {
    double multiplier = 1.0;

    if (isDesktop(context)) {
      multiplier = 1.2;
    } else if (isTablet(context)) {
      multiplier = 1.1;
    }

    // Adjust for landscape mode on mobile
    if (isMobile(context) && isLandscape(context)) {
      multiplier *= 0.9;
    }

    return size * multiplier;
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double space) {
    double multiplier = 1.0;

    if (isDesktop(context)) {
      multiplier = 1.5;
    } else if (isTablet(context)) {
      multiplier = 1.25;
    }

    // Adjust for landscape mode
    if (isLandscape(context) && isMobile(context)) {
      multiplier *= 0.8;
    }

    return space * multiplier;
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
    double multiplier = 1.0;

    if (isDesktop(context)) {
      multiplier = 1.5;
    } else if (isTablet(context)) {
      multiplier = 1.25;
    }

    // Adjust for landscape mode
    if (isLandscape(context) && isMobile(context)) {
      multiplier *= 0.8;
    }

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

  /// Get safe area adjusted height
  static double safeHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
  }

  /// Get safe area adjusted width
  static double safeWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right;
  }
}
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

/// Responsive SafeArea wrapper that handles all orientations properly
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  const ResponsiveSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In landscape mode, we need to handle left/right insets as well
    final isLandscape = ResponsiveUtils.isLandscape(context);

    return SafeArea(
      top: top,
      bottom: bottom,
      left: isLandscape ? left : false, // Only apply left/right in landscape
      right: isLandscape ? right : false,
      minimum: minimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}

/// Responsive Scaffold that handles SafeArea and orientation changes
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool useSafeArea;

  const ResponsiveScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.useSafeArea = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget scaffold = Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );

    // Wrap with ResponsiveSafeArea if requested
    if (useSafeArea) {
      scaffold = ResponsiveSafeArea(
        child: scaffold,
      );
    }

    return scaffold;
  }
}

/// Orientation-aware responsive container
class OrientationResponsive extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;

  const OrientationResponsive({
    Key? key,
    required this.portrait,
    this.landscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLandscape(context) && landscape != null) {
      return landscape!;
    }
    return portrait;
  }
}
