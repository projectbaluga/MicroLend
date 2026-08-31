import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding = EdgeInsets.zero,
  });

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 700;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1000;
  }

  static bool isExtraLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1400;
  }

  static int gridColumnsForWidth(double width) {
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
