import 'package:flutter/material.dart';

import '../navigation/home_tabs.dart';
import '../navigation/tab_navigator.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/scan_tab.dart';

/// Root shell: persistent bottom nav + per-tab navigation stacks.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = HomeTabs.dashboard;

  void selectTab(int index) {
    if (index < HomeTabs.dashboard || index > HomeTabs.scan) return;
    if (_index == index) {
      TabNavigatorKeys.forIndex(index).currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  Route<dynamic> _onGenerateRoute(int tabIndex, RouteSettings settings) {
    Widget page;
    switch (tabIndex) {
      case HomeTabs.dashboard:
        page = DashboardTab(onOpenTab: selectTab);
        break;
      case HomeTabs.schedule:
        page = const ScheduleTab();
        break;
      case HomeTabs.scan:
      default:
        page = ScanTab(onOpenTab: selectTab);
        break;
    }
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _TabNavigator(
            navigatorKey: TabNavigatorKeys.dashboard,
            onGenerateRoute: (s) => _onGenerateRoute(HomeTabs.dashboard, s),
          ),
          _TabNavigator(
            navigatorKey: TabNavigatorKeys.schedule,
            onGenerateRoute: (s) => _onGenerateRoute(HomeTabs.schedule, s),
          ),
          _TabNavigator(
            navigatorKey: TabNavigatorKeys.scan,
            onGenerateRoute: (s) => _onGenerateRoute(HomeTabs.scan, s),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner),
              label: 'Extractor',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.onGenerateRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Route<dynamic> Function(RouteSettings) onGenerateRoute;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      initialRoute: Navigator.defaultRouteName,
    );
  }
}
