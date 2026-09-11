import '../../../core/database/app_database.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double? customUnitPrice;

  const CartItem({
    required this.product,
    required this.quantity,
    this.customUnitPrice,
  });

  double get unitPrice => customUnitPrice ?? product.sellingPrice;
  double get subtotal => unitPrice * quantity;
  double get totalCost => product.costPrice * quantity;
  double get profitMargin => subtotal - totalCost;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? customUnitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      customUnitPrice: customUnitPrice ?? this.customUnitPrice,
    );
  }
}
