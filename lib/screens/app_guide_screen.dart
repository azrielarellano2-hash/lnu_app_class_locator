import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_shell.dart';

/// How-to guide shown once after tapping Enter APP on the welcome screen.
class AppGuideScreen extends StatefulWidget {
  const AppGuideScreen({super.key});

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
  static const _deepForest = Color(0xFF06180E);
  static const _leafMid = Color(0xFF1B5E20);
  static const _leafBright = Color(0xFF43A047);

  final _pageController = PageController();
  int _page = 0;

  static const _pages = <_GuidePage>[
    _GuidePage(
      icon: Icons.school_rounded,
      title: 'Welcome to LNU SmartPath',
      body:
          'Manage your class schedule from your enrolment e-slip. '
          'Everything stays on your phone — no internet required.',
    ),
    _GuidePage(
      icon: Icons.document_scanner_outlined,
      title: '1. Scan your e-slip',
      body:
          'Open the Extractor tab (bottom navigation). Tap Scan e-slip, '
          'then choose Camera or Gallery. Photograph the full enrolment table '
          'in good lighting, flat and in frame.',
    ),
    _GuidePage(
      icon: Icons.fact_check_outlined,
      title: '2. Review & confirm',
      body:
          'Check each row’s confidence (green / yellow / red). Tap any field '
          'to fix OCR mistakes, then tap Confirm & save schedule. '
          'Nothing is saved until you confirm.',
    ),
    _GuidePage(
      icon: Icons.calendar_month,
      title: '3. Weekly schedule',
      body:
          'On the Schedule tab, see your week in a time grid (Mon–Sat). '
          'Tap any class block for details, teacher profile, and to add '
          'quizzes, reminders, activities, or notes.',
    ),
    _GuidePage(
      icon: Icons.print_outlined,
      title: '4. Printable e-slip',
      body:
          'After saving, or anytime from Schedule → Official schedule, '
          'preview your enrolment table on screen. Use Print / Export PDF '
          'when it looks correct.',
    ),
    _GuidePage(
      icon: Icons.person_outline,
      title: '5. Profiles & reminders',
      body:
          'Student profile (person icon on Dashboard or Schedule): edit your '
          'info and stats. Instructors get profiles from your schedule — tap '
          'a name to view or edit. Reminders notify you on this device.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      _goHome();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepForest, _leafMid, _leafBright],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _goHome,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_page + 1} / ${_pages.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _GuidePageView(page: _pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Get started' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _GuidePageView extends StatelessWidget {
  const _GuidePageView({required this.page});

  final _GuidePage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Icon(page.icon, size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
