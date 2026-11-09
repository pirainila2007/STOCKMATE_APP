import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmate/app.dart';
import 'package:stockmate/core/theme/app_theme.dart';
import 'package:stockmate/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StockMate dashboard opens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppTheme.useGoogleFonts = false;
    await SupabaseService.instance.init();

    await tester.pumpWidget(const StockMateApp());
    await tester.pumpAndSettle();

    expect(find.text('StockMate'), findsOneWidget);
    expect(find.text('Shop Overview'), findsOneWidget);
    expect(find.text('Total Products'), findsOneWidget);
  });
}