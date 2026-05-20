import 'package:flutter/material.dart';

/// Keys for each bottom-nav tab's nested [Navigator].
class TabNavigatorKeys {
  TabNavigatorKeys._();

  static final dashboard = GlobalKey<NavigatorState>();
  static final schedule = GlobalKey<NavigatorState>();
  static final scan = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> forIndex(int index) {
    switch (index) {
      case 0:
        return dashboard;
      case 1:
        return schedule;
      case 2:
        return scan;
      default:
        return dashboard;
    }
  }
}

/// Pushes [route] on the current tab stack (bottom nav stays visible).
Future<T?> pushOnTabNavigator<T>(BuildContext context, Route<T> route) {
  return Navigator.of(context).push(route);
}
