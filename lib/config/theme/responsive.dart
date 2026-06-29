import 'package:flutter/widgets.dart';

abstract class Responsive {
  static const double _mobile = 600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobile;

  static EdgeInsets pagePadding(BuildContext context) => isMobile(context)
      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
      : const EdgeInsets.all(32);
}
