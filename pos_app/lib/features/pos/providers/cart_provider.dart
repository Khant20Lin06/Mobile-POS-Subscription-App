import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final Customer? selectedCustomer;
  final double discountAmount;
  final double taxRate; // e.g. 0.0 for 0%, 0.05 for 5%
  final String? notes;

  const CartState({
    this.items = const [],
    this.selectedCustomer,
    this.discountAmount = 0.0,
    this.taxRate = 0.0,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get taxAmount => (subtotal - discountAmount) * taxRate;
  double get totalAmount {
    final net = subtotal - discountAmount + taxAmount;
    return net < 0 ? 0.0 : net;
  }

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    Customer? Function()? selectedCustomer,
    double? discountAmount,
    double? taxRate,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: selectedCustomer != null ? selectedCustomer() : this.selectedCustomer,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Add product to cart. If already exists, increment quantity.
  void addToCart(Product product, [int quantity = 1]) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final newQty = existingItem.quantity + quantity;
      
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existingItem.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItem(product: product, quantity: quantity);
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Increment quantity by 1
  void increment(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = state.items[index];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = item.copyWith(quantity: item.quantity + 1);
      state = state.copyWith(items: updatedList);
    }
  }

  /// Decrement quantity by 1. If quantity reaches 0, remove item from cart.
  void decrement(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity <= 1) {
        removeFromCart(productId);
      } else {
        final updatedList = List<CartItem>.from(state.items);
        updatedList[index] = item.copyWith(quantity: item.quantity - 1);
        state = state.copyWith(items: updatedList);
      }
    }
  }

  /// Set precise quantity
  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = state.items[index].copyWith(quantity: quantity);
      state = state.copyWith(items: updatedList);
    }
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  /// Select or clear customer
  void setCustomer(Customer? customer) {
    state = state.copyWith(selectedCustomer: () => customer);
  }

  /// Set fixed discount amount
  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount < 0 ? 0.0 : discount);
  }

  /// Set optional notes
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  /// Reset cart after sale is completed or cancelled
  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
