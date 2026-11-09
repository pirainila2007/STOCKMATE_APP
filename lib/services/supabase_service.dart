import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/stock_movement.dart';

/// An error whose message can be shown to the user as-is.
class StockException implements Exception {
  final String message;

  const StockException(this.message);

  @override
  String toString() => message;
}

/// Single source of truth for products, sales and stock movements.
///
/// * Data is always cached on the device (SharedPreferences).
/// * When [AppConstants.supabaseUrl] / [AppConstants.supabaseAnonKey] are
///   filled in, every change is also saved to Supabase so any device sees the
///   same data. If the cloud save fails nothing is changed, so the device and
///   the cloud never drift apart.
/// * Screens listen to this object and rebuild when anything changes.
class SupabaseService extends ChangeNotifier {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  final Uuid _uuid = const Uuid();

  SharedPreferences? _prefs;
  SupabaseClient? _client;
  bool _supabaseStarted = false;
  bool _cloudReady = false;
  bool _syncing = false;
  String? _syncError;

  final List<Product> _products = [];
  final List<Sale> _sales = [];
  final List<StockMovement> _movements = [];

  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<StockMovement> get movements => List.unmodifiable(_movements);

  bool get cloudEnabled => AppConstants.cloudEnabled;
  bool get cloudReady => _cloudReady;
  bool get syncing => _syncing;
  String? get syncError => _syncError;

  // ---------------------------------------------------------------------------
  // Start-up and sync
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    _loadLocal();

    if (!AppConstants.cloudEnabled) return;

    try {
      await _connectCloud().timeout(const Duration(seconds: 12));
    } catch (e) {
      _syncError = _describe(e);
    }
  }

  /// Pull the latest data from the cloud (pull-to-refresh / retry).
  Future<void> refresh() async {
    if (!AppConstants.cloudEnabled || _syncing) return;

    _syncing = true;
    notifyListeners();

    try {
      await _connectCloud();
    } catch (e) {
      _syncError = _describe(e);
    }

    _syncing = false;
    notifyListeners();
  }

  Future<void> _connectCloud() async {
    if (!_supabaseStarted) {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );

      _supabaseStarted = true;
    }

    final client = Supabase.instance.client;
    _client = client;

    final remoteProducts = await _fetchAll(client, 'products');
    final remoteSales = await _fetchAll(client, 'sales');
    final remoteMovements = await _fetchAll(client, 'stock_movements');

    final firstConnect = !_cloudReady;
    final cloudIsEmpty =
        remoteProducts.isEmpty &&
        remoteSales.isEmpty &&
        remoteMovements.isEmpty;
    final deviceHasData =
        _products.isNotEmpty || _sales.isNotEmpty || _movements.isNotEmpty;

    if (firstConnect && cloudIsEmpty && deviceHasData) {
      // First time the cloud is switched on: upload what is already here.
      if (_products.isNotEmpty) {
        await client
            .from('products')
            .upsert(_products.map(_productRow).toList());
      }
      if (_sales.isNotEmpty) {
        await client.from('sales').upsert(_sales.map(_saleRow).toList());
      }
      if (_movements.isNotEmpty) {
        await client
            .from('stock_movements')
            .upsert(_movements.map(_movementRow).toList());
      }
    } else {
      _products
        ..clear()
        ..addAll(remoteProducts.map(_productFromRow));
      _sales
        ..clear()
        ..addAll(remoteSales.map(_saleFromRow));
      _movements
        ..clear()
        ..addAll(remoteMovements.map(_movementFromRow));

      await _saveLocal(products: true, sales: true, movements: true);
    }

    _cloudReady = true;
    _syncError = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _fetchAll(
    SupabaseClient client,
    String table,
  ) async {
    const pageSize = 1000;
    final all = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final rows = await client
          .from(table)
          .select()
          .order('created_at', ascending: false)
          .order('id')
          .range(from, from + pageSize - 1);

      all.addAll(rows);
      if (rows.length < pageSize) break;
      from += pageSize;
    }

    return all;
  }

  /// Runs [action] against Supabase. Does nothing when the cloud is off.
  Future<void> _cloud(
    Future<void> Function(SupabaseClient client) action,
  ) async {
    if (!AppConstants.cloudEnabled) return;

    try {
      if (!_cloudReady) await _connectCloud();
      await action(_client!);
      _syncError = null;
    } catch (e) {
      _syncError = _describe(e);
      notifyListeners();
      throw StockException(
        'Could not reach the cloud, so nothing was saved. '
        'Check your internet and try again. (${_describe(e)})',
      );
    }
  }

  String _describe(Object error) {
    if (error is PostgrestException) return error.message;

    final text = error.toString();
    return text.length > 140 ? '${text.substring(0, 140)}...' : text;
  }

  // ---------------------------------------------------------------------------
  // Local cache
  // ---------------------------------------------------------------------------

  void _loadLocal() {
    _products
      ..clear()
      ..addAll(_readList(AppConstants.productsKey).map(Product.fromJson));

    _sales
      ..clear()
      ..addAll(_readList(AppConstants.salesKey).map(Sale.fromJson));

    _movements
      ..clear()
      ..addAll(
        _readList(AppConstants.movementsKey).map(StockMovement.fromJson),
      );
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs?.getString(key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal({
    bool products = false,
    bool sales = false,
    bool movements = false,
  }) async {
    final prefs = _prefs!;

    if (products) {
      await prefs.setString(
        AppConstants.productsKey,
        jsonEncode(_products.map((item) => item.toJson()).toList()),
      );
    }
    if (sales) {
      await prefs.setString(
        AppConstants.salesKey,
        jsonEncode(_sales.map((item) => item.toJson()).toList()),
      );
    }
    if (movements) {
      await prefs.setString(
        AppConstants.movementsKey,
        jsonEncode(_movements.map((item) => item.toJson()).toList()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Row mapping (Dart <-> Supabase columns)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _productRow(Product p) => {
    'id': p.id,
    'name': p.name,
    'sku': p.sku,
    'category': p.category,
    'cost_price': p.costPrice,
    'selling_price': p.sellingPrice,
    'quantity': p.quantity,
    'low_stock_limit': p.lowStockLimit,
  };

  Product _productFromRow(Map<String, dynamic> r) => Product(
    id: r['id'] as String,
    name: r['name'] as String? ?? '',
    sku: r['sku'] as String? ?? '',
    category: r['category'] as String? ?? 'General',
    costPrice: (r['cost_price'] as num?)?.toDouble() ?? 0,
    sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0,
    quantity: (r['quantity'] as num?)?.toInt() ?? 0,
    lowStockLimit: (r['low_stock_limit'] as num?)?.toInt() ?? 5,
  );

  Map<String, dynamic> _saleRow(Sale s) => {
    'id': s.id,
    'product_id': s.productId,
    'product_name': s.productName,
    'quantity': s.quantity,
    'unit_price': s.unitPrice,
    'cost_price': s.costPrice,
    'created_at': s.createdAt.toUtc().toIso8601String(),
  };

  Sale _saleFromRow(Map<String, dynamic> r) => Sale(
    id: r['id'] as String,
    productId: r['product_id'] as String? ?? '',
    productName: r['product_name'] as String? ?? '',
    quantity: (r['quantity'] as num).toInt(),
    unitPrice: (r['unit_price'] as num).toDouble(),
    costPrice: (r['cost_price'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  Map<String, dynamic> _movementRow(StockMovement m) => {
    'id': m.id,
    'product_id': m.productId,
    'product_name': m.productName,
    'type': m.type,
    'quantity': m.quantity,
    'unit_price': m.unitPrice,
    'created_at': m.createdAt.toUtc().toIso8601String(),
  };

  StockMovement _movementFromRow(Map<String, dynamic> r) => StockMovement(
    id: r['id'] as String,
    productId: r['product_id'] as String? ?? '',
    productName: r['product_name'] as String? ?? '',
    type: r['type'] as String,
    quantity: (r['quantity'] as num).toInt(),
    unitPrice: (r['unit_price'] as num).toDouble(),
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  // ---------------------------------------------------------------------------
  // Read helpers used by the screens
  // ---------------------------------------------------------------------------

  Product? findProduct(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  List<Product> get lowStockProducts {
    final list = _products.where((p) => p.isLowStock).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    return list;
  }

  int get stockUnits => _products.fold<int>(0, (sum, p) => sum + p.quantity);

  double get stockCostValue =>
      _products.fold<double>(0, (sum, p) => sum + p.quantity * p.costPrice);

  double get stockRetailValue =>
      _products.fold<double>(0, (sum, p) => sum + p.quantity * p.sellingPrice);

  bool _isToday(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  List<Sale> get _todaySales =>
      _sales.where((sale) => _isToday(sale.createdAt)).toList();

  int get todaySalesCount => _todaySales.length;

  int get todayUnits => _todaySales.fold<int>(0, (sum, s) => sum + s.quantity);

  double get todayRevenue =>
      _todaySales.fold<double>(0, (sum, s) => sum + s.total);

  double get todayProfit =>
      _todaySales.fold<double>(0, (sum, s) => sum + s.profit);

  // ---------------------------------------------------------------------------
  // Changes
  // ---------------------------------------------------------------------------

  void _putProduct(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) {
      _products.insert(0, product);
    } else {
      _products[index] = product;
    }
  }

  bool _skuTaken(String sku, {String? exceptId}) {
    if (sku.isEmpty) return false;

    return _products.any(
      (p) => p.id != exceptId && p.sku.toLowerCase() == sku.toLowerCase(),
    );
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    required String category,
    required double costPrice,
    required double sellingPrice,
    required int quantity,
    required int lowStockLimit,
  }) async {
    final cleanName = name.trim();
    final cleanSku = sku.trim();

    if (cleanName.isEmpty) {
      throw const StockException('Product name is required.');
    }
    if (_skuTaken(cleanSku)) {
      throw StockException(
        'SKU "$cleanSku" is already used by another product.',
      );
    }

    final product = Product(
      id: _uuid.v4(),
      name: cleanName,
      sku: cleanSku,
      category: category.trim().isEmpty ? 'General' : category.trim(),
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      lowStockLimit: lowStockLimit,
    );

    final movement = quantity > 0
        ? StockMovement(
            id: _uuid.v4(),
            productId: product.id,
            productName: product.name,
            type: 'STOCK_IN',
            quantity: quantity,
            unitPrice: costPrice,
            createdAt: DateTime.now(),
          )
        : null;

    await _cloud((client) async {
      await client.from('products').upsert(_productRow(product));
      if (movement != null) {
        await client.from('stock_movements').upsert(_movementRow(movement));
      }
    });

    _products.insert(0, product);
    if (movement != null) _movements.insert(0, movement);

    await _saveLocal(products: true, movements: movement != null);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    if (findProduct(product.id) == null) {
      throw const StockException('Product not found.');
    }
    if (product.name.trim().isEmpty) {
      throw const StockException('Product name is required.');
    }
    if (_skuTaken(product.sku, exceptId: product.id)) {
      throw StockException(
        'SKU "${product.sku}" is already used by another product.',
      );
    }

    await _cloud((client) async {
      await client.from('products').upsert(_productRow(product));
    });

    _putProduct(product);
    await _saveLocal(products: true);
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _cloud((client) async {
      await client.from('products').delete().eq('id', id);
    });

    _products.removeWhere((product) => product.id == id);
    await _saveLocal(products: true);
    notifyListeners();
  }

  Future<void> addStock(String productId, int quantity) async {
    final product = findProduct(productId);

    if (product == null) throw const StockException('Product not found.');
    if (quantity <= 0) {
      throw const StockException('Quantity must be above zero.');
    }

    final updated = product.copyWith(quantity: product.quantity + quantity);

    final movement = StockMovement(
      id: _uuid.v4(),
      productId: product.id,
      productName: product.name,
      type: 'STOCK_IN',
      quantity: quantity,
      unitPrice: product.costPrice,
      createdAt: DateTime.now(),
    );

    await _cloud((client) async {
      await client.from('products').upsert(_productRow(updated));
      await client.from('stock_movements').upsert(_movementRow(movement));
    });

    _putProduct(updated);
    _movements.insert(0, movement);

    await _saveLocal(products: true, movements: true);
    notifyListeners();
  }

  Future<void> recordSale(String productId, int quantity) async {
    final product = findProduct(productId);

    if (product == null) {
      throw const StockException('Product not found.');
    }
    if (quantity <= 0) {
      throw const StockException('Enter a valid quantity.');
    }
    if (quantity > product.quantity) {
      throw StockException('Not enough stock. Available: ${product.quantity}');
    }

    final now = DateTime.now();

    final sale = Sale(
      id: _uuid.v4(),
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: product.sellingPrice,
      costPrice: product.costPrice,
      createdAt: now,
    );

    final movement = StockMovement(
      id: _uuid.v4(),
      productId: product.id,
      productName: product.name,
      type: 'SALE',
      quantity: quantity,
      unitPrice: product.sellingPrice,
      createdAt: now,
    );

    // Automatically reduce the remaining stock.
    final updated = product.copyWith(quantity: product.quantity - quantity);

    await _cloud((client) async {
      await client.from('sales').upsert(_saleRow(sale));
      await client.from('stock_movements').upsert(_movementRow(movement));
      await client.from('products').upsert(_productRow(updated));
    });

    _putProduct(updated);
    _sales.insert(0, sale);
    _movements.insert(0, movement);

    await _saveLocal(products: true, sales: true, movements: true);
    notifyListeners();
  }
}
