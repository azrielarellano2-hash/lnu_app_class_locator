import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/welcome_screen.dart';
import 'state/app_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = AppRepository();
  await repo.init();
  runApp(
    ChangeNotifierProvider.value(
      value: repo,
      child: const LnuSmartPathApp(),
    ),
  );
}

class LnuSmartPathApp extends StatelessWidget {
  const LnuSmartPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LNU SmartPath',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WelcomeScreen(),
    );
  }
}
