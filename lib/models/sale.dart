class Sale {
  final String id;
  final String productId;
  final String? productName;
  final int quantity;
  final double unitPrice; // selling price per unit
  final double costPrice; // cost per unit
  final DateTime createdAt;

  const Sale({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0,
    required this.createdAt,
  });

  double get total => unitPrice * quantity;

  double get profit => (unitPrice - costPrice) * quantity;

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'].toString(),
        productId: json['product_id'].toString(),
        productName: json['product_name'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        if (productName != null) 'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'cost_price': costPrice,
        'created_at': createdAt.toIso8601String(),
      };

  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? costPrice,
    DateTime? createdAt,
  }) =>
      Sale(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        costPrice: costPrice ?? this.costPrice,
        createdAt: createdAt ?? this.createdAt,
      );
}