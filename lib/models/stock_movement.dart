class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String type;
  final int quantity;
  final double unitPrice;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'type': type,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String? ?? '',
    type: json['type'] as String,
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
