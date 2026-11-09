
class AppConstants {
  AppConstants._();

  // Application details
  static const String appName = 'StockMate';
  static const String currency = 'LKR';
  static const int lowStockLimit = 5;

  // Supabase project configuration
  static const String supabaseUrl =
      'https://lmiornieycouxlgztayh.supabase.co';

  // Supabase Publishable Key
  static const String supabaseAnonKey =
      'sb_publishable_D9JQw26ExM-0zc5RmKBECg_EPHSciMw';

  // Cloud connection check
  static bool get cloudEnabled {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  // Local storage keys
  static const String productsKey =
      'stockmate_products_v1';

  static const String salesKey =
      'stockmate_sales_v1';

  static const String movementsKey =
      'stockmate_movements_v1';

  // Supabase table names
  static const String productsTable = 'products';
  static const String salesTable = 'sales';
  static const String movementsTable = 'stock_movements';
}
