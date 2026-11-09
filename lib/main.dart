import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    startupError = e;
  }

  runApp(StockMateApp(startupError: startupError));
}