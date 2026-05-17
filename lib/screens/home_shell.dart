import 'package:flutter/material.dart';

import '../navigation/home_tabs.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/scan_tab.dart';

/// Bottom navigation: Dashboard, Schedule, Extractor (e-slip).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = HomeTabs.dashboard;

  void selectTab(int index) {
    if (index < HomeTabs.dashboard || index > HomeTabs.scan) return;
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final hideBottomNav = _index == HomeTabs.scan;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardTab(onOpenTab: selectTab),
          const ScheduleTab(),
          ScanTab(onOpenTab: selectTab),
        ],
      ),
      bottomNavigationBar: hideBottomNav
          ? null
          : NavigationBar(
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
    );
  }
}
