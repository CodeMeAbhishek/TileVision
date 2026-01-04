import 'package:flutter/material.dart';

/// Helper class for responsive UI design across different device sizes
class ResponsiveHelper {
  // Breakpoints for different device sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Get responsive padding based on device type
  static EdgeInsets getPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? 14.0;
      case DeviceType.tablet:
        return tablet ?? 16.0;
      case DeviceType.desktop:
        return desktop ?? 18.0;
    }
  }

  /// Get responsive grid cross axis count for tiles
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 2; // Mobile: 2 columns
    } else if (width < tabletBreakpoint) {
      return 3; // Tablet: 3 columns
    } else {
      return 4; // Desktop: 4 columns
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? 8.0;
      case DeviceType.tablet:
        return tablet ?? 12.0;
      case DeviceType.desktop:
        return desktop ?? 16.0;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 32.0;
      case DeviceType.desktop:
        return 40.0;
    }
  }

  /// Get responsive card height
  static double getCardHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 150.0;
      case DeviceType.tablet:
        return 180.0;
      case DeviceType.desktop:
        return 200.0;
    }
  }

  /// Get responsive button padding
  static EdgeInsets getButtonPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 40, vertical: 20);
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

