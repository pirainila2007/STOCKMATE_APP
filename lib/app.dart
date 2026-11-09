import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';

class StockMateApp extends StatelessWidget {
  final Object? startupError;

  const StockMateApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: startupError == null
          ? const DashboardScreen()
          : Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'StockMate could not open its storage.\n$startupError',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }
}