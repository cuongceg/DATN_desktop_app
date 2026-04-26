import 'package:flutter/material.dart';

class AppSizes {
  // Spacing Unit & Scale
  static const double unit = 8.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double gutter = lg;
  static const double pageMargin = xl;
  static const double componentGap = md;

  // Sidebar
  static const double sidebarExpanded = 260.0;
  static const double sidebarCollapsed = 72.0;

  // Border Radius (Shapes)
  static const double radiusSmall = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  static final BorderRadius brSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius brDefault = BorderRadius.circular(radiusDefault);
  static final BorderRadius brMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius brLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius brXL = BorderRadius.circular(radiusXL);
  static final BorderRadius brFull = BorderRadius.circular(radiusFull);

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Elevation & Depth (Backdrop Blur)
  static const double blurLevel1 = 20.0;
  static const double blurLevel2 = 40.0;
  static const double blurLevel3 = 60.0;

  // Layout breakpoints
  static const double breakpointCompact = 980.0;

  // Login screen specific
  static const double formMaxWidth = 460.0;
  static const double logoSize = 80.0;
}
