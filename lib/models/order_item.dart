import 'item.dart';

class OrderItem {
  final Item item;
  double quantity;

  OrderItem({
    required this.item,
    this.quantity = 0,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': item.id,
      'quantity': quantity,
    };
  }
}