enum OrderType {
  part,
  chief,
  owner,
  regular,
  preparation,
}

class Item {
  final int id;
  final String name;
  final String kitchen_minimum; // ★変更：キッチンでの最低数
  final String back_minimum;    // ★変更：裏での最低数
  final String kitchen_category;
  final String back_category;
  final String supplier;
  final OrderType orderType;
  final bool alive;

  const Item({
    required this.id,
    required this.name,
    required this.kitchen_minimum, // ★変更
    required this.back_minimum,    // ★変更
    required this.kitchen_category,
    required this.back_category,
    required this.supplier,
    required this.orderType,
    this.alive = true,
  });
}