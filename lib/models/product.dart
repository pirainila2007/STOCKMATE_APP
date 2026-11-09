class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int lowStockLimit;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    this.lowStockLimit = 5,
  });

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? quantity,
    int? lowStockLimit,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
    );
  }

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity <= lowStockLimit;

  /// Profit as a share of the selling price (0 - 1).
  double get margin =>
      sellingPrice <= 0 ? 0 : (sellingPrice - costPrice) / sellingPrice;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category': category,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'quantity': quantity,
    'lowStockLimit': lowStockLimit,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lowStockLimit: (json['lowStockLimit'] as num?)?.toInt() ?? 5,
  );
}