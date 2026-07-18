import 'package:flutter/material.dart';

const appAlwaysScrollablePhysics = AlwaysScrollableScrollPhysics(
  parent: ClampingScrollPhysics(),
);

final class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
