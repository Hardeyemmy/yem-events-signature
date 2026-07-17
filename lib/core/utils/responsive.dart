import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 900;
    if (width >= 600) return 700;
    return width;
  }
}
